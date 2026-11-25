// Run the page's program (scilab.js: Scilab with OpenJDK 21) under node, with
// headless Java, the host's directories at their own paths and the current
// directory as the working directory.
//
//   node run_headless.js <share/scilab-wasm> [scilab options]
'use strict';
const path = require('path');
const fs = require('fs');
const os = require('os');

const home = path.resolve(process.argv[2]);
const createScilabModule = require(path.join(home, 'scilab.js'));

const env = { SCI_JAVA_ENABLE_HEADLESS: '1', DISPLAY: '' };
for (const k of ['HOME', 'USER', 'LANG', 'TZ', 'TERM', 'TERMINFO', 'TERMINFO_DIRS']) {
  if (process.env[k] !== undefined) env[k] = process.env[k];
}

function mountHost(M) {
  const FS = M.FS;
  const skip = new Set(['dev', 'proc', 'sys', 'java', 'usr', 'tmp']);
  for (const name of fs.readdirSync('/')) {
    if (skip.has(name)) continue;
    let real;
    try {
      real = fs.realpathSync('/' + name);
      if (!fs.statSync(real).isDirectory()) continue;
    } catch (e) { continue; }
    try {
      if (!FS.analyzePath('/' + name).exists) FS.mkdir('/' + name);
      FS.mount(M.NODEFS, { root: real }, '/' + name);
    } catch (e) { /* keep the in-memory directory */ }
  }
  try { FS.mkdirTree('/tmp'); FS.mount(M.NODEFS, { root: os.tmpdir() }, '/tmp'); } catch (e) {}
  FS.chdir(process.cwd());
}

createScilabModule({
  locateFile: (p) => path.join(home, p),
  scilabEnv: env,
  persistHome: false,
  print: (s) => process.stdout.write(s + '\n'),
  printErr: (s) => process.stderr.write(s + '\n'),
  onExit: (code) => process.exit(code),
  preRun: [mountHost],
}).then((M) => M.callMain(process.argv.slice(3)),
        (e) => { process.stderr.write('cannot start: ' + (e && e.message || e) + '\n'); process.exit(1); });
