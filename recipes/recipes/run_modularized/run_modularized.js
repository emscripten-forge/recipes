#!/usr/bin/env node

const binary_js_runner = process.argv[2];
process.argv = process.argv.slice(3);
let already_called = false;
async function my_main(){
    let exitCode = 126;  // "Command invoked cannot execute"
    const ModuleF = require(binary_js_runner);
    const Module = await ModuleF({
        arguments: process.argv,
        quit: (status, toThrow) => {
            if (already_called) {
                return;
            }
            already_called = true;
            exitCode = status;
        }
    });
    return exitCode;
}
(async function() {
    const exitCode = await my_main();
    // exit the process
    process.exit(exitCode);
})();