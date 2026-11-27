import contextlib
import io
from pathlib import Path
import tempfile
import unittest
from unittest import mock

from generic_testing.check_lib import (
    check_arch_of_lib,
    check_no_threads,
    is_memoryless_function_module,
    run_llvm_readobj,
)


# Emscripten 6.0.8 shared wrapper: void *entry(void) { return wrapped(); }
FACADE = bytes.fromhex(
    "0061736d01000000000f0864796c696e6b2e300104000000000108026000017f"
    "600000020f0103656e76077772617070656400000303020100071d02115f5f"
    "7761736d5f63616c6c5f63746f7273000105656e74727900020a090202000b"
    "040010000b"
)
HEADER = b"\0asm\x01\0\0\0"


class MemorylessTests(unittest.TestCase):
    def setUp(self):
        directory = tempfile.TemporaryDirectory()
        self.addCleanup(directory.cleanup)
        self.path = Path(directory.name) / "example.so"

    def test_forwarders(self):
        for result_type in (b"\x7f", b"\x7e"):
            self.path.write_bytes(FACADE.replace(
                b"\x60\x00\x01\x7f", b"\x60\x00\x01" + result_type))
            for arch in ("emscripten-wasm32", "emscripten-wasm64"):
                with self.subTest(result_type=result_type, arch=arch):
                    check_arch_of_lib(self.path, arch)

    def test_memory_width_is_still_checked(self):
        for flags, arch, other in ((0, "wasm32", "wasm64"),
                                   (4, "wasm64", "wasm32")):
            imported = b"\x01\x03env\x06memory\x02" + bytes((flags, 1))
            for memory in (bytes((5, 3, 1, flags, 1)),
                           bytes((2, len(imported))) + imported):
                self.path.write_bytes(FACADE[:25] + memory)
                check_arch_of_lib(self.path, "emscripten-" + arch)
                with contextlib.redirect_stdout(io.StringIO()):
                    with self.assertRaises(SystemExit):
                        check_arch_of_lib(self.path, "emscripten-" + other)

    def test_non_function_imports_are_not_exempt(self):
        for description in ("020001", "020401", "037e00", "01700001"):
            payload = b"\x01\x03env\x01x" + bytes.fromhex(description)
            self.path.write_bytes(
                FACADE[:25] + bytes((2, len(payload))) + payload)
            run_llvm_readobj(self.path, "-h")
            self.assertFalse(is_memoryless_function_module(self.path))

    def test_archives_objects_and_truncated_modules_are_not_exempt(self):
        for data in (b"!<arch>\n", HEADER, HEADER + b"\x02\x05\x01",
                     FACADE[:25] + b"\x02\x01\x01", FACADE[:-1]):
            self.path.write_bytes(data)
            with contextlib.redirect_stdout(io.StringIO()):
                try:
                    self.assertFalse(is_memoryless_function_module(self.path))
                except SystemExit as error:
                    self.assertEqual(error.code, 1)


def archive(*members):
    """an `ar` archive (static library) with the given (name, bytes) members"""
    data = b"!<arch>\n"
    for name, body in members:
        header = f"{name + '/':<16}{0:<12}{0:<6}{0:<6}{644:<8}{len(body):<10}`\n"
        data += header.encode() + body + (b"\n" if len(body) % 2 else b"")
    return data


def bitcode(triple):
    """a stand-in for an LLVM bitcode object: the magic number and, as in
    the string table of real bitcode, the target triple as plain text"""
    return b"BC\xc0\xde" + b"\0" * 12 + triple + b"\0" * 7


class BitcodeTests(unittest.TestCase):
    """Static libraries compiled with -flto contain LLVM bitcode: accepted,
    but only for the right architecture."""

    def setUp(self):
        directory = tempfile.TemporaryDirectory()
        self.addCleanup(directory.cleanup)
        self.path = Path(directory.name) / "libexample.a"
        # (llvm-readobj sees no WebAssembly in bitcode)
        patcher = mock.patch("generic_testing.check_lib.run_llvm_readobj",
                             return_value="File: libexample.a\n")
        patcher.start()
        self.addCleanup(patcher.stop)

    def check(self, data, arch):
        self.path.write_bytes(data)
        check_arch_of_lib(self.path, "emscripten-" + arch)

    def test_bitcode_of_the_right_arch(self):
        for arch in ("wasm32", "wasm64"):
            triple = f"{arch}-unknown-emscripten".encode()
            self.check(archive(("a.o", bitcode(triple)), ("b.o", bitcode(triple))), arch)

    def test_bitcode_of_the_wrong_arch_or_without_wasm_triple(self):
        for triple, arch in ((b"wasm64-unknown-emscripten", "wasm32"),
                             (b"wasm32-unknown-emscripten", "wasm64"),
                             (b"x86_64-apple-darwin", "wasm32")):
            with self.subTest(triple=triple, arch=arch), contextlib.redirect_stdout(io.StringIO()):
                with self.assertRaises(SystemExit):
                    self.check(archive(("a.o", bitcode(triple))), arch)

    def test_one_wrong_member_is_enough(self):
        good, bad = bitcode(b"wasm32-unknown-emscripten"), bitcode(b"wasm64-unknown-emscripten")
        with contextlib.redirect_stdout(io.StringIO()), self.assertRaises(SystemExit):
            self.check(archive(("a.o", good), ("b.o", bad)), "wasm32")

    def test_neither_wasm_nor_bitcode(self):
        with contextlib.redirect_stdout(io.StringIO()), self.assertRaises(SystemExit):
            self.check(archive(("a.o", b"\x7fELF" + b"\0" * 12)), "wasm32")


def section(section_id, payload):
    """a WebAssembly section"""
    return bytes((section_id, len(payload))) + payload


def custom_section(name, payload):
    return section(0, bytes((len(name),)) + name + payload)


def target_features(*features):
    """a "target_features" custom section, as in objects compiled by clang"""
    entries = b"".join(f[:1].encode() + bytes((len(f) - 1,)) + f[1:].encode() for f in features)
    return custom_section(b"target_features", bytes((len(features),)) + entries)


def wasm_object(*features, symbol=b"pthread_mutex_lock"):
    """a WebAssembly object: a name in a custom section (stands for its
    symbols, e.g. a call of pthread_mutex_lock) and its target features"""
    return HEADER + custom_section(b"names", symbol) + target_features(*features)


def linked_module(memory_flags):
    """a linked module (.so) importing env.memory with the given flags"""
    entry = b"\x03env\x06memory\x02" + bytes((memory_flags, 1))
    if memory_flags & 1:
        entry += b"\x02"
    return HEADER + section(2, b"\x01" + entry)


class ThreadTests(unittest.TestCase):
    """--allow-pthread is about code compiled with thread support (atomics /
    shared memory), not about calling pthread_* functions"""

    def setUp(self):
        directory = tempfile.TemporaryDirectory()
        self.addCleanup(directory.cleanup)
        self.directory = Path(directory.name)

    def check(self, name, data, allow_pthread=False):
        path = self.directory / name
        path.write_bytes(data)
        check_no_threads(path, allow_pthread)

    def rejected(self, name, data):
        with contextlib.redirect_stdout(io.StringIO()), self.assertRaises(SystemExit):
            self.check(name, data)

    def test_objects(self):
        default = ("+bulk-memory", "+mutable-globals", "+sign-ext")
        # calls pthread_* but compiled without -pthread: fine
        self.check("libplain.a", archive(("a.o", wasm_object(*default))))
        self.check("plain.o", wasm_object(*default))
        # compiled with -pthread: one such member is enough
        threaded = wasm_object("+atomics", *default)
        self.rejected("libthreads.a", archive(("a.o", wasm_object(*default)), ("b.o", threaded)))
        self.rejected("threads.o", threaded)
        self.check("libthreads.a", archive(("b.o", threaded)), allow_pthread=True)

    def test_linked_modules(self):
        for flags in (0x00, 0x01, 0x04):
            self.check("plain.so", linked_module(flags))
        for flags in (0x02, 0x03):
            self.rejected("threads.so", linked_module(flags))
        # (a module without imports, e.g. the forwarder above)
        self.check("facade.so", FACADE)

    def test_bitcode(self):
        member = bitcode(b"wasm32-unknown-emscripten")
        for disassembly, threaded in (
            (b'attributes #0 = { "target-features"="+bulk-memory,+sign-ext" }', False),
            (b'attributes #0 = { "target-features"="+atomics,+bulk-memory" }', True),
        ):
            result = mock.Mock(stdout=disassembly)
            with self.subTest(threaded=threaded), \
                 mock.patch("generic_testing.check_lib.subprocess.run", return_value=result):
                if threaded:
                    self.rejected("libexample.a", archive(("a.o", member)))
                else:
                    self.check("libexample.a", archive(("a.o", member)))


if __name__ == "__main__":
    unittest.main()
