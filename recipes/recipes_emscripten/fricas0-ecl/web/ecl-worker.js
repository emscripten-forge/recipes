importScripts("https://cdn.jsdelivr.net/npm/xterm-pty@0.9.4/workerTools.js");

onmessage = (msg) => {
  self.Module = self.Module || {};
  self.Module.preRun = self.Module.preRun || [];
  importScripts("fricas-init.js");
  importScripts("ecl.js");

  emscriptenHack(new TtyClient(msg.data));
};