// import test from 'ava';
let Module = {};
var createModule = require('./embed.js')

function waitRunDependency() {
  const promise = new Promise((r) => {
    Module.monitorRunDependencies = (n) => {
      if (n === 0) {
        console.log("all `RunDependencies` loaded")
        r();
      }
    };
  });
  // If there are no pending dependencies left, monitorRunDependencies will
  // never be called. Since we can't check the number of dependencies,
  // manually trigger a call.
  Module.addRunDependency("dummy");
  Module.removeRunDependency("dummy");
  return promise;
}

const print = (text) => {
  // console.log("PRINT",text)
}




const myArgs = process.argv.slice(2);
console.log(myArgs);

(async function() {
  // var embed = await import('./embed.js')

  var myModule = await createModule({print:print, error:print})
  Module = myModule
  global.Module = Module
  await import('./python_data.js')
  await import('./testdata.js')
  var deps = await waitRunDependency()

  myModule.initialize_interpreter()
  var main_scope = myModule.main_scope()
  myModule.eval_testfile(myArgs[0], main_scope)
  main_scope.delete()

})();