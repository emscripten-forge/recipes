


import sys
import os
from pathlib import Path
import json
import subprocess


def run_llvm_readobj(path):
    cmd = ["llvm-readobj", "-h", str(path)]
    try:
        output = subprocess.check_output(cmd, stderr=subprocess.STDOUT)
        return output.decode("utf-8")
    except subprocess.CalledProcessError as e:
        print(f"Error: {e.output.decode('utf-8')}")
        sys.exit(1)


def check_arch_of_static_lib(path, arch):
    output = run_llvm_readobj(path)
    # split arch string (emscripten-wasm32 or emscripten-wasm64) and take the last part (wasm32 or wasm64)
    slim_arch = arch.split("-")[-1]
    if f"Arch: {slim_arch}" not in output:
        print(f"Error: {path} is not built for architecture {slim_arch}")
        sys.exit(1)

def has_pthread_symbols(path):
    output = run_llvm_readobj(path)
    if "pthread" in output:
        return True
    return False

def check_static_lib(path, arch, allow_pthread):
    print(f"Checking static library: {path}")
    if not path.exists():
        print(f"Error: {path} does not exist")
        sys.exit(1)

    # check architecture of the static library
    check_arch_of_static_lib(path, arch)

    # check for pthread symbols in the static library
    if has_pthread_symbols(path) and not allow_pthread:
        print(f"Error: {path} contains pthread symbols but --allow-pthread is not set")
        sys.exit(1)

def impl(pkg_name, pkg_version, pkg_bld_str, arch, allow_pthread):

    prefix = Path(os.environ["PREFIX"])
    if not prefix.exists():
        print(f"Error: PREFIX {prefix} does not exist")
        sys.exit(1)



    conda_meta_dir = prefix / "conda-meta"
    fname = conda_meta_dir / f"{pkg_name}-{pkg_version}-{pkg_bld_str}.json"
    if not fname.exists():
        print(f"Error: {fname} does not exist")
        sys.exit(1)

    with open(fname) as f:
        pkg_meta = json.load(f)
        files = pkg_meta.get("files", [])

    # iterate over files and do smth for each static library file
    for f in files:
        if f.endswith(".a"):
            lib_path = prefix / f
            check_static_lib(lib_path, arch, allow_pthread)


def main():
    import argparse

    # first argument is the name of the package to test
    parser = argparse.ArgumentParser(description="Run generic tests for a package")


    parser.add_argument("--allow-pthread", action="store_true", help="Allow pthread symbols in the package")

    args = parser.parse_args()

    target_platform = os.environ.get("target_platform")
    assert target_platform is not None, "target_platform environment variable is not set"
    assert target_platform in ["emscripten-wasm32", "emscripten-wasm64"], f"target_platform must be one of ['emscripten-wasm32', 'emscripten-wasm64'], but got {target_platform}"   
    pkg_name = os.environ.get("PKG_NAME")
    pkg_version = os.environ.get("PKG_VERSION")
    pkg_bld_str = os.environ.get("PKG_BUILD_STRING")




    impl(pkg_name=pkg_name,pkg_version=pkg_version, pkg_bld_str=pkg_bld_str, arch=target_platform, allow_pthread=args.allow_pthread)


if __name__ == "__main__":
    main()