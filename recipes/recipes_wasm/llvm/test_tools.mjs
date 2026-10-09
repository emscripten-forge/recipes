import assert from "node:assert/strict";
import path from "node:path";
import { pathToFileURL } from "node:url";

// Each command gets its own module, as it would in a disposable browser worker.
async function run(tool, args, inputs = {}, outputs = []) {
  const url = pathToFileURL(path.join(process.env.PREFIX, "bin", `${tool}.js`));
  const { default: createTool } = await import(url.href);
  const stdout = [];
  const stderr = [];
  let exitCode;
  const module = await createTool({
    arguments: args,
    preRun: [(m) => {
      for (const [name, data] of Object.entries(inputs)) m.FS.writeFile(name, data);
    }],
    print: (s) => stdout.push(s),
    printErr: (s) => stderr.push(s),
    onExit: (status) => { exitCode = status; },
  });
  assert.equal(exitCode, 0, `${tool}: ${stderr.join("\n")}`);
  const files = Object.fromEntries(outputs.map(name =>
    [name, Buffer.from(module.FS.readFile(name))]));
  return { stdout: stdout.join("\n"), files };
}

const ir = "define i32 @answer() {\n  %x = add i32 19, 23\n  ret i32 %x\n}\n";
const optimized = await run("opt", ["-passes=instcombine", "-S", "/in.ll", "-o", "/out.ll"],
  { "/in.ll": ir }, ["/out.ll"]);
assert.match(optimized.files["/out.ll"].toString(), /ret i32 42/);

const triple = process.env.target_platform === "emscripten-wasm64"
  ? "wasm64-unknown-unknown" : "wasm32-unknown-unknown";
const compiled = await run("llc", [`-mtriple=${triple}`, "-filetype=obj", "/in.ll", "-o", "/answer.o"],
  { "/in.ll": optimized.files["/out.ll"] }, ["/answer.o"]);
const object = compiled.files["/answer.o"];
assert.deepEqual([...object.subarray(0, 4)], [0, 97, 115, 109]);

const inputs = { "/answer.o": object };
assert.match((await run("llvm-nm", ["/answer.o"], inputs)).stdout, /\banswer\b/);
assert.match((await run("llvm-readobj", ["--file-headers", "/answer.o"], inputs)).stdout, /wasm/i);
assert.match((await run("llvm-objdump", ["-h", "/answer.o"], inputs)).stdout, /wasm/i);
assert.match((await run("llvm-size", ["/answer.o"], inputs)).stdout, /answer\.o/);
assert.match((await run("llvm-cxxfilt", ["_Z3fooi"])).stdout, /foo\(int\)/);

const archive = await run("llvm-ar", ["rc", "/answer.a", "/answer.o"], inputs, ["/answer.a"]);
assert.equal(archive.files["/answer.a"].subarray(0, 8).toString(), "!<arch>\n");
const stripped = await run("llvm-objcopy", ["--strip-debug", "/answer.o", "/stripped.o"],
  inputs, ["/stripped.o"]);
assert.deepEqual([...stripped.files["/stripped.o"].subarray(0, 4)], [0, 97, 115, 109]);

console.log("LLVM optimization, code generation and object utilities passed");
