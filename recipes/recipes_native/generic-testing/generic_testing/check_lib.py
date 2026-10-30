import sys
import os
from pathlib import Path
import json
import re
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


def is_memoryless_function_module(path):
    with open(path, "rb") as binary:
        if binary.read(8) != b"\0asm\x01\0\0\0":
            return False
        sections = run_llvm_readobj(path, "--sections")
        types = set(re.findall(r"^\s*Type: (\w+) ", sections, re.MULTILINE))
        if (not re.search(r"^\s*Name: dylink\.0$", sections, re.MULTILINE)
                or not types <= {"CUSTOM", "TYPE", "IMPORT", "FUNCTION", "EXPORT", "CODE"}):
            return False
        if "IMPORT" not in types:
            return True
        match = re.search(r"Type: IMPORT \(0x2\)\s+Size: (\d+)\s+Offset: (\d+)", sections)
        if match is None:
            return False
        size, offset = map(int, match.groups())
        binary.seek(offset)
        imports = iter(binary.read(size))

    # LLVM supplies section boundaries; decode only the import descriptions.
    def read_uleb():
        value = 0
        for shift in range(0, 35, 7):
            byte = next(imports)
            value |= (byte & 0x7f) << shift
            if byte < 0x80:
                return value
        raise ValueError("Invalid Wasm integer")

    try:
        for _ in range(read_uleb()):
            for _ in range(2):  # Skip the module and field names.
                for _ in range(read_uleb()):
                    next(imports)
            if next(imports) != 0:  # Only function imports are width-neutral.
                return False
            read_uleb()  # Function type index.
        return next(imports, None) is None
    except (StopIteration, ValueError):
        return False


def check_arch_of_lib(path, arch):
    output = run_llvm_readobj(path, "-h")
    # arch is expected to be e.g. "emscripten-wasm32" or "emscripten-wasm64"
    slim_arch = arch.split("-")[-1]

    if "Format: WASM" not in output:
        print(f"Error: {path} is not a WebAssembly library")
        sys.exit(1)

    # LLVM defaults to wasm32 for function-only wrappers with no memory width.
    if (slim_arch == "wasm64" and "Arch: wasm32" in output
            and is_memoryless_function_module(path)):
        return

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

    # print(f"output for {path}")
    # print(output)

    lines = output.splitlines()
    context = 10

    pthread_matches = [
        i for i, line in enumerate(lines)
        if re.search(r"^\s*Name:\s+_*pthread_", line)
    ]

    if pthread_matches:
        print(
            f"Error: {path} contains pthread symbols "
            "but --allow-pthread is not set"
        )

        print("\npthread-related symbols with context:")

        for index in pthread_matches:
            start = max(0, index - context)
            end = min(len(lines), index + context + 1)

            print("\n" + "=" * 80)
            print(f"Match at line {index + 1}")

            for i in range(start, end):
                prefix = ">>> " if i == index else "    "
                print(f"{prefix}{i + 1:5}: {lines[i]}")

        sys.exit(1)

def check_lib(path, arch, allow_pthread):
    print(f"Checking library: {path}")

    is_shared = str(path).endswith(".so")

    # in case of a ** a shared lib** we need to
    # check that its not a symlink, 
    if is_shared and path.is_symlink():
        print(f"Error: shared lib {path} is a symlink, which is not allowed for shared libraries")
        sys.exit(1)

    if not path.exists():
        print(f"Error: {path} does not exist")
        sys.exit(1)

    check_arch_of_lib(path, arch)
    check_no_pthread_symbols(path, allow_pthread)

