const path = require("node:path");
const nodeFs = require("node:fs");

const useRpy = !!process.env.USE_RPY;

const wasmRHome = "/R";
const hostRHome = path.join(process.env.PREFIX, "lib", "R");
const rExecDir = path.join(hostRHome, "bin", "exec");
const rLibDir = path.join(hostRHome, "lib");
const prefixLibDir = path.join(process.env.PREFIX, "lib");

const rScriptPath = process.argv[2];
const rScriptBody = nodeFs.readFileSync(rScriptPath, "utf8");

const fname = path.basename(rScriptPath, ".R");

const rArgs = ["--no-restore", "--vanilla", "-e", `source("/${fname}.R")`];

var Module = {
  noInitialRun: true,
  locateFile: (file) => {
    const normalized = file.replace("$PREFIX", process.env.PREFIX);
    if (nodeFs.existsSync(normalized)) {
      return normalized;
    }
    const base = path.basename(normalized);
    for (const dir of [prefixLibDir, rExecDir, rLibDir]) {
      const candidate = path.join(dir, base);
      if (nodeFs.existsSync(candidate)) {
        return candidate;
      }
    }
    for (const dir of [prefixLibDir, rExecDir, rLibDir]) {
      const candidate = path.join(dir, normalized);
      if (nodeFs.existsSync(candidate)) {
        return candidate;
      }
    }
    for (const dir of [rExecDir, rLibDir]) {
      const candidate = path.join(dir, file);
      if (nodeFs.existsSync(candidate)) {
        return candidate;
      }
    }
    return path.join(rExecDir, file);
  },
  preRun: [() => {
    const copyTree = (srcRoot, dstRoot) => {
      Module.FS.mkdirTree(dstRoot);
      for (const entry of nodeFs.readdirSync(srcRoot, { withFileTypes: true })) {
        const src = path.join(srcRoot, entry.name);
        const dst = `${dstRoot}/${entry.name}`;
        if (entry.isDirectory()) {
          copyTree(src, dst);
        } else if (entry.isFile()) {
          Module.FS.writeFile(dst, nodeFs.readFileSync(src));
        }
      }
    };

    // R_HOME tree (etc, share, library, modules) and /lib for dynload paths.
    copyTree(hostRHome, wasmRHome);
    copyTree(rLibDir, "/lib");

    // copy test script to the root of the virtual FS so it can be executed by R.
    Module.FS.writeFile(`/${path.basename(rScriptPath)}`, rScriptBody);

    // For RPY: mount Python stdlib and headers so PYTHONHOME="/" resolves correctly.
    if (useRpy) {
      const prefixIncludeDir = path.join(process.env.PREFIX, "include");
      for (const entry of nodeFs.readdirSync(prefixLibDir, { withFileTypes: true })) {
        if (entry.isDirectory() && /^python\d/.test(entry.name)) {
          copyTree(path.join(prefixLibDir, entry.name), `/lib/${entry.name}`);
        }
      }
      for (const entry of nodeFs.readdirSync(prefixIncludeDir, { withFileTypes: true })) {
        if (entry.isDirectory() && /^python\d/.test(entry.name)) {
          copyTree(path.join(prefixIncludeDir, entry.name), `/include/${entry.name}`);
        }
      }
    }
  }],
  onRuntimeInitialized() {
    Module.callMain(rArgs);
  },
};

const executableName = useRpy ? "RPY" : "R";
let glue = nodeFs.readFileSync(path.join(rExecDir, executableName), "utf8");
const envLiteral = JSON.stringify({
  R_HOME: wasmRHome,
  ...(useRpy ? { PYTHONHOME: "/" } : {}),
});
glue = glue.replace("var ENV={};", `var ENV=${envLiteral};`);
eval(glue);
