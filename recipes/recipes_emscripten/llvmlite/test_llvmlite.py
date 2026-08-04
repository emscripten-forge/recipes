import pytest


def test_import_llvmlite():
    import llvmlite
    assert llvmlite.__version__


def test_import_ir():
    import llvmlite.ir as ir
    # Build a trivial LLVM IR module to exercise the pure-Python IR layer.
    m = ir.Module(name="test")
    fntype = ir.FunctionType(ir.IntType(32), [ir.IntType(32), ir.IntType(32)])
    fn = ir.Function(m, fntype, name="add")
    block = fn.append_basic_block(name="entry")
    builder = ir.IRBuilder(block)
    a, b = fn.args
    result = builder.add(a, b, name="res")
    builder.ret(result)
    assert "define" in str(m)


def test_import_binding():
    import llvmlite.binding as llvm
    # If we reach here libllvmlite.so was successfully dlopen()'d.
    assert hasattr(llvm, "WasmExecutionEngine")


def test_wasm_execution_engine_importable():
    from llvmlite.binding.wasmengine import (
        WasmExecutionEngine,
        EmscriptenBackend,
        WasmRuntimeError,
        WasmToolNotFoundError,
    )
    assert WasmExecutionEngine is not None
    assert EmscriptenBackend is not None


def test_graphviz_renders_in_process():
    from llvmlite.binding.analysis import view_dot_graph

    rendered = view_dot_graph("digraph G { A -> B; }")
    svg = getattr(rendered, "data", rendered)
    assert "<svg" in svg
    assert "A" in svg
    assert "B" in svg
