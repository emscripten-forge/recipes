import sys
import os
from pathlib import Path
import json
import subprocess

from .check_lib import check_lib,run_llvm_readobj



def is_wasmish(file_path):
    # use llvm-readobj to check if the file is a shared library
    output = run_llvm_readobj(file_path, "-h")
    return "Format: WASM" in output

def per_file_test(file_path, arch, allow_pthread):

    # do somewhat elaborate checks for libraries and 
    # shared libraries
    if str(file_path).endswith((".a", ".so")):
        check_lib(file_path, arch, allow_pthread)

    # we disallow versioned shared libraries, e.g. libfoo.so.1.2.3, 
    # because they are problematic.
    # to avoid false positives, we will use llvm-readobj to check if a file
    # might be a shared library, ie is wasm-ish
    if ".so." in str(file_path) and is_wasmish(file_path):
        print(f"""Error: {file_path} looks like it is a versioned shared library, which is not allowed""")
        sys.exit(1)
            

def load_pkg_meta(prefix, pkg_name, pkg_version, pkg_bld_str):
    conda_meta_dir = prefix / "conda-meta"
    fname = conda_meta_dir / f"{pkg_name}-{pkg_version}-{pkg_bld_str}.json"

    if not fname.exists():
        print(f"Error: {fname} does not exist")
        sys.exit(1)

    with open(fname) as f:
        pkg_meta = json.load(f)

    return pkg_meta



# this is the entry point for the generic testing package
def generic_testing(pkg_name, pkg_version, pkg_bld_str, arch, allow_pthread):

    prefix = Path(os.environ["PREFIX"])
    if not prefix.exists():
        print(f"Error: PREFIX {prefix} does not exist")
        sys.exit(1)

    pkg_meta = load_pkg_meta(prefix, pkg_name, pkg_version, pkg_bld_str)

    files = pkg_meta.get("files", [])


    # run per-file tests
    for f in files:
        path = prefix / f
        per_file_test(path, arch, allow_pthread)