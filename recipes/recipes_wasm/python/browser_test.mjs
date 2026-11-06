// Runs the plain python tests (python_tests.mjs) in the browser, driven by
// browser_test.py (playwright). The python stdlib is preloaded into the
// emscripten FS (--preload-file, see build_tests.sh).
import { pythonTests } from "./python_tests.mjs";

function wasmGcSupported() {
  // a module with a wasm-gc struct type
  try {
    return WebAssembly.validate(new Uint8Array([0, 97, 115, 109, 1, 0, 0, 0, 1, 3, 1, 95, 0]));
  } catch (e) {
    return false;
  }
}

globalThis.runPythonTests = async function () {
  const Module = await createModule({
    ENV: { PYTHONHOME: "/", PYTHONPATH: "/lib/python3.14" },
  });
  const run = (code) => Number(Module.ccall("run_python", "number", ["string"], [code]));
  const results = [];
  // first: a second Py_Initialize resets _PyRuntime, ie. the call trampoline
  const trampolineOk = run("import math; assert math.hypot(3, 4) == 5.0; assert 'a'.upper() == 'A'") === 0;
  const pointerSize = Number(Module.ccall("pointer_size", "number", [], []));
  const wasmGcTrampoline = Number(Module.ccall("uses_wasm_gc_trampoline", "number", [], [])) === 1;
  results.push({ name: "trampoline calls", ok: trampolineOk });
  for (const test of pythonTests) {
    console.log(`=== ${test.name}`);
    results.push({ name: test.name, ok: run(test.code) === 0 });
  }
  return {
    results,
    pointerSize,
    wasmGcSupported: wasmGcSupported(),
    wasmGcTrampoline,
    jspiSupported: "Suspending" in WebAssembly,
    userAgent: navigator.userAgent,
  };
};
