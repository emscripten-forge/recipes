import sys
import os
from pathlib import Path
import json
import re
import subprocess


def run_llvm_tool(tool, path, *options):
    cmd = [tool, *options, str(path)]

    try:
        output = subprocess.check_output(cmd, stderr=subprocess.STDOUT)
        return output.decode("utf-8")
    except subprocess.CalledProcessError as e:
        print(f"Error running {tool} on {path}:")
        print(e.output.decode("utf-8"))
        sys.exit(1)


def run_llvm_readobj(path, *options):
    return run_llvm_tool("llvm-readobj", path, *options)


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


# The two magic numbers of LLVM bitcode: plain, and the wrapper format.
BITCODE_MAGICS = (b"BC\xc0\xde", b"\xde\xc0\x17\x0b")


def members(path):
    """The (name, bytes) of the objects in `path`: the members of a static
    library (an `ar` archive), or the file itself for a single object."""
    data = Path(path).read_bytes()
    if data[:8] != b"!<arch>\n":
        return [(Path(path).name, data)]
    result = []
    pos = 8
    while pos + 60 <= len(data):
        header = data[pos:pos + 60]
        size = int(header[48:58])
        name = header[:16].decode("latin-1").strip()
        body = data[pos + 60:pos + 60 + size]
        # (members start at even offsets)
        pos += 60 + size + (size & 1)
        # the symbol table and the long-name table are no objects
        if name in ("/", "//", "/SYM64/"):
            continue
        result.append((name, body))
    return result


def bitcode_members(path):
    """The members of `path` that are LLVM bitcode (link-time optimization:
    compiled with -flto they contain LLVM IR, no WebAssembly yet)."""
    return [(name, body) for name, body in members(path) if body[:4] in BITCODE_MAGICS]


def check_arch_of_bitcode(path, slim_arch):
    """LLVM bitcode carries its target triple, e.g.
    "wasm32-unknown-emscripten", in its string table as plain text. Every
    bitcode member must name the expected architecture and not the other
    one: the same mistake check_arch_of_lib catches for WebAssembly objects
    (built for the wrong target)."""
    other = {"wasm32": "wasm64", "wasm64": "wasm32"}[slim_arch]
    for name, body in bitcode_members(path):
        if f"{other}-".encode() in body or f"{slim_arch}-".encode() not in body:
            print(f"Error: {path}: the LLVM bitcode of {name} is not built for {slim_arch}")
            sys.exit(1)


def check_arch_of_lib(path, arch):
    output = run_llvm_readobj(path, "-h")
    # arch is expected to be e.g. "emscripten-wasm32" or "emscripten-wasm64"
    slim_arch = arch.split("-")[-1]

    # Static libraries / objects compiled with -flto (link-time optimization)
    # contain LLVM bitcode instead of WebAssembly. That is fine (the linker
    # compiles it), as long as it is bitcode for the right target.
    has_bitcode = not str(path).endswith(".so") and bool(bitcode_members(path))
    if has_bitcode:
        check_arch_of_bitcode(path, slim_arch)
        # only bitcode: nothing left for the checks of WebAssembly below
        if "Format: WASM" not in output:
            return

    if "Format: WASM" not in output:
        print(f"Error: {path} is neither a WebAssembly library nor LLVM bitcode")
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


# ---------------------------------------------------------------------------
# Thread support (-pthread)
#
# What the check is for: a package must not force its users to link with
# -pthread. That is the case when code was COMPILED with thread support:
# it then uses WebAssembly atomics and needs shared memory, and the linker
# refuses to mix it with code built without. Calling pthread_* functions
# alone is fine: emscripten's libc has them in non-threaded builds too
# (CPython calls pthread_mutex_lock & co. but is built without -pthread).
#
# What marks code compiled with -pthread (checked with emscripten 6.0.8):
#   WebAssembly objects (.o, members of .a)  "+atomics" in the custom
#                                             section "target_features"
#   LLVM bitcode (-flto)                      "+atomics" in the
#                                             "target-features" attribute
#                                             of its functions (llvm-dis)
#   linked modules (.so)                      no target_features section
#                                             any more; their memory
#                                             (imported or own) is shared
# ---------------------------------------------------------------------------
def read_uleb(data, pos):
    """an unsigned LEB128 integer at `pos` of `data`: (value, next position)"""
    value = shift = 0
    while True:
        byte = data[pos]
        pos += 1
        value |= (byte & 0x7F) << shift
        shift += 7
        if byte < 0x80:
            return value, pos


def wasm_sections(data):
    """(id, payload) of each section of a WebAssembly module / object"""
    pos = 8  # magic number + version
    while pos < len(data):
        section_id = data[pos]
        size, pos = read_uleb(data, pos + 1)
        yield section_id, data[pos:pos + size]
        pos += size


def wasm_target_features(data):
    """the entries of the "target_features" custom section of a WebAssembly
    object, e.g. {"+atomics", "+bulk-memory"} (empty if there is none)"""
    features = set()
    for section_id, payload in wasm_sections(data):
        if section_id != 0:
            continue
        length, pos = read_uleb(payload, 0)
        if payload[pos:pos + length] != b"target_features":
            continue
        count, pos = read_uleb(payload, pos + length)
        for _ in range(count):
            prefix = chr(payload[pos])
            length, pos = read_uleb(payload, pos + 1)
            features.add(prefix + payload[pos:pos + length].decode())
            pos += length
    return features


def wasm_has_shared_memory(data):
    """does a linked WebAssembly module import or define shared memory?
    (bit 0x02 of the limits flags of a memory)"""
    for section_id, payload in wasm_sections(data):
        if section_id == 2:  # imports
            count, pos = read_uleb(payload, 0)
            for _ in range(count):
                for _ in range(2):  # module and field name
                    length, pos = read_uleb(payload, pos)
                    pos += length
                kind = payload[pos]
                pos += 1
                if kind == 0:  # function: type index
                    _, pos = read_uleb(payload, pos)
                elif kind in (1, 2):  # table (+ element type) / memory: limits
                    if kind == 1:
                        pos += 1
                    flags, pos = read_uleb(payload, pos)
                    if kind == 2 and flags & 0x02:
                        return True
                    _, pos = read_uleb(payload, pos)
                    if flags & 0x01:
                        _, pos = read_uleb(payload, pos)
                elif kind == 3:  # global: value type + mutability
                    pos += 2
                else:
                    # (tags, or something newer: memories come before, stop)
                    break
        elif section_id == 5:  # own memories
            count, pos = read_uleb(payload, 0)
            for _ in range(count):
                flags, pos = read_uleb(payload, pos)
                if flags & 0x02:
                    return True
                _, pos = read_uleb(payload, pos)
                if flags & 0x01:
                    _, pos = read_uleb(payload, pos)
    return False


def bitcode_uses_atomics(body):
    """is the LLVM bitcode `body` compiled with thread support? (its
    functions' target features, as llvm-dis shows them, contain +atomics)"""
    try:
        text = subprocess.run(
            ["llvm-dis", "-o", "-", "-"], input=body, capture_output=True, check=True
        ).stdout
    except subprocess.CalledProcessError as e:
        print("Error running llvm-dis:")
        print(e.stderr.decode("utf-8", "replace"))
        sys.exit(1)
    return re.search(rb'"target-features"="[^"]*\+atomics', text) is not None


def threaded_parts(path):
    """the names of the objects in `path` that were compiled with thread
    support (see above)"""
    linked = str(path).endswith(".so")
    result = []
    for name, body in members(path):
        if body[:4] == b"\0asm":
            if linked:
                threaded = wasm_has_shared_memory(body)
            else:
                threaded = "+atomics" in wasm_target_features(body)
        elif body[:4] in BITCODE_MAGICS:
            threaded = bitcode_uses_atomics(body)
        else:
            threaded = False
        if threaded:
            result.append(name)
    return result


def check_no_threads(path, allow_pthread):
    """Fail if `path` contains code compiled with thread support (-pthread),
    which would force every user to link with -pthread too; unless the
    package says it is meant to be threaded (--allow-pthread)."""
    if allow_pthread:
        return
    threaded = threaded_parts(path)
    if threaded:
        print(
            f"Error: {path} contains code compiled with thread support (-pthread: "
            "WebAssembly atomics / shared memory), which forces its users to link with "
            "-pthread too; --allow-pthread is not set"
        )
        for name in threaded[:20]:
            print(f"    {name}")
        if len(threaded) > 20:
            print(f"    ... and {len(threaded) - 20} more")
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
    check_no_threads(path, allow_pthread)

