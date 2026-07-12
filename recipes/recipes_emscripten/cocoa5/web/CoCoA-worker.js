importScripts("https://cdn.jsdelivr.net/npm/xterm-pty@0.9.4/workerTools.js");

onmessage = (msg) => {
  self.Module = self.Module || {};
  self.Module.preRun = self.Module.preRun || [];
  
  self.Module.ENV = { "LANG": "C", "LC_ALL": "C" };

  self.Module.preRun.push(() => {
    try { FS.mkdirTree('/src/CoCoA-5/bin'); } catch(e) {}
    FS.chdir('/src/CoCoA-5'); 
  });

  importScripts("CoCoAInterpreter");
  importScripts("CoCoAInterpreter.data.js");

  emscriptenHack(new TtyClient(msg.data));
};