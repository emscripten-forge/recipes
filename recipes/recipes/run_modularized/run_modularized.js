#!/usr/bin/env node

const binary_js_runner = process.argv[2];
process.argv = process.argv.slice(3);
async function my_main(){
    const ModuleF = require(binary_js_runner);
    const Module = await ModuleF({
        noInitialRun: true,
        // arguments: args_without_js_path
    });
    const ret = Module.callMain(process.argv);
    return ret;
}
(async function() {
    const exitCode = await my_main();
    // exit the process
    process.exit(exitCode);
})();