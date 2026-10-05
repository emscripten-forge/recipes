/*
 * java_pre.js -- Emscripten --pre-js of the WebAssembly OpenJDK runtime.
 * Sets up the process environment the JDK expects in a browser tab.
 */
if (!Module['thisProgram']) Module['thisProgram'] = '/java/bin/java';
// Console input: end of file unless the page supplies a reader.
if (!Module['stdin']) Module['stdin'] = function () { return null; };
Module['preRun'] = [].concat(Module['preRun'] || []);
Module['preRun'].unshift(function () {
  var defaults = {
    'JAVA_HOME': '/java',
    'DISPLAY': ':0',              // AWT is headless without a DISPLAY
    'HOME': '/home/web_user',
    'USER': 'web_user',
    'LOGNAME': 'web_user',
    'LANG': 'en_US.UTF-8',
    'TZ': 'UTC',
    'PATH': '/java/bin:/usr/bin:/bin',
  };
  try {
    var tz = Intl.DateTimeFormat().resolvedOptions().timeZone;
    if (tz) defaults['TZ'] = tz;
  } catch (e) {}
  for (var k in defaults) if (!(k in ENV)) ENV[k] = defaults[k];
  var extra = Module['javaEnv'] || {};
  for (var k2 in extra) ENV[k2] = extra[k2];
  try { FS.mkdirTree('/home/web_user'); } catch (e) {}
  try { FS.mkdirTree('/tmp'); } catch (e) {}
});

/*
 * Java runtime files: unless the page mounts its own file system
 * (Module.javaFS === false), load openjdk8-jre.json and the data file it names
 * (openjdk8-jre.data.gz, next to openjdk8.wasm, see Module.locateFile) and unpack them
 * into the in-memory file system.  The data file is gzip-compressed; it is
 * decompressed here (DecompressionStream in browsers, zlib in Node.js), and
 * also accepted if the web server already removed the compression.
 * Module.onJreProgress(loaded, total) reports download progress.
 */
Module['preRun'].push(function () {
  if (Module['javaFS'] === false) return;
  var indexName = Module['jreIndex'] || 'openjdk8-jre.json';
  var loc = function (p) { return Module['locateFile'] ? Module['locateFile'](p, '') : p; };
  var isNode = typeof process === 'object' && process.versions && process.versions.node &&
               typeof window === 'undefined';
  var isRemote = function (u) { return /^[a-z][a-z0-9+.-]*:\/\//i.test(u) && !/^file:/i.test(u); };
  var readLocal = function (u) {
    var fs = require('fs');
    if (/^file:/i.test(u)) u = require('url').fileURLToPath(u);
    return Promise.resolve(new Uint8Array(fs.readFileSync(u)));
  };
  // Download with progress reporting; resolves to a Uint8Array.
  var download = function (url, total) {
    if (isNode && !isRemote(url)) return readLocal(url);
    return fetch(url).then(function (resp) {
      if (!resp.ok) throw new Error('cannot load ' + url + ': HTTP ' + resp.status);
      var progress = Module['onJreProgress'];
      if (!resp.body || !progress) return resp.arrayBuffer().then(function (b) { return new Uint8Array(b); });
      var reader = resp.body.getReader();
      var buf = new Uint8Array(total || 1 << 20);
      var pos = 0;
      var pump = function () {
        return reader.read().then(function (r) {
          if (r.done) return buf.subarray(0, pos);
          if (pos + r.value.length > buf.length) {
            var nb = new Uint8Array(Math.max(buf.length * 2, pos + r.value.length));
            nb.set(buf.subarray(0, pos)); buf = nb;
          }
          buf.set(r.value, pos);
          pos += r.value.length;
          progress(Math.min(pos, total || pos), total || pos);
          return pump();
        });
      };
      return pump();
    });
  };
  var gunzip = function (u8) {
    if (isNode) return Promise.resolve(new Uint8Array(require('zlib').gunzipSync(u8)));
    var stream = new Blob([u8]).stream().pipeThrough(new DecompressionStream('gzip'));
    return new Response(stream).arrayBuffer().then(function (b) { return new Uint8Array(b); });
  };
  var readIndex = function (url) {
    if (isNode && !isRemote(url)) return readLocal(url).then(function (u8) {
      return JSON.parse(new TextDecoder().decode(u8));
    });
    return fetch(url).then(function (r) {
      if (!r.ok) throw new Error('cannot load ' + url + ': HTTP ' + r.status);
      return r.json();
    });
  };
  addRunDependency('java-jre');
  readIndex(loc(indexName)).then(function (idx) {
    var dataName = Module['jreData'] || idx.data || 'openjdk8-jre.data';
    return download(loc(dataName), idx.csize || idx.size).then(function (u8) {
      // compressed unless the server decoded it (Content-Encoding: gzip)
      if (idx.encoding === 'gzip' && u8.length !== idx.size && u8[0] === 0x1f && u8[1] === 0x8b)
        return gunzip(u8).then(function (raw) { return [idx, raw]; });
      return [idx, u8];
    });
  }).then(function (r) {
    var idx = r[0], u8 = r[1];
    if (u8.length !== idx.size) throw new Error('runtime data size mismatch (' + u8.length + ' != ' + idx.size + ')');
    var root = idx.root;
    FS.mkdirTree(root);
    idx.dirs.forEach(function (d) { FS.mkdirTree(root + '/' + d); });
    idx.files.forEach(function (f) {
      var path = root + '/' + f.p;
      var slash = path.lastIndexOf('/');
      FS.createDataFile(path.substring(0, slash), path.substring(slash + 1),
                        u8.subarray(f.o, f.o + f.s), true, true, true);
      if (f.m & 0o111) FS.chmod(path, f.m);
    });
    (idx.links || []).forEach(function (l) { FS.symlink(l.t, root + '/' + l.p); });
    removeRunDependency('java-jre');
  }).catch(function (e) {
    err('Java runtime files: ' + e);
    if (Module['onAbort']) Module['onAbort'](e);
  });
});
