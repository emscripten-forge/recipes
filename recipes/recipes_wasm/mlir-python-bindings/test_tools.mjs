import assert from "node:assert/strict";
import path from "node:path";
import { pathToFileURL } from "node:url";

// Match WasmBolt: initialize, restore files, then invoke each tool once.
async function run(tool, args, input, output) {
  const url = pathToFileURL(path.join(process.env.PREFIX, "bin", `${tool}.js`));
  const { default: createTool } = await import(url.href);
  const stderr = [];
  let exitCode;
  const module = await createTool({
    noInitialRun: true,
    thisProgram: tool,
    print: () => {},
    printErr: (s) => stderr.push(s),
    onExit: (status) => { exitCode = status; },
  });
  module.FS.writeFile("/in.mlir", input);
  try {
    exitCode = module.callMain([...args, "/in.mlir", "-o", output]);
  } catch (error) {
    if (error?.name !== "ExitStatus" || !Number.isInteger(error.status)) throw error;
    exitCode = error.status;
  }
  assert.equal(exitCode, 0, `${tool}: ${stderr.join("\n")}`);
  return module.FS.readFile(output, { encoding: "utf8" });
}

const input = `module {
  func.func @answer() -> i32 {
    %a = arith.constant 19 : i32
    %b = arith.constant 23 : i32
    %sum = arith.addi %a, %b : i32
    return %sum : i32
  }
}`;
const lowered = await run("mlir-opt", [
  "--canonicalize", "--convert-arith-to-llvm", "--convert-func-to-llvm",
  "--reconcile-unrealized-casts",
], input, "/out.mlir");
const llvmIR = await run("mlir-translate", ["--mlir-to-llvmir"], lowered, "/out.ll");
assert.match(llvmIR, /define i32 @answer\(/);
assert.match(llvmIR, /ret i32 42/);
console.log("MLIR lowering and LLVM IR translation passed");
