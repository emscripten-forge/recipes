// Test a WebAssembly package inside a xeus kernel, run in the test phase of a rattler-build recipe.
//
// Uses environment variables set by rattler-build:
//   PREFIX:          wasm test environment containing the package under test and a xeus kernel.
//   PKG_NAME:        name of the package under test.
//   target_platform: platform of the test environment, e.g. emscripten-wasm32.
// Every file in the current directory is a test file to run in the kernel.
//
// Each test file is run in node with the kernel in the main thread and in a worker. If playwright is
// installed alongside xeus-tester, each test file is also run in a headless Chromium browser with the
// kernel in the main thread and in a worker. A test fails if running it writes anything to stderr,
// such as an exception.

import { spawnSync } from 'node:child_process';
import { existsSync, readdirSync, readFile, readFileSync } from 'node:fs';
import http from 'node:http';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { XeusKernel } from './dist_node/xeus-runner.js';

// Directory containing this script, the xeus-runner bundles and the browser test page.
const SCRIPT_DIR = path.dirname(fileURLToPath(import.meta.url));

// Playwright installed in the same environment as xeus-tester, if present.
const PLAYWRIGHT_DIR = path.join(SCRIPT_DIR, '..', '..', 'lib', 'node_modules', 'playwright');

// URL path on the HTTP server for the contents of SCRIPT_DIR.
const XEUS_TESTER_URL_PATH = '/xeus-tester';

// ------------------------------------------------------------------------------------------------
// Utilities
// ------------------------------------------------------------------------------------------------

function fail(message) {
  console.error(`[xeus-tester] Error: ${message}`);
  process.exit(1);
}

function log(message) {
  console.log(`[xeus-tester] ${message}`);
}

function getEnv(name) {
  const value = process.env[name];
  if (!value) {
    fail(`${name} is not set`);
  }
  return value;
}

/**
 * Return time elapsed since `start` (from `performance.now()`) as a string in seconds.
 */
function elapsedSeconds(start) {
  return `${((performance.now() - start) / 1000).toFixed(1)} s`;
}

// ------------------------------------------------------------------------------------------------
// Test environment
// ------------------------------------------------------------------------------------------------

/**
 * Read the conda-meta records of all packages installed in the environment at `prefix`.
 */
function readCondaMeta(prefix) {
  const condaMeta = path.join(prefix, 'conda-meta');
  return readdirSync(condaMeta)
    .filter((f) => f.endsWith('.json'))
    .map((f) => JSON.parse(readFileSync(path.join(condaMeta, f), 'utf8')));
}

/**
 * Return the name of the xeus kernel package, which is the xeus-<language> package with exactly one
 * dash in its name. This excludes support packages such as xeus-python-shell.
 */
function findKernel(records) {
  const kernels = records.map((r) => r.name).filter((name) => /^xeus-[^-]+$/.test(name));
  if (kernels.length !== 1) {
    fail(`expected one xeus kernel package in test requirements, found: [${kernels.join(', ')}]`);
  }
  return kernels[0];
}

/**
 * Return the names of the test files, which are all files in the current directory.
 */
function findTestFiles() {
  const testFiles = readdirSync('.', { withFileTypes: true })
    .filter((e) => e.isFile())
    .map((e) => e.name)
    .sort();
  if (testFiles.length === 0) {
    fail(`no test files found in ${process.cwd()}`);
  }
  return testFiles;
}

// ------------------------------------------------------------------------------------------------
// Environment lock
// ------------------------------------------------------------------------------------------------

/**
 * Return the distinct local file:// channels in the conda-meta records. These are the temporary
 * channels rattler-build uses for the package under test.
 */
function findLocalChannels(records) {
  const channels = records.map((r) => r.channel.replace(/\/+$/, ''));
  return [...new Set(channels.filter((c) => c.startsWith('file://')))];
}

/**
 * Create environment lock in mambajs format from the conda-meta records of an installed
 * environment, so that the kernel uses exactly the same packages without solving the environment
 * again.
 * `channelUrls` maps local file:// channels to the HTTP URLs serving them, as xeus-runner cannot read
 * file:// channels.
 */
function createEnvLock(records, platform, channelUrls) {
  const packages = {};
  const channels = new Set();
  for (const r of records) {
    let channel = r.channel.replace(/\/+$/, '');
    channel = channelUrls.get(channel) ?? channel;
    channels.add(channel);
    packages[r.fn] = {
      name: r.name,
      version: r.version,
      build: r.build,
      subdir: r.subdir,
      channel,
      hash: { md5: r.md5, sha256: r.sha256 },
      size: r.size,
    };
  }

  return {
    lockVersion: '1.0.4',
    platform,
    specs: [],
    channels: [...channels],
    channelInfo: Object.fromEntries([...channels].map((c) => [c, [{ url: c, protocol: 'https' }]])),
    packages,
    pipPackages: {},
  };
}

// ------------------------------------------------------------------------------------------------
// HTTP server
// ------------------------------------------------------------------------------------------------

const CONTENT_TYPES = {
  '.html': 'text/html',
  '.js': 'text/javascript',
  '.json': 'application/json',
  '.wasm': 'application/wasm',
};

/**
 * Start an HTTP server on a free port that serves local directories. `routes` maps URL path prefixes
 * such as '/channel/0' to local directories. Returns the server and its base URL.
 */
async function startServer(routes) {
  const server = http.createServer((req, res) => {
    const urlPath = decodeURIComponent(new URL(req.url, 'http://localhost').pathname);
    const route = [...routes.keys()].find((prefix) => urlPath.startsWith(`${prefix}/`));
    if (route === undefined) {
      res.writeHead(404).end();
      return;
    }
    const dir = routes.get(route);
    const filePath = path.join(dir, urlPath.slice(route.length));
    if (!filePath.startsWith(dir + path.sep)) {
      res.writeHead(403).end();
      return;
    }
    readFile(filePath, (err, data) => {
      if (err) {
        res.writeHead(404).end();
      } else {
        const contentType = CONTENT_TYPES[path.extname(filePath)] ?? 'application/octet-stream';
        res.writeHead(200, { 'Content-Type': contentType }).end(data);
      }
    });
  });
  await new Promise((resolve) => server.listen(0, '127.0.0.1', resolve));
  return { server, url: `http://127.0.0.1:${server.address().port}` };
}

// ------------------------------------------------------------------------------------------------
// Running code in a kernel
// ------------------------------------------------------------------------------------------------

/**
 * Execute cells of code in turn in a fresh kernel in node, stopping at the first cell that writes to
 * stderr. Returns the combined {stdout, stderr} from the kernel, plus the index of the failed cell
 * if there is one.
 */
async function executeInNode(kernelType, envLock, cells, worker) {
  const kernel = new XeusKernel({ type: kernelType, envLock, worker });
  try {
    await kernel.ready;
    let stdout = '';
    for (const [index, code] of cells.entries()) {
      const ret = await kernel.execute({ code });
      stdout += ret.stdout ?? '';
      if (ret.stderr) {
        return { stdout, stderr: ret.stderr, failedCell: index };
      }
    }
    return { stdout };
  } finally {
    kernel.dispose();
  }
}

/**
 * Launch headless Chromium using the playwright installed alongside xeus-tester, installing the
 * browser first if necessary. Returns the browser.
 */
async function launchBrowser() {
  log('Installing Chromium for playwright');
  const install = spawnSync(process.execPath, [path.join(PLAYWRIGHT_DIR, 'cli.js'), 'install', 'chromium'], {
    stdio: 'inherit',
  });
  if (install.status !== 0) {
    fail('failed to install Chromium for playwright');
  }
  const { chromium } = await import(path.join(PLAYWRIGHT_DIR, 'index.mjs'));
  return await chromium.launch();
}

/**
 * Execute cells of code in turn in a fresh kernel in a new browser page, stopping at the first cell
 * that writes to stderr. Returns the combined {stdout, stderr} from the kernel, plus the index of
 * the failed cell if there is one.
 */
async function executeInBrowser(browser, pageUrl, kernelType, envLock, cells, worker) {
  const page = await browser.newPage();
  try {
    await page.goto(pageUrl);
    await page.waitForFunction(() => globalThis.XeusKernel !== undefined);
    // This function runs in the browser so cannot call functions defined here.
    return await page.evaluate(
      async ({ kernelType, envLock, cells, worker }) => {
        const kernel = new globalThis.XeusKernel({ type: kernelType, envLock, worker });
        try {
          await kernel.ready;
          let stdout = '';
          for (const [index, code] of cells.entries()) {
            const ret = await kernel.execute({ code });
            stdout += ret.stdout ?? '';
            if (ret.stderr) {
              return { stdout, stderr: ret.stderr, failedCell: index };
            }
          }
          return { stdout };
        } finally {
          kernel.dispose();
        }
      },
      { kernelType, envLock, cells, worker },
    );
  } finally {
    await page.close();
  }
}

// ------------------------------------------------------------------------------------------------
// Shims
// ------------------------------------------------------------------------------------------------

/**
 * Split SQL source into cells for xeus-sqlite, which only runs one thing per cell: either a magic
 * such as `%CREATE test.db`, or the first SQL statement. Each line starting with `%` is a cell, and
 * each SQL statement ending with a line that ends in `;` is a cell. Blank lines and `--` comment lines
 * are ignored.
 */
function splitSqlCells(source) {
  const cells = [];
  let statement = [];
  for (const line of source.split('\n')) {
    const trimmed = line.trim();
    if (trimmed === '' || trimmed.startsWith('--')) {
      continue;
    }
    if (statement.length === 0 && trimmed.startsWith('%')) {
      cells.push(trimmed);
      continue;
    }
    statement.push(line);
    if (trimmed.endsWith(';')) {
      cells.push(statement.join('\n'));
      statement = [];
    }
  }
  if (statement.length > 0) {
    cells.push(statement.join('\n'));
  }
  return cells;
}

/**
 * Shims to run test files using a language-specific approach, such as a test framework like pytest.
 * Each shim has:
 *   name:    name of the shim for logging.
 *   applies: function(kernel, packageNames) returning whether the shim applies to this test
 *            environment, given the kernel package name and the names of all installed packages.
 *   cells:   function(testFile, source) returning an array of cells of code to run in turn in the
 *            kernel in place of the test file's source. The test fails at the first cell that writes
 *            to stderr, e.g. raises an exception.
 * The first shim that applies is used. If none apply, each test file is run directly as one cell.
 */
const SHIMS = [
  {
    name: 'pytest',
    applies: (kernel, packageNames) => kernel === 'xeus-python' && packageNames.includes('pytest'),
    cells: (testFile, source) => {
      // Write the test file into the kernel's filesystem and run it using pytest.
      // A JSON string is also a valid Python string literal.
      const file = JSON.stringify(testFile);
      return [
        `import pytest
with open(${file}, "w") as f:
    f.write(${JSON.stringify(source)})
ret = pytest.main(["-s", "-vvv", "-p", "no:faulthandler", "-p", "no:cacheprovider", ${file}])
if ret != 0:
    raise RuntimeError(f"pytest failed with exit code {ret}")
`,
      ];
    },
  },
  {
    name: 'sqlite',
    applies: (kernel, packageNames) => kernel === 'xeus-sqlite',
    cells: (testFile, source) => splitSqlCells(source),
  },
];

/**
 * Return the first shim that applies to the test environment, or undefined if none do.
 */
function findShim(kernel, records) {
  const packageNames = records.map((r) => r.name);
  return SHIMS.find((shim) => shim.applies(kernel, packageNames));
}

// ------------------------------------------------------------------------------------------------
// Running tests
// ------------------------------------------------------------------------------------------------

/**
 * Run a test file in a fresh kernel using `mode`, so that test files are isolated from each other.
 * `mode` has a `name` and an `execute(cells)` function that runs cells of code in turn in one kernel
 * and returns the combined {stdout, stderr} from the kernel.
 * If `shim` is defined it is used to run the test file, otherwise the test file is run directly as
 * one cell.
 * Returns whether the test passed.
 */
async function runTest(mode, testFile, shim) {
  const name = `${testFile}, ${mode.name}`;
  log(`Running ${name}`);
  const start = performance.now();
  const source = readFileSync(testFile, 'utf8');
  const cells = shim ? shim.cells(testFile, source) : [source];
  const ret = await mode.execute(cells);
  if (ret.stdout) {
    console.log(ret.stdout.trimEnd());
  }
  if (ret.stderr) {
    console.error(ret.stderr.trimEnd());
    // If the test file is split into cells, show which one failed.
    if (cells.length > 1) {
      log(`Failed in cell ${ret.failedCell + 1} of ${cells.length}:\n${cells[ret.failedCell]}`);
    }
    log(`FAILED ${name} (${elapsedSeconds(start)})`);
    return false;
  }
  log(`PASSED ${name} (${elapsedSeconds(start)})`);
  return true;
}

// ------------------------------------------------------------------------------------------------
// Main
// ------------------------------------------------------------------------------------------------

const totalStart = performance.now();

const prefix = getEnv('PREFIX');
const packageName = getEnv('PKG_NAME');
const platform = getEnv('target_platform');

const records = readCondaMeta(prefix);
const kernel = findKernel(records);
const testFiles = findTestFiles();
const shim = findShim(kernel, records);
const useBrowser = existsSync(path.join(PLAYWRIGHT_DIR, 'index.mjs'));

log(`Package under test: ${packageName}`);
log(`Kernel: ${kernel}`);
log(`Test files: ${testFiles.join(', ')}`);
log(`Running test files ${shim ? `using ${shim.name}` : 'directly'}`);
log(`Running in node${useBrowser ? ' and browser' : ''}`);

// Serve local channels, and xeus-tester's own files for the browser test page.
const localChannels = findLocalChannels(records);
const routes = new Map(localChannels.map((channel, i) => [`/channel/${i}`, fileURLToPath(channel)]));
routes.set(XEUS_TESTER_URL_PATH, SCRIPT_DIR);
const { server, url } = await startServer(routes);
const channelUrls = new Map(localChannels.map((channel, i) => [channel, `${url}/channel/${i}`]));
for (const [channel, channelUrl] of channelUrls) {
  log(`Serving ${channel} at ${channelUrl}`);
}

let browser;
let nTests = 0;
let nFailed = 0;
try {
  const envLock = createEnvLock(records, platform, channelUrls);

  const modes = [false, true].map((worker) => ({
    name: `node, worker=${worker}`,
    execute: (cells) => executeInNode(kernel, envLock, cells, worker),
  }));
  if (useBrowser) {
    browser = await launchBrowser();
    const pageUrl = `${url}${XEUS_TESTER_URL_PATH}/index.html`;
    for (const worker of [false, true]) {
      modes.push({
        name: `browser, worker=${worker}`,
        execute: (cells) => executeInBrowser(browser, pageUrl, kernel, envLock, cells, worker),
      });
    }
  }

  for (const mode of modes) {
    for (const testFile of testFiles) {
      nTests++;
      if (!(await runTest(mode, testFile, shim))) {
        nFailed++;
      }
    }
  }
} finally {
  await browser?.close();
  server.close();
}

log(`${nTests - nFailed} passed, ${nFailed} failed (${elapsedSeconds(totalStart)})`);
process.exitCode = nFailed > 0 ? 1 : 0;
