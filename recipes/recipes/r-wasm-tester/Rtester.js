const path = require("node:path");

const wasmRHome = "/R";
const hostRHome = path.join(process.env.PREFIX, "lib", "R");
const rExecDir = path.join(hostRHome, "bin", "exec");
const rLibDir = path.join(hostRHome, "lib");
const rScriptPath = process.argv[2];
const rScriptBody = require("node:fs").readFileSync(rScriptPath, "utf8");
const rArgs = ["--no-restore", "--vanilla", "-e", rScriptBody];

var Module = {
  noInitialRun: true,
  locateFile: (file) => {
    const fs = require("node:fs");
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

    // Populate the virtual FS with what R needs at runtime.
    copyTree(`${hostRHome}/etc`, `${wasmRHome}/etc`);
    copyTree(`${hostRHome}/share`, `${wasmRHome}/share`);
    copyTree(`${hostRHome}/library`, `${wasmRHome}/library`);
    copyTree(`${hostRHome}/modules`, `${wasmRHome}/modules`);
    copyTree(rLibDir, "/lib");
  }],
  onRuntimeInitialized() {
    Module.callMain(rArgs);
  },
};

let glue = require("node:fs").readFileSync(path.join(rExecDir, "R"), "utf8");
const envLiteral = JSON.stringify({
  R_HOME: wasmRHome,
  R_SHARE_DIR: `${wasmRHome}/share`,
  R_INCLUDE_DIR: `${wasmRHome}/include`,
  R_DOC_DIR: `${wasmRHome}/doc`,
});
glue = glue.replace("var ENV={};", `var ENV=${envLiteral};`);
eval(glue);
