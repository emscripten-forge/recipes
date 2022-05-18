import tempfile
import os
import yaml
import subprocess
import shutil
from contextlib import contextmanager


NODE_TEST_FILE_STR = """
let Module = {};

console.log("require pytest_driver.js")
var createModule = require('./pytest_driver.js')

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
  var opts = {}
  opts = {print:sink, error:sink}
  var myModule = await createModule()
  Module = myModule
  global.Module = Module

  console.log("import python_data")
  await import('./python_data.js')
  console.log("import testdata")
  await import('./testdata.js')
  console.log("waitRunDependency")
  var deps = await waitRunDependency()
  console.log("waitRunDependency DONE")
  myModule.initialize_interpreter()
  myModule.print = print
  myModule.error = print
  try{
  var ret = myModule.run_tests("/tests")
  }
  catch(e){
    console.log(e)
    throw "Test(s) failed!"+String(e);
  }
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
    recipe_dir = os.path.abspath(recipe_dir)
    extra = recipe.get("extra", {})
    emscripten_tests = extra.get("emscripten_tests", {})
    python = emscripten_tests.get("python", {})
    pytest_files = python.get("pytest_files", [])
    pytest_files = [os.path.join(recipe_dir, f) for f in pytest_files]
    return pytest_files


def create_test_env(pkg_name, prefix):
    # cmd = ['$MAMBA_EXE' ,'create','--prefix', prefix,'--platform=emscripten-32'] + [pkg_name] #+ ['--dryrun']
    print("prefix", prefix)
    cmd = [
        f"$MAMBA_EXE create --yes --prefix {prefix} --platform=emscripten-32   python pytest_driver_node pytest {pkg_name}"
    ]
    ret = subprocess.run(cmd, shell=True)
    #  stderr=subprocess.PIPE, stdout=subprocess.PIPE)
    returncode = ret.returncode
    assert returncode == 0


def pack(prefix, pytest_files):
    assert len(pytest_files) <= 1, "atm only one file is allowed"

    cmd = [
        f"empack pack python core {prefix} --version=3.10 --export-name='global.Module'"
    ]
    ret = subprocess.run(cmd, shell=True)

    cmd = [
        f"empack pack file  {pytest_files[0]}  '/tests'  testdata --export-name='global.Module'"
    ]
    ret = subprocess.run(cmd, shell=True)


def copy_from_prefix(prefix, work_dir):
    # copy wasm / js file to work dir
    js_file = os.path.join(prefix, "bin", "pytest_driver.js")
    shutil.copy(js_file, work_dir)
    wasm_file = os.path.join(prefix, "bin", "pytest_driver.wasm")
    shutil.copy(wasm_file, work_dir)


def patch(work_dir):
    js_file = os.path.join(work_dir, "pytest_driver.js")
    # Read in the file
    with open(js_file, "r") as file:
        filedata = file.read()

    # Replace the target string
    filedata = filedata.replace("push(audioPlugin)", "push(imagePlugin)")

    # Write the file out again
    with open(js_file, "w") as file:
        file.write(filedata)


def run_node_tests(work_dir):
    # Write the file out again
    with open(os.path.join(work_dir, "test.js"), "w") as file:
        file.write(NODE_TEST_FILE_STR)

    os.chdir(work_dir)
    cmd = [f"node   --trace-uncaught test.js"]
    ret = subprocess.run(cmd, shell=True)
    if ret.returncode != 0:
        raise RuntimeError("Tests Failed")


@contextmanager
def test_dir_context(pkg_name, debug, debug_dir):
    if debug:
        try:
            os.stat(debug_dir)
        except:
            os.mkdir(debug_dir)
        yield debug_dir
    else:
        with tempfile.TemporaryDirectory() as temp_dir:
            yield temp_dir


def test_package(recipe, debug=False, debug_dir=None):

    old_cwd = os.getcwd()

    recipe_dir, _ = os.path.split(recipe["recipe_file"])
    assert os.path.isdir(recipe_dir), f"recipe_dir: {recipe_dir} does not exist"
    pytest_files = get_pytest_files(recipe_dir, recipe)
    has_tests = len(pytest_files) > 0

    if has_tests:
        pkg_name = recipe["package"]["name"]
        with test_dir_context(
            pkg_name=pkg_name, debug=debug, debug_dir=debug_dir
        ) as test_dir:
            prefix = os.path.join(test_dir, "prefix")
            work_dir = os.path.join(test_dir, "work")
            os.mkdir(work_dir)
            os.chdir(work_dir)
            create_test_env(pkg_name=pkg_name, prefix=prefix)
            print("PACK STUFF")
            pack(prefix=prefix, pytest_files=pytest_files)
            print("COPY FROM PREFIX")
            copy_from_prefix(prefix=prefix, work_dir=work_dir)
            patch(work_dir=work_dir)
            run_node_tests(work_dir=work_dir)

    os.chdir(old_cwd)


# if __name__ == "__main__":

#     import argparse

#     parser = argparse.ArgumentParser()
#     parser.add_argument("pkg_spec")
#     parser.add_argument("--debug", action=argparse.BooleanOptionalAction)
#     parser.add_argument("--debug-dir", type=str)
#     args = parser.parse_args()
#     print(args.debug_dir)
#     if args.debug and args.debug_dir is None:
#         raise RuntimeError("missing arg: --debug-dir")
#     test_package(args.pkg_spec, debug=args.debug, debug_dir=args.debug_dir)

#     import sys

#     sys.exit(0)
