// Under node, give julia.js access to the real file system, so that
// `node julia.js script.jl` and `include("...")` work the way they do with a
// native julia. Emscripten's default file system is an in-memory one, and
// -sNODERAWFS would replace it globally, which would break the browser REPL
// that is shipped from the same julia.js. NODEFS is mounted instead, under
// /host, and the working directory is moved there so that relative paths
// resolve exactly as they do outside the module.
if (typeof process !== 'undefined' && process.versions && process.versions.node) {
  Module['preRun'] = Module['preRun'] || [];
  Module['preRun'].push(function () {
    try {
      FS.mkdir('/host');
      FS.mount(NODEFS, { root: '/' }, '/host');
      FS.chdir('/host' + process.cwd());
    } catch (e) {
      err('julia: could not mount the host file system: ' + e);
    }
  });
  // Absolute paths on the command line have to be moved under the mount point
  // as well; relative ones are already correct after the chdir above.
  try {
    var nodeFs = require('fs');
    Module['arguments'] = process.argv.slice(2).map(function (a) {
      return a.charAt(0) === '/' && nodeFs.existsSync(a) ? '/host' + a : a;
    });
  } catch (e) { /* not a CommonJS environment; leave argv alone */ }
}
