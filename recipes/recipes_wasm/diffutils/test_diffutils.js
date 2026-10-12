// Functional test: run diff/cmp on files created in the emscripten FS.
const assert = require("assert");
const path = require("path");

function load(name) {
  return require(path.join(process.env.PREFIX, "bin", name + ".js"));
}

async function run(name, args, inputs) {
  const factory = load(name);
  const out = [];
  const err = [];
  let status = 0;
  const options = {
    arguments: args,
    print: (s) => out.push(s),
    printErr: (s) => err.push(s),
    onExit: (s) => { status = s; },
    preRun: [(m) => {
      for (const [file, data] of Object.entries(inputs || {})) m.FS.writeFile(file, data);
    }],
  };
  try {
    await factory(options);
  } catch (e) {
    if (e && typeof e.status === "number") status = e.status;
    else throw e;
  }
  // emscripten's node runtime sets process.exitCode to the program status,
  // which would fail the test script on a normal "files differ" exit.
  process.exitCode = 0;
  return { status, stdout: out.join("\n"), stderr: err.join("\n") };
}

const FROM = "1\n2\n3\n";
const TO = "1\nx\n3\n4\n";

(async () => {
  const version = await run("diff", ["--version"]);
  assert.match(version.stdout, /diff \(GNU diffutils\) 3\./, "diff --version");

  const same = await run("diff", ["a.txt", "b.txt"], { "/a.txt": FROM, "/b.txt": FROM });
  assert.strictEqual(same.status, 0, "identical files: " + same.stderr);
  assert.strictEqual(same.stdout, "", "identical files produce no output");

  const differing = await run("diff", ["-u", "a.txt", "b.txt"], { "/a.txt": FROM, "/b.txt": TO });
  assert.strictEqual(differing.status, 1, "differing files: " + differing.stderr);
  assert.strictEqual(
    differing.stdout.replace(/^--- a\.txt.*$/m, "--- a.txt").replace(/^\+\+\+ b\.txt.*$/m, "+++ b.txt"),
    "--- a.txt\n+++ b.txt\n@@ -1,3 +1,4 @@\n 1\n-2\n+x\n 3\n+4",
    "diff -u output");

  const cmpSame = await run("cmp", ["a.txt", "b.txt"], { "/a.txt": FROM, "/b.txt": FROM });
  assert.strictEqual(cmpSame.status, 0, "cmp identical: " + cmpSame.stderr);

  const cmp = await run("cmp", ["a.bin", "b.bin"], {
    "/a.bin": Buffer.from([0, 1, 2, 255]),
    "/b.bin": Buffer.from([0, 1, 3, 255]),
  });
  assert.strictEqual(cmp.status, 1, "cmp mismatch: " + cmp.stderr);
  assert.match(cmp.stdout, /differ: char 3, line 1/, "cmp report");

  console.log("diffutils diff/cmp OK");
})().catch((e) => { console.error(e); process.exit(1); });
