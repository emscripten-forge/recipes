/*
 * openjdk8-web.js -- run Java (OpenJDK 8, WebAssembly) in a web page.
 *
 *   <script src="openjdk8-web.js"></script>
 *
 * Applets: every <applet>, <object type="application/x-java-applet"> and
 * <embed type="application/x-java-applet"> element on the page is started
 * automatically (disable with data-applets="off" on the script tag, or call
 * OpenJDK8.runApplets() yourself).
 *
 * Applications:
 *   OpenJDK8.run({ args: ['-cp', '/app', 'Main'], root: element,
 *                  files: { '/app/Main.class': 'Main.class' } })
 *
 * The runtime files (openjdk8.js, openjdk8.wasm, openjdk8-jre.json, openjdk8-jre.data.gz) are loaded from
 * the directory of this script, or from data-base / options.base.
 *
 * Copyright (c) 2026 emscripten-forge contributors.  GPL-2.0 with the
 * Classpath exception, like OpenJDK.
 */
(function (global) {
  'use strict';

  var thisScript = document.currentScript;
  var defaultBase = (thisScript && (thisScript.getAttribute('data-base') ||
                     thisScript.src.replace(/[^\/]*$/, ''))) || './';

  // System properties for the browser environment.
  var DEFAULT_JVM_ARGS = [
    '-Djava.protocol.handler.pkgs=org.emscriptenforge.jvm.net',
    '-Dsun.java2d.pmoffscreen=false',
    '-Dsun.java2d.xrender=false',
    '-Duser.dir=/home/web_user',
  ];

  var STYLE = [
    // (x11.wasm styles .x11-wasm-root as a relative, clipped box; the applet
    // overlay must be absolutely positioned at the document origin)
    'div.openjdk8-root,div.openjdk8-root.x11-wasm-root{position:absolute!important;left:0;top:0;margin:0;padding:0;border:0;',
    'pointer-events:none;z-index:2147483000;overflow:visible!important;background:transparent!important}',
    '.openjdk8-root .x11-wasm-window{pointer-events:auto}',
    '.openjdk8-applet-box{display:inline-block;position:relative;box-sizing:border-box;background:#f2f2f2;',
    'border:1px solid #c9c9c9;color:#555;font:12px/1.4 system-ui,sans-serif;overflow:hidden;vertical-align:bottom}',
    '.openjdk8-applet-box span{position:absolute;left:8px;right:8px;top:50%;transform:translateY(-50%);text-align:center}',
  ].join('');

  function loadScript(src) {
    return new Promise(function (resolve, reject) {
      if (global.createOpenJDK8Module) return resolve();
      var s = document.createElement('script');
      s.src = src;
      s.onload = function () { resolve(); };
      s.onerror = function () { reject(new Error('cannot load ' + src)); };
      document.head.appendChild(s);
    });
  }

  function addStyle() {
    if (document.getElementById('openjdk8-style')) return;
    var st = document.createElement('style');
    st.id = 'openjdk8-style';
    st.textContent = STYLE;
    document.head.appendChild(st);
  }

  var running = null;   // only one JVM per page

  /**
   * Start a JVM.  options: args (array), root (element for windows),
   * base, files ({vmPath: url}), env, jvmArgs (extra), onStdout, onStderr,
   * onStatus, onProgress, onExit, heap (e.g. '256m'), documentTitle (false:
   * keep the page title), audioContext (an AudioContext to play sound on).
   * Returns a promise for the Emscripten module once main() has started.
   */
  function run(options) {
    options = options || {};
    if (running) return Promise.reject(new Error('a Java VM is already running in this page'));
    var base = options.base || defaultBase;
    if (base && base.slice(-1) !== '/') base += '/';
    var files = options.files || {};
    running = loadScript(base + 'openjdk8.js').then(function () {
      return global.createOpenJDK8Module({
        thisProgram: '/java/bin/java',
        noInitialRun: true,
        locateFile: function (p) { return base + p; },
        x11WasmRoot: options.root,
        // the title of a top-level Java window becomes the page title
        // unless documentTitle is false (always false for applets)
        x11WasmDocumentTitle: options.documentTitle !== false,
        audioContext: options.audioContext,
        javaEnv: options.env || {},
        print: options.onStdout || function (s) { console.log(s); },
        printErr: options.onStderr || function (s) { console.warn(s); },
        onAppletStatus: options.onStatus || function () {},
        onJreProgress: options.onProgress,
        onExit: options.onExit,
        preRun: [function (M) {
          var names = Object.keys(files);
          if (!names.length) return;
          M.addRunDependency('java-app-files');
          Promise.all(names.map(function (vmPath) {
            return fetch(files[vmPath]).then(function (r) {
              if (!r.ok) throw new Error(files[vmPath] + ': HTTP ' + r.status);
              return r.arrayBuffer();
            }).then(function (buf) {
              M.FS.mkdirTree(vmPath.replace(/\/[^\/]*$/, '') || '/');
              M.FS.writeFile(vmPath, new Uint8Array(buf));
            });
          })).then(function () {
            M.removeRunDependency('java-app-files');
          }, function (e) {
            console.error('Java: ' + e);
          });
        }],
      });
    }).then(function (M) {
      var args = DEFAULT_JVM_ARGS.slice();
      if (options.heap) args.push('-Xmx' + options.heap);
      args = args.concat(options.jvmArgs || [], options.args || []);
      M.javaMain = M.callMain(args);
      Promise.resolve(M.javaMain).then(function (rc) {
        if (options.onExit) options.onExit(rc);
      }, function (e) {
        if (options.onExit) options.onExit(e && e.status !== undefined ? e.status : -1);
      });
      return M;
    });
    return running;
  }

  // ------------------------------------------------------------- applets

  function attr(el, name) {
    var v = el.getAttribute(name);
    return v === null ? null : v;
  }

  function paramsOf(el) {
    var params = {};
    var ps = el.querySelectorAll(':scope > param');
    for (var i = 0; i < ps.length; i++) {
      var n = ps[i].getAttribute('name');
      if (n) params[n.toLowerCase()] = ps[i].getAttribute('value') || '';
    }
    return params;
  }

  function describe(el) {
    var tag = el.tagName.toLowerCase();
    var params = paramsOf(el);
    var spec = { el: el, params: {} };
    if (tag === 'applet') {
      spec.code = attr(el, 'code');
      spec.codebase = attr(el, 'codebase');
      spec.archive = attr(el, 'archive');
      spec.name = attr(el, 'name') || attr(el, 'id');
    } else {
      var type = (attr(el, 'type') || '').toLowerCase();
      var classid = attr(el, 'classid') || '';
      var isJava = type.indexOf('java') >= 0 || /^java:/i.test(classid) ||
                   /8AD9C840-044E-11D1-B3E9-00805F499D93/i.test(classid);
      if (!isJava) return null;
      spec.code = attr(el, 'code') || params.code || (/^java:/i.test(classid) ? classid.slice(5) : null);
      spec.codebase = attr(el, 'codebase') || params.codebase || attr(el, 'java_codebase') || params.java_codebase;
      if (spec.codebase && /^https?:\/\/java\.sun\.com/i.test(spec.codebase)) spec.codebase = params.codebase || null;
      spec.archive = attr(el, 'archive') || params.archive || params.java_archive;
      spec.name = attr(el, 'name') || attr(el, 'id') || params.name;
      ['code', 'codebase', 'archive', 'type', 'name', 'java_codebase', 'java_archive',
       'java_code', 'java_type', 'scriptable', 'mayscript'].forEach(function (k) { delete params[k]; });
      if (!spec.code && params.java_code) spec.code = params.java_code;
    }
    if (!spec.code) return null;
    if (tag === 'embed') {
      // <embed> carries applet parameters as attributes
      for (var i = 0; i < el.attributes.length; i++) {
        var a = el.attributes[i].name.toLowerCase();
        if (['type', 'code', 'codebase', 'archive', 'width', 'height', 'name', 'id',
             'src', 'pluginspage', 'style', 'class'].indexOf(a) < 0) {
          params[a] = el.attributes[i].value;
        }
      }
    }
    spec.params = params;
    spec.width = parseInt(attr(el, 'width'), 10) || 300;
    spec.height = parseInt(attr(el, 'height'), 10) || 200;
    return spec;
  }

  function findApplets(root) {
    var out = [];
    var els = (root || document).querySelectorAll('applet, object, embed');
    for (var i = 0; i < els.length; i++) {
      var el = els[i];
      if (el.closest('applet, object') && el.closest('applet, object') !== el) continue; // nested fallback
      var spec = describe(el);
      if (spec) out.push(spec);
    }
    return out;
  }

  function documentSize() {
    var d = document.documentElement, b = document.body;
    return {
      w: Math.max(d.scrollWidth, b ? b.scrollWidth : 0, d.clientWidth),
      h: Math.max(d.scrollHeight, b ? b.scrollHeight : 0, d.clientHeight),
    };
  }

  function boxPosition(box) {
    var r = box.getBoundingClientRect();
    return { x: Math.round(r.left + global.pageXOffset + 1), y: Math.round(r.top + global.pageYOffset + 1) };
  }

  /**
   * Start all applets of the page in one JVM.  options as for run(), plus
   * applets (from findApplets()).
   */
  function runApplets(options) {
    options = options || {};
    var applets = options.applets || findApplets();
    if (!applets.length) return Promise.resolve(null);
    addStyle();

    // A box in the page flow reserves the applet's space; the applet's
    // window is placed over it in a page-sized overlay (the X screen).
    applets.forEach(function (a) {
      var box = document.createElement('div');
      box.className = 'openjdk8-applet-box';
      box.style.width = a.width + 'px';
      box.style.height = a.height + 'px';
      box.innerHTML = '<span>Loading Java&hellip;</span>';
      a.el.parentNode.insertBefore(box, a.el);
      a.el.style.display = 'none';
      a.box = box;
    });
    var root = document.createElement('div');
    root.className = 'openjdk8-root';
    var size = documentSize();
    root.style.width = size.w + 'px';
    root.style.height = size.h + 'px';
    document.body.appendChild(root);

    var setText = function (t) {
      applets.forEach(function (a) {
        var s = a.box.querySelector('span');
        if (s) s.textContent = t;
      });
    };

    // Positions are polled by the applet host (see AppletRunner).
    global.__openjdk8AppletLayout = function () {
      var sz = documentSize();
      root.style.width = sz.w + 'px';
      root.style.height = sz.h + 'px';
      return applets.map(function (a) { var p = boxPosition(a.box); return p.x + ',' + p.y; }).join(';');
    };

    var args = ['org.emscriptenforge.jvm.applet.AppletRunner', '--documentbase', location.href];
    applets.forEach(function (a) {
      var p = boxPosition(a.box);
      args.push('--applet', 'code=' + a.code, 'width=' + a.width, 'height=' + a.height,
                'x=' + p.x, 'y=' + p.y);
      if (a.codebase) args.push('codebase=' + a.codebase);
      if (a.archive) args.push('archive=' + a.archive);
      if (a.name) args.push('name=' + a.name);
      Object.keys(a.params).forEach(function (k) { args.push('param:' + k + '=' + a.params[k]); });
    });

    var userStatus = options.onStatus;
    return run(Object.assign({}, options, {
      root: root,
      documentTitle: false,
      args: (options.jvmArgs || []).concat(args),
      jvmArgs: [],
      onProgress: function (loaded, total) {
        setText('Loading Java runtime ' + Math.round(100 * loaded / Math.max(total, 1)) + '%');
        if (options.onProgress) options.onProgress(loaded, total);
      },
      onStatus: function (text) {
        if (/started$/.test(text)) {
          applets.forEach(function (a) { var s = a.box.querySelector('span'); if (s) s.textContent = ''; });
        } else if (/failed/.test(text)) {
          setText(text);
        } else if (/^Loading/.test(text)) {
          setText(text);
        }
        try { global.status = text; } catch (e) {}
        if (userStatus) userStatus(text);
      },
    }));
  }

  global.OpenJDK8 = { run: run, runApplets: runApplets, findApplets: findApplets,
                      defaultJvmArgs: DEFAULT_JVM_ARGS };

  var auto = thisScript ? thisScript.getAttribute('data-applets') : null;
  if (auto !== 'off') {
    var go = function () { if (findApplets().length) runApplets(); };
    if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', go);
    else go();
  }
})(typeof globalThis !== 'undefined' ? globalThis : window);
