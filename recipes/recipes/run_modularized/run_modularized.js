#!/usr/bin/env node

const binary_js_runner = process.argv[2];
process.argv = process.argv.slice(3);
let already_called = false;
async function my_main(){
    let exitCode = 126;  // "Command invoked cannot execute"
    const ModuleF = require(binary_js_runner);

    function setExitCode(status) {
        if (already_called) {
            return;
        }
        already_called = true;
        exitCode = status;
    }

    const Module = await ModuleF({
        arguments: process.argv,
        locateFile: (filename) => {
            // .wasm and .data files are in the same directory as the module .js file
            const path = require('path');
            const directory = path.dirname(binary_js_runner);
            return path.join(directory, filename);
        },
        onExit: (status) => setExitCode(status),
        quit: (status, toThrow) => setExitCode(status)
    });
    return exitCode;
}
(async function() {
    const exitCode = await my_main();
    // exit the process
    process.exit(exitCode);
})();