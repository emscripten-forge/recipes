import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import createModule from "./test_main.js";

const __dirname = path.dirname(fileURLToPath(import.meta.url));




const PYTHON_ROOT = path.join(
  process.env.PREFIX,
  "lib",
  "python3.14",
);


function ensureVirtualFSPathForFile(Module, fsPath) {
  const filename = path.posix.basename(fsPath);
  const dirPath = path.posix.dirname(fsPath);

  // Create the directory structure in the virtual FS if it doesn't exist
  if (!Module.FS.analyzePath(dirPath).exists) {
    Module.FS.mkdirTree(dirPath);
  }
}

function copyPyFiles(Module, hostDir, fsDir) {
  for (const entry of fs.readdirSync(hostDir, { withFileTypes: true })) {
    const hostPath = path.join(hostDir, entry.name);
    const fsPath = path.posix.join(fsDir, entry.name);
    if (entry.isDirectory()) {
      Module.FS.mkdirTree(fsPath);
      copyPyFiles(Module, hostPath, fsPath);
    } else if (entry.isFile() && entry.name.endsWith(".py")) {
      ensureVirtualFSPathForFile(Module, fsPath);
      Module.FS.writeFile(fsPath, fs.readFileSync(hostPath));
    }
  }
}

const Module = await createModule({
  ENV: {
    "PYTHONHOME": "/",
    "PYTHONPATH": "/lib/python3.14",
  },
});


console.log("Copying Python files to Emscripten FS...");
copyPyFiles(
  Module,
  PYTHON_ROOT,
  "/lib/python3.14",
);
console.log("Python files copied to Emscripten FS.");
// Everything is mounted now.


// --- call trampoline ---------------------------------------------------------
// checked first: a second Py_Initialize (after Py_FinalizeEx) resets _PyRuntime
// to its initial values, ie. back to the JS trampoline (pystate.c)
// C functions with 0..3 arguments are called through the trampoline
// (METH_NOARGS / METH_O / METH_VARARGS / METH_VARARGS|METH_KEYWORDS ...)
const trampoline_code = `
import math, itertools, operator
assert len([1, 2]) == 2                         # METH_O
assert "abc".upper() == "ABC"                   # METH_NOARGS
assert "a,b".split(",") == ["a", "b"]           # METH_FASTCALL|METH_KEYWORDS
assert sorted([3, 1, 2], reverse=True) == [3, 2, 1]
assert math.hypot(3, 4) == 5.0                  # METH_FASTCALL
assert dict(a=1)["a"] == 1
assert list(itertools.islice(itertools.count(), 3)) == [0, 1, 2]
assert operator.add(1, 2) == 3
assert {1: 2}.get(1) == 2
assert [1, 2].index(2) == 1
assert int("10", base=2) == 2
print("trampoline calls ok")
`;
const ret_trampoline = Module.ccall('run_python', 'number', ['string'], [trampoline_code]);
if (Number(ret_trampoline) !== 0) {
  throw new Error(`calls through the trampoline failed (return code ${ret_trampoline})`);
}

const pointer_size = Number(Module.ccall('pointer_size', 'number', [], []));
const uses_wasm_gc = Number(Module.ccall('uses_wasm_gc_trampoline', 'number', [], []));
const wasm_gc_supported = (() => {
  // a module with a wasm-gc struct type
  try {
    return WebAssembly.validate(new Uint8Array([
      0, 97, 115, 109, 1, 0, 0, 0, 1, 3, 1, 95, 0]));
  } catch (e) {
    return false;
  }
})();
console.log(`pointer size ${pointer_size}, wasm-gc supported ${wasm_gc_supported}, wasm-gc trampoline used ${uses_wasm_gc === 1}`);
if (pointer_size === 4 && wasm_gc_supported && uses_wasm_gc !== 1) {
  throw new Error("wasm32: the wasm-gc call trampoline is not used (JS trampoline breaks JSPI stack switching)");
}




let ret_code_0 = Module.ccall(
  'run_python',     // C function name
  'number',         // Return type
  ['string'],       // Argument types
  ["print('hello world')"] // Arguments
);
if (Number(ret_code_0) !== 0) {
  throw new Error(`Python code did not return the return code when no exception was raised. Expected 0, got ${ret_code_0}`);
}

ret_code_0 = Module.ccall(
  'run_python',     // C function name
  'number',         // Return type
  ['string'],       // Argument types
  ["import platform; print(platform.platform())"] // Arguments
);
if (Number(ret_code_0) !== 0) {
  throw new Error(`Python code did not return the return code when no exception was raised. Expected 0, got ${ret_code_0}`);
}
  


const ret_code = Module.ccall(
  'run_python',     // C function name
  'number',         // Return type
  ['string'],       // Argument types
  ["raise Exception('This is an expected test exception DONT WORRY')"] // Arguments
);
if (Number(ret_code) === 1) {
  console.log("Python code returned the expected return code when an exception was raised.");
}
else {
  throw new Error(`Python code did not return the return code when an exception was raised. Expected 1, got ${ret_code}`);
}
  