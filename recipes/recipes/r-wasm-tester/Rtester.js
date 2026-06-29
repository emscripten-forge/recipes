const path = require("node:path");

const wasmRHome = "/RPY";
const hostRHome = path.join(process.env.PREFIX, "lib", "RPY");
const rExecDir = path.join(hostRHome, "bin", "exec");
const rLibDir = path.join(hostRHome, "lib");
const prefixLibDir = path.join(process.env.PREFIX, "lib");

const rScriptPath = process.argv[2];
const rScriptBody = require("node:fs").readFileSync(rScriptPath, "utf8");
const rArgs = ["--no-restore", "--vanilla", "-e", rScriptBody];

var Module = {
  noInitialRun: true,
  locateFile: (file) => {
    const fs = require("node:fs");
    const normalized = file.replace("$PREFIX", process.env.PREFIX);
    if (fs.existsSync(normalized)) {
      return normalized;
    }
    const base = path.basename(normalized);
    for (const dir of [prefixLibDir, rExecDir, rLibDir]) {
      const candidate = path.join(dir, base);
      if (fs.existsSync(candidate)) {
        return candidate;
      }
    }
    for (const dir of [prefixLibDir, rExecDir, rLibDir]) {
      const candidate = path.join(dir, normalized);
      if (fs.existsSync(candidate)) {
        return candidate;
      }
    }
    for (const dir of [rExecDir, rLibDir]) {
      const candidate = path.join(dir, file);
      if (fs.existsSync(candidate)) {
        return candidate;
      }
    }
    return path.join(rExecDir, file);
  },
  preRun: [() => {
    const fs = require("node:fs");
    const copyTree = (srcRoot, dstRoot) => {
      Module.FS.mkdirTree(dstRoot);
      for (const entry of fs.readdirSync(srcRoot, { withFileTypes: true })) {
        const src = path.join(srcRoot, entry.name);
        const dst = `${dstRoot}/${entry.name}`;
        if (entry.isDirectory()) {
          copyTree(src, dst);
        } else if (entry.isFile()) {
          Module.FS.writeFile(dst, fs.readFileSync(src));
        }
      }
    };

    // R_HOME tree (etc, share, library, modules) and /lib for dynload paths.
    copyTree(hostRHome, wasmRHome);
    copyTree(rLibDir, "/lib");
  }],
  onRuntimeInitialized() {
    Module.callMain(rArgs);
  },
};

let glue = require("node:fs").readFileSync(path.join(rExecDir, "R"), "utf8");
const envLiteral = JSON.stringify({
  R_HOME: wasmRHome,
});
glue = glue.replace("var ENV={};", `var ENV=${envLiteral};`);
eval(glue);
