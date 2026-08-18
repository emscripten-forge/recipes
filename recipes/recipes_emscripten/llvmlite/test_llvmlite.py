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


def test_wasm_side_module_filename_is_debugger_friendly():
    from llvmlite.binding.wasmengine import _wasm_module_filename

    assert _wasm_module_filename(
        "ol_np_empty_like.<locals>.impl", 12
    ) == "0012-ol_np_empty_like._locals_.impl.wasm"
    assert _wasm_module_filename("", 3) == "0003-anonymous.wasm"


def test_wasm_execution_engine_object_cache_callbacks(monkeypatch):
    import llvmlite.binding.wasmengine as wasmengine

    class Module:
        name = "cached_module"

    class TargetMachine:
        target_data = None

        def __init__(self):
            self.emissions = 0

        def emit_object(self, module):
            self.emissions += 1
            return b"fresh-object"

    class Backend:
        def __init__(self):
            self.loaded = []

        def load_object(self, object_bytes, module_name):
            self.loaded.append((object_bytes, module_name))

    target_machine = TargetMachine()
    backend = Backend()
    monkeypatch.setattr(wasmengine, "_ON_EMSCRIPTEN", True)
    monkeypatch.setattr(
        wasmengine,
        "_detect_backend",
        lambda backend_name, wasm_ld_path: backend,
    )
    engine = wasmengine.WasmExecutionEngine(target_machine)
    notifications = []
    engine.set_object_cache(
        lambda module, buf: notifications.append((module, buf)),
        lambda module: b"cached-object",
    )

    module = Module()
    engine.add_module(module)

    assert target_machine.emissions == 0
    assert backend.loaded == [(b"cached-object", module.name)]
    assert notifications == []


def test_graphviz_renders_in_process():
    from llvmlite.binding.analysis import view_dot_graph

    rendered = view_dot_graph("digraph G { A -> B; }")
    svg = getattr(rendered, "data", rendered)
    assert "<svg" in svg
    assert "A" in svg
    assert "B" in svg
