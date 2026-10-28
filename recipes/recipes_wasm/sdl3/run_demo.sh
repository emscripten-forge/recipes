#!/bin/bash
set -euo pipefail

demo_dir="${PREFIX}/share/sdl3-demo"

cat > run_demo.cjs <<'EOF'
const fs = require("fs");
const path = require("path");
const vm = require("vm");

const js_path = process.argv[2];

globalThis.Module = { arguments: ["--driver=dummy", "--frames=3"] };
globalThis.window = globalThis;
globalThis.location = { search: "", href: "http://localhost/" };
globalThis.matchMedia = () => ({ matches: false, addEventListener() {}, removeEventListener() {} });
globalThis.screen = { width: 640, height: 480, orientation: null };
globalThis.addEventListener = () => {};
globalThis.removeEventListener = () => {};
globalThis.document = {
  hidden: false,
  visibilityState: "visible",
  fullscreenEnabled: false,
  body: { clientWidth: 640, clientHeight: 480, appendChild() {}, children: [] },
  addEventListener() {},
  removeEventListener() {},
  hasFocus: () => true,
  querySelector: () => null,
  getElementById: () => null,
  createElement: () => ({ style: {}, getContext: () => null }),
};
if (globalThis.navigator && !globalThis.navigator.getGamepads) {
  globalThis.navigator.getGamepads = () => [];
}

globalThis.require = require;
globalThis.__filename = js_path;
globalThis.__dirname = path.dirname(js_path);

vm.runInThisContext(fs.readFileSync(js_path, "utf8"), { filename: js_path });
EOF

timeout 60 node run_demo.cjs "$demo_dir/sdl3-demo.js"
