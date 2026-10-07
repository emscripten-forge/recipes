// Functional test: create an archive, list it, extract it, compare contents.
const assert = require("assert");
const path = require("path");

const tar = require(path.join(process.env.PREFIX, "bin", "tar.js"));

const files = {
  "/one.txt": Buffer.from("first file\n"),
  "/two.bin": Buffer.from([0, 1, 2, 250, 251, 252, 10]),
};

async function run(args, inputs, stdout) {
  return tar({
    arguments: args,
    preRun: [(m) => {
      m.FS.mkdir("/out");
      for (const [name, data] of Object.entries(inputs)) m.FS.writeFile(name, data);
    }],
    print: (s) => stdout.push(s),
    printErr: (s) => process.stderr.write(s + "\n"),
    onExit: (status) => { if (status !== 0) throw new Error("tar exited with " + status); },
  });
}

(async () => {
  const created = await run(["-cf", "/a.tar", "one.txt", "two.bin"], files, []);
  const archive = Buffer.from(created.FS.readFile("/a.tar"));
  assert.ok(archive.length >= 10240, "archive should hold both members");

  const listing = [];
  await run(["-tf", "/a.tar"], { "/a.tar": archive }, listing);
  assert.deepStrictEqual(listing, ["one.txt", "two.bin"]);

  const extracted = await run(["-xf", "/a.tar", "-C", "/out"], { "/a.tar": archive }, []);
  assert.strictEqual(Buffer.from(extracted.FS.readFile("/out/one.txt")).toString(), "first file\n");
  assert.deepStrictEqual(Array.from(extracted.FS.readFile("/out/two.bin")), Array.from(files["/two.bin"]));
  console.log("tar create/list/extract round trip OK");
})().catch((e) => { console.error(e); process.exit(1); });
