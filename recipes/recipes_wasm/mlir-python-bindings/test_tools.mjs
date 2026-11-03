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

const vectorStores = await run("mlir-opt", ["--spirv-unify-aliased-resource"], `
spirv.module Logical GLSL450 {
  spirv.GlobalVariable @canonical bind(0, 0) {aliased} : !spirv.ptr<!spirv.struct<(!spirv.rtarray<vector<2xf32>, stride=8> [0])>, StorageBuffer>
  spirv.GlobalVariable @wide bind(0, 0) {aliased} : !spirv.ptr<!spirv.struct<(!spirv.rtarray<vector<4xf32>, stride=16> [0])>, StorageBuffer>
  spirv.func @store(%value: vector<4xf32>) "None" {
    %c0 = spirv.Constant 0 : i32
    %base = spirv.mlir.addressof @wide : !spirv.ptr<!spirv.struct<(!spirv.rtarray<vector<4xf32>, stride=16> [0])>, StorageBuffer>
    %ptr = spirv.AccessChain %base[%c0, %c0] : !spirv.ptr<!spirv.struct<(!spirv.rtarray<vector<4xf32>, stride=16> [0])>, StorageBuffer>, i32, i32 -> !spirv.ptr<vector<4xf32>, StorageBuffer>
    spirv.Store "StorageBuffer" %ptr, %value ["Aligned", 16] : vector<4xf32>
    spirv.Return
  }
}`, "/stores.mlir");
assert.doesNotMatch(vectorStores, /@wide/);
assert.equal((vectorStores.match(/spirv.Store/g) ?? []).length, 2);
assert.match(vectorStores, /spirv.Store[^\n]+\["Aligned", 16\] : vector<2xf32>/);
assert.match(vectorStores, /spirv.Store[^\n]+\["Aligned", 8\] : vector<2xf32>/);

const softmax = await run("mlir-opt", ["--transform-interpreter"], `
module attributes {transform.with_named_sequence} {
  func.func @softmax(%input: tensor<2x4xf32>, %output: tensor<2x4xf32>) -> tensor<2x4xf32> {
    %result = linalg.softmax dimension(1) ins(%input : tensor<2x4xf32>) outs(%output : tensor<2x4xf32>) -> tensor<2x4xf32>
    return %result : tensor<2x4xf32>
  }
  transform.named_sequence @__transform_main(%root: !transform.any_op {transform.readonly}) {
    %op = transform.structured.match ops{["linalg.softmax"]} in %root : (!transform.any_op) -> !transform.any_op
    %result = transform.structured.decompose_interface %op : (!transform.any_op) -> !transform.any_op
    transform.yield
  }
}`, "/softmax.mlir");
assert.match(softmax, /arith.constant -3\.40282347E\+38 : f32/);
assert.doesNotMatch(softmax, /0xFFC00000/);
console.log("Aliased vector stores and finite softmax initializer passed");
