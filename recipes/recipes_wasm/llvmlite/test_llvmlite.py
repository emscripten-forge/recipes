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


def test_wasm_execution_engine_runs_jitted_code():
    # Compile IR, load it as a side module and call it through ctypes. The
    # pointer/size_t argument catches wasm32 code being run on wasm64.
    import ctypes
    import sys

    import llvmlite.binding as llvm

    intp = "i64" if sys.maxsize > 2**32 else "i32"
    ir_text = f"""
    define i32 @add(i32 %a, i32 %b) {{
      %r = add i32 %a, %b
      ret i32 %r
    }}

    define double @sum(ptr %p, {intp} %n) {{
    entry:
      br label %loop
    loop:
      %i = phi {intp} [0, %entry], [%i1, %body]
      %acc = phi double [0.0, %entry], [%acc1, %body]
      %c = icmp ult {intp} %i, %n
      br i1 %c, label %body, label %done
    body:
      %gep = getelementptr double, ptr %p, {intp} %i
      %v = load double, ptr %gep
      %acc1 = fadd double %acc, %v
      %i1 = add {intp} %i, 1
      br label %loop
    done:
      ret double %acc
    }}
    """

    engine = llvm.create_wasm_engine()
    mod = llvm.parse_assembly(ir_text)
    mod.name = "jit_exec_test"
    mod.data_layout = str(engine.target_data)
    engine.add_module(mod)

    add = ctypes.CFUNCTYPE(ctypes.c_int32, ctypes.c_int32, ctypes.c_int32)(
        engine.get_function_address("add")
    )
    assert add(40, 2) == 42

    total = ctypes.CFUNCTYPE(
        ctypes.c_double, ctypes.POINTER(ctypes.c_double), ctypes.c_size_t
    )(engine.get_function_address("sum"))
    values = (ctypes.c_double * 4)(1.0, 2.0, 3.0, 4.5)
    assert total(values, 4) == 10.5


def test_new_pass_manager_with_numba_passes():
    # Numba adds these passes to its pipelines. A wrong ctypes signature
    # (e.g. the jump-threading threshold) traps on wasm64.
    import llvmlite.binding as llvm

    engine = llvm.create_wasm_engine()
    mod = llvm.parse_assembly(
        "define i32 @f(i32 %a) {\n  %r = add i32 %a, 1\n  ret i32 %r\n}\n"
    )
    mod.data_layout = str(engine.target_data)
    pto = llvm.create_pipeline_tuning_options(speed_level=3)
    pb = llvm.create_pass_builder(engine._target_machine, pto)

    mpm = pb.getModulePassManager()
    mpm.add_loop_rotate_pass()
    mpm.add_instruction_combine_pass()
    mpm.add_jump_threading_pass()
    mpm.add_refprune_pass()
    mpm.run(mod, pb)

    fpm = pb.getFunctionPassManager()
    fpm.add_jump_threading_pass()
    fpm.add_refprune_pass()
    for fn in mod.functions:
        fpm.run(fn, pb)


def test_graphviz_renders_in_process():
    from llvmlite.binding.analysis import view_dot_graph

    rendered = view_dot_graph("digraph G { A -> B; }")
    svg = getattr(rendered, "data", rendered)
    assert "<svg" in svg
    assert "A" in svg
    assert "B" in svg
