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
  