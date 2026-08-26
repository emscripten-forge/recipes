import sys
import os
from pathlib import Path
import json
import subprocess


def run_llvm_readobj(path, *options):
    cmd = ["llvm-readobj", *options, str(path)]

    try:
        output = subprocess.check_output(cmd, stderr=subprocess.STDOUT)
        return output.decode("utf-8")
    except subprocess.CalledProcessError as e:
        print(f"Error running llvm-readobj on {path}:")
        print(e.output.decode("utf-8"))
        sys.exit(1)


def check_arch_of_lib(path, arch):
    output = run_llvm_readobj(path, "-h")
    # arch is expected to be e.g. "emscripten-wasm32" or "emscripten-wasm64"
    slim_arch = arch.split("-")[-1]

    if "Format: WASM" not in output:
        print(f"Error: {path} is not a WebAssembly library")
        sys.exit(1)

    if f"Arch: {slim_arch}" not in output:
        print(f"Error: {path} is not built for architecture {slim_arch}")
        sys.exit(1)

    expected_address_size = {
        "wasm32": "32bit",
        "wasm64": "64bit",
    }[slim_arch]

    if f"AddressSize: {expected_address_size}" not in output:
        print(
            f"Error: {path} has unexpected address size; "
            f"expected {expected_address_size}"
        )
        sys.exit(1)


def check_no_pthread_symbols(path, allow_pthread):
    if allow_pthread:
        return

    output = run_llvm_readobj(path, "--symbols")

    pthread_lines = [
        line for line in output.splitlines()
        if "pthread" in line.lower()
    ]

    if pthread_lines:
        print(
            f"Error: {path} contains pthread symbols "
            "but --allow-pthread is not set"
        )

        print("pthread-related symbols:")
        for line in pthread_lines:
            print(f"  {line.strip()}")

        sys.exit(1)


def check_lib(path, arch, allow_pthread):
    print(f"Checking library: {path}")

    # check that its not a symlink, because we want to check the actual file
    if path.is_symlink():
        print(f"Error: {path} is a symlink, which is not allowed for libraries")
        sys.exit(1)

    if not path.exists():
        print(f"Error: {path} does not exist")
        sys.exit(1)

    check_arch_of_lib(path, arch)
    check_no_pthread_symbols(path, allow_pthread)

