import tempfile
import os
import yaml
import subprocess
import shutil

NODE_TEST_FILE_STR = """
let Module = {};
var createModule = require('./embed.js')

function waitRunDependency() {
  const promise = new Promise((r) => {
    Module.monitorRunDependencies = (n) => {
      if (n === 0) {
        r();
      }
    };
  });
  Module.addRunDependency("dummy");
  Module.removeRunDependency("dummy");
  return promise;
}
const print = (text) => {
  console.log(text)
}
const sink = (text) =>{}

let res = (async function() {
  // var embed = await import('./embed.js')
  var opts = {}
  opts = {print:sink, error:sink}
  var myModule = await createModule()
  Module = myModule
  global.Module = Module
  await import('./python_data.js')
  await import('./testdata.js')
  var deps = await waitRunDependency()

  myModule.initialize_interpreter()
  var main_scope = myModule.main_scope()
  myModule.print = print
  myModule.error = print
  var ret = myModule.run_tests("/tests")

  main_scope.delete()
  return ret
})().then(
  (r) => {
    console.log("test r",r)
    if(r == 1)
    {
      throw "Test(s) failed!"; 
    }
  }
)
"""


def get_pytest_files(recipe_dir, recipe):
    extra = recipe.get('extra',{})
    emscripten_tests = extra.get('emscripten_tests',{})
    python = emscripten_tests.get('python',{})
    pytest_files = python.get('pytest_files',[])
    pytest_files = [os.path.join(recipe_dir, f) for f in pytest_files]
    return pytest_files


def create_test_env(pkg_name, prefix):
    # cmd = ['$MAMBA_EXE' ,'create','--prefix', prefix,'--platform=emscripten-32'] + [pkg_name] #+ ['--dryrun']
    print("prefix",prefix)
    cmd = [f'$MAMBA_EXE create --yes --prefix {prefix} --platform=emscripten-32   python embind11_node pytest {pkg_name}']
    ret = subprocess.run(cmd, shell=True)
    #  stderr=subprocess.PIPE, stdout=subprocess.PIPE)
    returncode = ret.returncode
    assert returncode == 0

def pack(prefix, pytest_files):
    assert len(pytest_files) <= 1, "atm only one file is allowed"

    cmd = [f"emboa pack python core {prefix} --version=3.10 --export-name='global.Module'"]
    ret = subprocess.run(cmd, shell=True)

    cmd = [f"emboa pack file  {pytest_files[0]}  '/tests'  testdata --export-name='global.Module'"]
    ret = subprocess.run(cmd, shell=True)


def copy_from_prefix(prefix,work_dir):
    # copy wasm / js file to work dir
    js_file = os.path.join(prefix,'bin','embed.js')
    shutil.copy(js_file, work_dir)
    wasm_file = os.path.join(prefix,'bin','embed.wasm')
    shutil.copy(wasm_file, work_dir)


def patch(work_dir):
    js_file = os.path.join(work_dir,'embed.js')
    # Read in the file
    with open(js_file, 'r') as file :
      filedata = file.read()

    # Replace the target string
    filedata = filedata.replace('push(audioPlugin)', 'push(imagePlugin)')

    # Write the file out again
    with open(js_file, 'w') as file:
      file.write(filedata)

def run_node_tests(work_dir):
    # Write the file out again
    with open(os.path.join(work_dir,"test.js"), 'w') as file:
        file.write(NODE_TEST_FILE_STR)
    
    os.chdir(work_dir)
    cmd = [f'node  --no-warnings test.js']
    ret = subprocess.run(cmd, shell=True)
    if ret.returncode != 0:
        raise RuntimeError("Tests Failed")

def test_package(recipe_dir):
    assert os.path.isdir(recipe_dir)
    recipe_file = os.path.join(recipe_dir, 'recipe.yaml')

    has_tests = False
    with open(recipe_file, 'r') as stream:
        recipe=yaml.safe_load(stream)
    pytest_files = get_pytest_files(recipe_dir, recipe)
    has_tests = len(pytest_files) > 0

    if has_tests:
        pkg_name = recipe['package']['name']
        with tempfile.TemporaryDirectory() as temp_dir:
            prefix = os.path.join(temp_dir,'prefix')
            work_dir = os.path.join(temp_dir,'work')
            os.mkdir(work_dir)
            os.chdir(work_dir)
            create_test_env(pkg_name=pkg_name, prefix=prefix)
            pack(prefix=prefix, pytest_files=pytest_files)
            copy_from_prefix(prefix=prefix, work_dir=work_dir)
            patch(work_dir=work_dir)
            run_node_tests(work_dir=work_dir)

if __name__ == "__main__":

  import argparse
  parser = argparse.ArgumentParser()
  parser.add_argument("recipe_dir")
  args = parser.parse_args()
  
  test_package(args.recipe_dir)

  import sys
  sys.exit(0)