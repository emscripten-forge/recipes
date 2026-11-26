// Mount the host proj data dir (containing proj.db) into the wasm virtual FS
// and point PROJ_DATA at it. Only meaningful under the Node backend.
Module['preRun'] = (Module['preRun'] || []).concat([function () {
  var host = (typeof process !== 'undefined' && process.env && process.env.PROJ_DATA_HOST);
  if (!host) return;
  try {
    FS.mkdirTree('/proj');
    FS.mount(NODEFS, { root: host }, '/proj');
    ENV['PROJ_DATA'] = '/proj';
  } catch (e) {
    console.error('failed to mount PROJ_DATA_HOST=' + host + ': ' + e);
  }
}]);
