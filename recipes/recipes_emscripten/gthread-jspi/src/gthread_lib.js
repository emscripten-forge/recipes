/*
 * gthread_lib.js -- JavaScript half of the JSPI green-thread runtime.
 * Link with:  --js-library gthread_lib.js -sJSPI
 *             -sJSPI_EXPORTS=gt_thread_entry,main (main is included by default)
 *
 * The dispatcher resumes exactly one suspended WebAssembly stack at a time.
 * It is driven by microtasks while threads hand the CPU to each other and
 * falls back to a macrotask (MessageChannel) every few milliseconds so that
 * the browser can render and deliver input events.
 */
addToLibrary({
  $GT__deps: ['gt_pick_next', 'gt_get_idle_delay', 'gt_thread_entry',
              '_emscripten_stack_restore'],
  $GT: {
    resolvers: new Map(),     // id -> resolve() of a suspended thread
    fresh: new Map(),         // id -> C stack top of a not yet started thread
    pending: false,           // a dispatch is queued
    timer: null,              // idle timer
    lastMacro: 0,
    stopped: false,
    macroChannel: null,
    macroQueue: [],
    now() {
      return (typeof performance != 'undefined') ? performance.now() : Date.now();
    },
    macrotask(fn) {
      if (typeof MessageChannel != 'undefined') {
        if (!GT.macroChannel) {
          GT.macroChannel = new MessageChannel();
          GT.macroChannel.port1.onmessage = () => {
            var f = GT.macroQueue.shift();
            // In Node, only keep the process alive while work is queued.
            if (!GT.macroQueue.length && GT.macroChannel.port1.unref) GT.macroChannel.port1.unref();
            if (f) f();
          };
        }
        if (GT.macroChannel.port1.ref) GT.macroChannel.port1.ref();
        GT.macroQueue.push(fn);
        GT.macroChannel.port2.postMessage(0);
      } else {
        setTimeout(fn, 0);
      }
    },
    kick() {
      if (GT.stopped || GT.pending) return;
      if (GT.timer !== null) { clearTimeout(GT.timer); GT.timer = null; }
      GT.pending = true;
      var t = GT.now();
      if (t - GT.lastMacro > 8) {
        GT.macrotask(() => { GT.lastMacro = GT.now(); GT.dispatch(); });
      } else {
        queueMicrotask(GT.dispatch);
      }
    },
    onError(e) {
      if (e instanceof ExitStatus || (e && e.name == 'ExitStatus')) {
        GT.stopped = true;
        return;
      }
      if (e == 'unwind') return;
      GT.stopped = true;
      err('green thread aborted: ' + (e && e.stack ? e.stack : e));
      if (Module['onGreenThreadError']) Module['onGreenThreadError'](e);
    },
    dispatch() {
      GT.pending = false;
      if (GT.stopped) return;
      var id = _gt_pick_next();
      if (id < 0) {
        var delay = _gt_get_idle_delay();
        if (delay >= 0) {
          GT.timer = setTimeout(() => { GT.timer = null; GT.kick(); }, Math.max(0, delay));
        }
        return;
      }
      var top = GT.fresh.get(id);
      if (top !== undefined) {
        GT.fresh.delete(id);
        __emscripten_stack_restore(top);
        var p;
        try {
          p = _gt_thread_entry(id);
        } catch (e) {
          GT.onError(e);
          return;
        }
        Promise.resolve(p).then(() => GT.kick(), GT.onError);
        return;
      }
      var r = GT.resolvers.get(id);
      if (!r) {
        err('gthread: no suspended stack for thread ' + id);
        return;
      }
      GT.resolvers.delete(id);
      r();
    },
  },

  gt_js_block__deps: ['$GT'],
  gt_js_block__async: true,
  gt_js_block: (id) => {
    if (Module['gtDebug']) {
      (Module['gtStacks'] = Module['gtStacks'] || {})[id] = new Error().stack;
    }
    return new Promise((resolve) => {
      GT.resolvers.set(id, resolve);
      GT.kick();
    });
  },

  gt_js_thread_created__deps: ['$GT'],
  gt_js_thread_created: (id, top) => {
    GT.fresh.set(id, top);
  },

  gt_js_kick__deps: ['$GT'],
  gt_js_kick: () => GT.kick(),
});
