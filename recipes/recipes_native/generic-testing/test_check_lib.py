import contextlib
import io
from pathlib import Path
import tempfile
import unittest
from unittest import mock

from generic_testing.check_lib import (
    check_arch_of_lib,
    check_no_pthread_symbols,
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


class PthreadSymbolTests(unittest.TestCase):
    def test_unrelated_symbol_names(self):
        output = "\n".join([
            "File: /tmp/pthread/example.so",
            "Name: FLAGS_pthreadpool_size",
            "Name: _ZN4llvm15JumpThreadingPass3runEv",
            "Name: pthreadpool_parallelize_1d",
        ])
        with mock.patch("generic_testing.check_lib.run_llvm_readobj", return_value=output):
            check_no_pthread_symbols(Path("example.so"), False)

    def test_actual_pthread_symbols_are_rejected(self):
        for name in ("pthread_create", "_pthread_join", "__pthread_mutex_lock",
                     "pthread_create.llvm.123"):
            with self.subTest(name=name), contextlib.redirect_stdout(io.StringIO()):
                with mock.patch("generic_testing.check_lib.run_llvm_readobj",
                                return_value=f"  Name: {name}\n"):
                    with self.assertRaises(SystemExit):
                        check_no_pthread_symbols(Path("example.so"), False)


if __name__ == "__main__":
    unittest.main()
