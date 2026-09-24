import ctypes
import sysconfig
from textwrap import dedent

import numpy as np

from mlir.ir import Context, Module
from mlir.passmanager import PassManager
from mlir.runtime.np_to_memref import get_ranked_memref_descriptor
from mlir.wasm_execution_engine import (
    WasmExecutionEngine,
    target_index_bitwidth,
    translate_to_llvmir,
)


def _lower_to_llvm(module):
    index_bits = target_index_bitwidth()
    pipeline = (
        "builtin.module("
        "finalize-memref-to-llvm{index-bitwidth=%d},"
        "convert-func-to-llvm{index-bitwidth=%d},"
        "convert-arith-to-llvm{index-bitwidth=%d},"
        "convert-cf-to-llvm{index-bitwidth=%d},"
        "reconcile-unrealized-casts)"
    ) % ((index_bits,) * 4)
    PassManager.parse(pipeline).run(module.operation)
    return module


def _scale_module(symbol, factor):
    return Module.parse(
        dedent(
            f"""
            module {{
              func.func @{symbol}(%arg0: memref<1xf32>)
                  attributes {{llvm.emit_c_interface}} {{
                %c0 = arith.constant 0 : index
                %value = memref.load %arg0[%c0] : memref<1xf32>
                %factor = arith.constant {factor:.1f} : f32
                %scaled = arith.mulf %value, %factor : f32
                memref.store %scaled, %arg0[%c0] : memref<1xf32>
                return
              }}
            }}
            """
        )
    )


def test_target_configuration_is_consistent():
    pointer_bits = ctypes.sizeof(ctypes.c_void_p) * 8
    assert pointer_bits in (32, 64)
    assert target_index_bitwidth() == pointer_bits

    extension_suffix = sysconfig.get_config_var("EXT_SUFFIX")
    assert extension_suffix.endswith("-emscripten.so")
    assert f"wasm{pointer_bits}" in extension_suffix


def test_import_parse_and_translate():
    with Context():
        module = Module.parse(
            """
            module {
              llvm.func @identity(%arg0: i32) -> i32 {
                llvm.return %arg0 : i32
              }
            }
            """
        )
        llvm_ir = translate_to_llvmir(module)
        assert "define i32 @identity" in llvm_ir


def test_memref_lowering_and_translation():
    with Context():
        module = _lower_to_llvm(_scale_module("scale_for_translation", 2.0))
        llvm_ir = translate_to_llvmir(module)
        assert "_mlir_ciface_scale_for_translation" in llvm_ir


def test_numpy_memref_execution_and_repeated_linking():
    with Context():
        first = _lower_to_llvm(_scale_module("scale_by_two", 2.0))
        first_array = np.array([3.0], dtype=np.float32)
        first_descriptor = get_ranked_memref_descriptor(first_array)
        WasmExecutionEngine(first, module_name="scale_two").invoke(
            "scale_by_two", ctypes.pointer(first_descriptor)
        )
        assert first_array.tolist() == [6.0]

        # A second compilation in the same browser process exercises lld's
        # reusable cleanup path as well as the process-global symbol table.
        second = _lower_to_llvm(_scale_module("scale_by_three", 3.0))
        second_array = np.array([4.0], dtype=np.float32)
        second_descriptor = get_ranked_memref_descriptor(second_array)
        WasmExecutionEngine(second, module_name="scale_three").invoke(
            "scale_by_three", ctypes.pointer(second_descriptor)
        )
        assert second_array.tolist() == [12.0]
