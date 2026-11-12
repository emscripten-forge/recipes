// For $PREFIX/bin/octave-cli to be able to find shared libs
var Module = {
  locateFile(path, prefix) {
    if (path.endsWith('.so'))
      return prefix + '../lib/octave/${PKG_VERSION}/' + path;
    return prefix + path;
  },
  preRun: [() => {
    // octave-cli.js lives in $PREFIX/bin
    // OCTAVE_HOME = $PREFIX
    let home;
    if (typeof __dirname !== 'undefined') {
      const path = require('node:path');
      home = path.resolve(__dirname, '..');
    }
    if (!home) return;
    ENV.OCTAVE_HOME = home;
    ENV.OCTAVE_EXEC_HOME = home;
    if (typeof process !== 'undefined' && process.env) {
      process.env.OCTAVE_HOME = home;
      process.env.OCTAVE_EXEC_HOME = home;
    }
  }]
};