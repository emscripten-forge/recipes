/*
 * wasmrt_lib.js -- browser services for the WebAssembly OpenJDK runtime
 * (Emscripten --js-library).  Everything that can take time completes
 * asynchronously and wakes the waiting green thread through
 * gt_io_notify(channel); nothing here suspends WebAssembly directly.
 */
addToLibrary({
  $WasmRT: {
    reqs: new Map(),
    nextReq: 1,
    handles: [null, null],   // JSObject handles; 1 == the global object
    freeHandles: [],
    status(text) {
      if (Module['onAppletStatus']) Module['onAppletStatus'](text);
    },
    parseHeaders(text) {
      const h = [];
      for (const line of text.split('\n')) {
        const i = line.indexOf(':');
        if (i > 0) h.push([line.slice(0, i).trim(), line.slice(i + 1).trim()]);
      }
      return h;
    },
    allocString(s) {
      if (s === null || s === undefined) return 0;
      const n = lengthBytesUTF8(s) + 1;
      const p = _malloc(n);
      stringToUTF8(s, p, n);
      return p;
    },
    newHandle(v) {
      if (v === null || v === undefined) return 0;
      let id = WasmRT.freeHandles.pop();
      if (id === undefined) id = WasmRT.handles.length;
      WasmRT.handles[id] = v;
      return id;
    },
    // Encode a JS value for Java: returns "type:payload"
    encode(v) {
      if (v === null || v === undefined) return 'n:';
      switch (typeof v) {
        case 'boolean': return 'b:' + (v ? '1' : '0');
        case 'number': return 'd:' + String(v);
        case 'string': return 's:' + v;
        default: return 'o:' + WasmRT.newHandle(v);
      }
    },
    decode(s) {
      const t = s[0], p = s.slice(2);
      switch (t) {
        case 'n': return null;
        case 'b': return p === '1';
        case 'd': return Number(p);
        case 's': return p;
        case 'o': return Number(p) === 1 ? globalThis : WasmRT.handles[Number(p)];
      }
      return undefined;
    },
  },

  // ------------------------------------------------------------ fetch
  wasm_fetch_start__deps: ['$WasmRT', 'gt_io_notify', 'malloc'],
  wasm_fetch_start: (urlPtr, methodPtr, headersPtr, bodyPtr, bodyLen) => {
    const id = WasmRT.nextReq++;
    const url = UTF8ToString(urlPtr);
    const method = UTF8ToString(methodPtr) || 'GET';
    const headers = WasmRT.parseHeaders(headersPtr ? UTF8ToString(headersPtr) : '');
    const body = bodyLen >= 0 ? HEAPU8.slice(bodyPtr, bodyPtr + bodyLen) : undefined;
    const r = { done: false, status: 0, statusText: '', headers: '', body: null,
                error: null, url: url };
    WasmRT.reqs.set(id, r);
    const finish = () => { r.done = true; _gt_io_notify(2); };
    let resolved = url;
    try { resolved = new URL(url, globalThis.location ? globalThis.location.href : undefined).href; } catch (e) {}
    const opts = { method, headers, redirect: 'follow', credentials: 'same-origin' };
    if (body !== undefined && method !== 'GET' && method !== 'HEAD') opts.body = body;
    (Module['fetch'] || fetch)(resolved, opts).then(async (resp) => {
      r.status = resp.status;
      r.statusText = resp.statusText;
      r.url = resp.url || resolved;
      let h = '';
      resp.headers.forEach((v, k) => { h += k + ': ' + v + '\n'; });
      r.headers = h;
      r.body = new Uint8Array(await resp.arrayBuffer());
      finish();
    }).catch((e) => {
      r.error = String(e && e.message ? e.message : e);
      finish();
    });
    return id;
  },
  wasm_fetch_done__deps: ['$WasmRT'],
  wasm_fetch_done: (id) => {
    const r = WasmRT.reqs.get(id);
    return (!r || r.done) ? 1 : 0;
  },
  wasm_fetch_status__deps: ['$WasmRT'],
  wasm_fetch_status: (id) => {
    const r = WasmRT.reqs.get(id);
    return r ? r.status : -1;
  },
  wasm_fetch_string__deps: ['$WasmRT', 'malloc'],
  wasm_fetch_string: (id, which) => {
    const r = WasmRT.reqs.get(id);
    if (!r) return 0;
    switch (which) {
      case 0: return WasmRT.allocString(r.statusText);
      case 1: return WasmRT.allocString(r.headers);
      case 2: return WasmRT.allocString(r.url);
      case 3: return WasmRT.allocString(r.error);
    }
    return 0;
  },
  wasm_fetch_body_length__deps: ['$WasmRT'],
  wasm_fetch_body_length: (id) => {
    const r = WasmRT.reqs.get(id);
    return (r && r.body) ? r.body.length : -1;
  },
  wasm_fetch_body_copy__deps: ['$WasmRT'],
  wasm_fetch_body_copy: (id, dst) => {
    const r = WasmRT.reqs.get(id);
    if (r && r.body) HEAPU8.set(r.body, dst);
  },
  wasm_fetch_free__deps: ['$WasmRT'],
  wasm_fetch_free: (id) => { WasmRT.reqs.delete(id); },


  // ------------------------------------------------------------ audio
  // Direct Audio playback (PLATFORM_API_WasmOS_WebAudio.c).  Each line
  // resamples its float PCM to the AudioContext rate and schedules one
  // AudioBufferSourceNode per write back to back.  While the context is not
  // running (browsers start it suspended until the first user gesture) and
  // with Module.nullAudio (no Web Audio, e.g. Node.js) the audio is
  // consumed in real time and discarded, so Java code never stalls.
  $WasmAudio__deps: ['$WasmRT'],
  $WasmAudio: {
    ctx: undefined,
    lines: new Map(),
    nextLine: 1,
    LATENCY: 0.03,
    context() {
      if (WasmAudio.ctx !== undefined) return WasmAudio.ctx;
      WasmAudio.ctx = null;
      const AC = globalThis.AudioContext || globalThis.webkitAudioContext;
      if (Module['audioContext']) {
        WasmAudio.ctx = Module['audioContext'];
      } else if (AC && !Module['nullAudio']) {
        try { WasmAudio.ctx = new AC({ latencyHint: 'playback' }); } catch (e) { WasmAudio.ctx = null; }
      }
      const ctx = WasmAudio.ctx;
      if (ctx && ctx.state !== 'running' && typeof document !== 'undefined') {
        // autoplay policy: resume on the first user gesture
        const resume = () => {
          ctx.resume().then(() => {
            if (ctx.state === 'running') {
              for (const ev of ['pointerdown', 'mousedown', 'keydown', 'touchend'])
                document.removeEventListener(ev, resume, true);
            }
          }, () => {});
        };
        for (const ev of ['pointerdown', 'mousedown', 'keydown', 'touchend'])
          document.addEventListener(ev, resume, true);
      }
      return ctx;
    },
    live() {
      const ctx = WasmAudio.ctx;
      return !!(ctx && ctx.state === 'running');
    },
    perfNow() {
      return (typeof performance !== 'undefined' ? performance.now() : Date.now()) / 1000;
    },
    prune(line) {
      if (!WasmAudio.live()) return;
      const now = WasmAudio.ctx.currentTime;
      while (line.chunks.length && line.chunks[0].t0 + line.chunks[0].buf.duration <= now)
        line.chunks.shift();
    },
    // seconds of audio not yet played
    pending(line) {
      let s = 0;
      for (const p of line.paused) s += p.buf ? p.buf.duration - p.off : p.dur;
      if (line.running) {
        if (WasmAudio.live()) s += Math.max(0, line.end - WasmAudio.ctx.currentTime);
        s += Math.max(0, line.vend - WasmAudio.perfNow());
      }
      return s;
    },
    // resample interleaved float frames to the output rate, one AudioBuffer
    toBuffer(line, src, frames) {
      const ctx = WasmAudio.ctx, ch = line.channels;
      const outRate = ctx.sampleRate;
      if (outRate === line.rate) {
        const b = ctx.createBuffer(ch, frames, outRate);
        for (let c = 0; c < ch; c++) {
          const d = b.getChannelData(c);
          for (let i = 0; i < frames; i++) d[i] = src[i * ch + c];
        }
        return b;
      }
      const step = line.rate / outRate;
      let t = line.t;
      const n = Math.max(0, Math.ceil((frames - t) / step));
      if (n === 0) {
        // nothing to emit yet; keep state consistent
        line.t = t - frames;
        for (let c = 0; c < ch; c++) line.prev[c] = src[(frames - 1) * ch + c];
        return null;
      }
      const b = ctx.createBuffer(ch, n, outRate);
      for (let c = 0; c < ch; c++) {
        const d = b.getChannelData(c), prev = line.prev[c];
        let tt = t;
        for (let k = 0; k < n; k++, tt += step) {
          const i = Math.floor(tt), f = tt - i;
          const y0 = i === 0 ? prev : src[(i - 1) * ch + c];
          const y1 = i < frames ? src[i * ch + c] : y0;
          d[k] = y0 + (y1 - y0) * f;
        }
        line.prev[c] = src[(frames - 1) * ch + c];
      }
      line.t = t + n * step - frames;
      return b;
    },
    schedule(line, buf, off) {
      const ctx = WasmAudio.ctx;
      const node = ctx.createBufferSource();
      node.buffer = buf;
      node.connect(ctx.destination);
      const t0 = Math.max(line.end, ctx.currentTime + WasmAudio.LATENCY);
      node.start(t0, off || 0);
      const chunk = { buf, node, t0: t0 - (off || 0) };
      line.chunks.push(chunk);
      line.end = t0 + buf.duration - (off || 0);
    },
  },
  wasm_audio_available__deps: ['$WasmAudio'],
  wasm_audio_available: () => (WasmAudio.context() || Module['nullAudio']) ? 1 : 0,
  wasm_audio_open__deps: ['$WasmAudio'],
  wasm_audio_open: (rate, channels, bufferFrames) => {
    const ctx = WasmAudio.context();
    if (!ctx && !Module['nullAudio']) return 0;
    const id = WasmAudio.nextLine++;
    WasmAudio.lines.set(id, {
      rate, channels, bufferFrames, running: false,
      chunks: [], paused: [], end: 0, vend: 0,
      t: 1, prev: new Float32Array(channels),
    });
    return id;
  },
  wasm_audio_buffered__deps: ['$WasmAudio'],
  wasm_audio_buffered: (id) => {
    const line = WasmAudio.lines.get(id);
    if (!line) return 0;
    WasmAudio.prune(line);
    return Math.min(line.bufferFrames, Math.round(WasmAudio.pending(line) * line.rate));
  },
  wasm_audio_write__deps: ['$WasmAudio'],
  wasm_audio_write: (id, ptr, frames) => {
    const line = WasmAudio.lines.get(id);
    if (!line) return -1;
    const src = HEAPF32.subarray(ptr >> 2, (ptr >> 2) + frames * line.channels);
    if (Module['onAudioWrite']) Module['onAudioWrite'](src, line.rate, line.channels);
    const dur = frames / line.rate;
    if (!WasmAudio.live()) {
      // not audible (yet): consume in real time
      if (line.running) {
        line.vend = Math.max(line.vend, WasmAudio.perfNow()) + dur;
      } else {
        line.paused.push({ buf: null, off: 0, dur });
      }
      return frames;
    }
    const buf = WasmAudio.toBuffer(line, src, frames);
    if (!buf) return frames;
    if (line.running) WasmAudio.schedule(line, buf, 0);
    else line.paused.push({ buf, off: 0 });
    return frames;
  },
  wasm_audio_start__deps: ['$WasmAudio'],
  wasm_audio_start: (id) => {
    const line = WasmAudio.lines.get(id);
    if (!line || line.running) return;
    line.running = true;
    const queued = line.paused;
    line.paused = [];
    for (const p of queued) {
      if (p.buf && WasmAudio.live()) WasmAudio.schedule(line, p.buf, p.off);
      else line.vend = Math.max(line.vend, WasmAudio.perfNow()) +
                       (p.buf ? p.buf.duration - p.off : p.dur);
    }
  },
  wasm_audio_stop__deps: ['$WasmAudio'],
  wasm_audio_stop: (id) => {
    const line = WasmAudio.lines.get(id);
    if (!line || !line.running) return;
    line.running = false;
    const live = WasmAudio.live();
    const now = live ? WasmAudio.ctx.currentTime : 0;
    for (const c of line.chunks) {
      const left = c.t0 + c.buf.duration - now;
      if (live && left <= 0) continue;
      try { c.node.stop(); c.node.disconnect(); } catch (e) {}
      if (live) line.paused.push({ buf: c.buf, off: Math.max(0, now - c.t0) });
    }
    line.chunks = [];
    line.end = 0;
    const v = line.vend - WasmAudio.perfNow();
    if (v > 0) line.paused.push({ buf: null, off: 0, dur: v });
    line.vend = 0;
  },
  wasm_audio_flush__deps: ['$WasmAudio'],
  wasm_audio_flush: (id) => {
    const line = WasmAudio.lines.get(id);
    if (!line) return;
    for (const c of line.chunks) { try { c.node.stop(); c.node.disconnect(); } catch (e) {} }
    line.chunks = []; line.paused = []; line.end = 0; line.vend = 0;
    line.t = 1; line.prev.fill(0);
  },
  wasm_audio_close__deps: ['$WasmAudio', 'wasm_audio_flush'],
  wasm_audio_close: (id) => { _wasm_audio_flush(id); WasmAudio.lines.delete(id); },

  // ---------------------------------------------------------- browser
  wasm_browser_show_document__deps: ['$WasmRT'],
  wasm_browser_show_document: (urlPtr, targetPtr) => {
    const url = UTF8ToString(urlPtr);
    const target = targetPtr ? UTF8ToString(targetPtr) : '_self';
    if (Module['onShowDocument']) { Module['onShowDocument'](url, target); return; }
    if (typeof window !== 'undefined') {
      if (target === '_self' || target === '_top' || target === '_parent') {
        (target === '_self' ? window : window.top).location.href = url;
      } else {
        window.open(url, target);
      }
    }
  },
  wasm_browser_show_status__deps: ['$WasmRT'],
  wasm_browser_show_status: (ptr) => { WasmRT.status(UTF8ToString(ptr)); },
  wasm_browser_page_url__deps: ['$WasmRT', 'malloc'],
  wasm_browser_page_url: () => WasmRT.allocString(
      typeof location !== 'undefined' ? location.href : 'file:///'),

  // ------------------------------------------- LiveConnect (JSObject)
  // Operations on JavaScript objects; values are exchanged as tagged
  // strings (see WasmRT.encode/decode).  Returns a malloc'ed string.
  wasm_js_op__deps: ['$WasmRT', 'malloc'],
  wasm_js_op: (op, handle, namePtr, argsPtr) => {
    const obj = handle === 1 ? globalThis : WasmRT.handles[handle];
    const name = namePtr ? UTF8ToString(namePtr) : '';
    const rawArgs = argsPtr ? UTF8ToString(argsPtr) : '';
    const args = rawArgs.length ? rawArgs.split('\x1f').map(WasmRT.decode) : [];
    let result;
    try {
      switch (op) {
        case 0: result = obj[name]; break;                       // getMember
        case 1: obj[name] = args[0]; result = undefined; break;  // setMember
        case 2: delete obj[name]; result = undefined; break;     // removeMember
        case 3: result = obj[name].apply(obj, args); break;      // call
        case 4: result = (0, eval)(name); break;                 // eval
        case 5: result = obj[Number(name)]; break;               // getSlot
        case 6: obj[Number(name)] = args[0]; break;              // setSlot
        case 7: result = String(obj); break;                     // toString
        case 8: WasmRT.handles[handle] = undefined;              // release
                if (handle > 1) WasmRT.freeHandles.push(handle);
                break;
      }
      return WasmRT.allocString('+' + WasmRT.encode(result));
    } catch (e) {
      return WasmRT.allocString('!' + String(e && e.message ? e.message : e));
    }
  },
});
