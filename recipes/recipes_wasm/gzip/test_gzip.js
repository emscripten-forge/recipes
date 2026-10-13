// Functional test: compress a binary payload and decompress it again.
const assert = require("assert");
const path = require("path");

const gzip = require(path.join(process.env.PREFIX, "bin", "gzip.js"));

const payload = Buffer.from([0, 1, 2, 3, 254, 255, 128, 64, 10, 13, 0, 26, 127, 63, 200, 199]);

async function run(args, inputs) {
  return gzip({
    arguments: args,
    preRun: [(m) => { for (const [name, data] of Object.entries(inputs)) m.FS.writeFile(name, data); }],
    printErr: (s) => process.stderr.write(s + "\n"),
    onExit: (status) => { if (status !== 0) throw new Error("gzip exited with " + status); },
  });
}

(async () => {
  const compressed = await run(["-9", "in.bin"], { "/in.bin": payload });
  const gz = Buffer.from(compressed.FS.readFile("/in.bin.gz"));
  assert.strictEqual(gz[0], 0x1f, "gzip magic byte 1");
  assert.strictEqual(gz[1], 0x8b, "gzip magic byte 2");

  const decompressed = await run(["-d", "in.bin.gz"], { "/in.bin.gz": gz });
  assert.deepStrictEqual(Buffer.from(decompressed.FS.readFile("/in.bin")), payload);
  console.log("gzip compress/decompress round trip OK");
})().catch((e) => { console.error(e); process.exit(1); });
