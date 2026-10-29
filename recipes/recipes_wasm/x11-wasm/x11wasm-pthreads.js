// x11wasm-pthreads.js -- --pre-js for programs that use x11.wasm from pthreads.
//
// With -sPROXY_TO_PTHREAD the program's threads are Web Workers and x11.wasm's
// DOM backend lives on the browser thread (its js-library functions are
// proxied there synchronously). DOM input handlers, however, call straight
// into wasm (_X11WasmQueue*Event, ...) and would mutate the Xlib event queue
// while a worker is reading it.
//
// This installs Module.x11WasmCreateBackend, which the x11.wasm bridge uses to
// build its backend:
//   * the backend sees a module whose queue/resize/clipboard exports only
//     record the call (copying any (pointer, length) string argument), and
//   * every backend method the bridge invokes -- i.e. every proxied Xlib call,
//     made while the calling worker is blocked waiting for it -- first replays
//     the recorded calls.
// So the queue is only touched by one side at a time. Xlib callers that poll
// (XPending / XEventsQueued(QueuedAfterFlush)) end up in the bridge via
// XFlush, which is what delivers pending input.
(function () {
  "use strict";

  var DEFERRED = /^_X11Wasm(Queue[A-Za-z]*|ResizeRoot|SetExternalClipboardText)$/;
  // name -> index of the (pointer, byteLength) argument pair
  var STRING_ARG = {
    _X11WasmQueueCompositionEvent: 2,
    _X11WasmSetExternalClipboardText: 0,
  };

  function createBackend(module) {
    var pending = [];

    var recordingModule = new Proxy(module, {
      get: function (target, prop) {
        var value = target[prop];
        if (typeof prop !== "string" || typeof value !== "function" ||
            !DEFERRED.test(prop)) {
          return value;
        }
        return function () {
          var args = Array.prototype.slice.call(arguments);
          var at = STRING_ARG[prop];
          if (at !== undefined) {
            var ptr = args[at] >>> 0, len = args[at + 1] >>> 0;
            args[at] = HEAPU8.slice(ptr, ptr + len);
          }
          pending.push({ name: prop, args: args, stringAt: at });
          return 1;
        };
      },
    });

    function replay() {
      while (pending.length) {
        var calls = pending;
        pending = [];
        for (var i = 0; i < calls.length; i++) {
          var call = calls[i], args = call.args, ptr = 0;
          if (call.stringAt !== undefined) {
            var bytes = args[call.stringAt];
            ptr = module._malloc(bytes.length + 1);
            HEAPU8.set(bytes, ptr);
            HEAPU8[ptr + bytes.length] = 0;
            args[call.stringAt] = ptr;
          }
          try {
            module[call.name].apply(null, args);
          } catch (e) {
            err("x11wasm-pthreads: " + call.name + " failed: " + e);
          } finally {
            if (ptr) module._free(ptr);
          }
        }
      }
    }

    var backend = globalThis.X11WasmDOM.createBackend({
      root: module.x11WasmRoot,
      module: recordingModule,
    });

    return new Proxy(backend, {
      get: function (target, prop) {
        var value = target[prop];
        if (typeof value !== "function") {
          return value;
        }
        return function () {
          replay();
          return value.apply(target, arguments);
        };
      },
    });
  }

  if (typeof Module !== "undefined" && !Module["x11WasmCreateBackend"]) {
    Module["x11WasmCreateBackend"] = createBackend;
  }
})();
