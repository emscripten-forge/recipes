def test_mlir_cfg_renders_with_in_process_graphviz():
    import builtins
    import importlib.util
    from unittest.mock import patch

    from mlir.utils import show_cfg, show_dot

    # The Emscripten integration uses Graphviz's in-process SWIG binding,
    # without the subprocess-oriented Python graphviz wrapper.
    assert importlib.util.find_spec("graphviz") is None

    # On Emscripten this must use the local gv SWIG binding. Any attempt to
    # launch dot as a subprocess or fetch @hpcc-js/wasm cannot satisfy this
    # browser-worker test.
    with patch.object(builtins, "display", create=True) as display:
        result = show_dot(
            'digraph mlir_test { Tensor -> LLVM; }',
            title="MLIR lowering",
        )
    assert result is None
    rendered = display.call_args.args[0]
    svg = rendered.data
    assert "<svg" in svg
    assert "Tensor" in svg
    assert "LLVM" in svg
    assert "MLIR lowering" in rendered._repr_html_()

    with patch.object(builtins, "display", create=True) as display:
        result = show_cfg(
            """
            func.func @choose(%condition: i1) -> i32 {
              cf.cond_br %condition, ^left, ^right
            ^left:
              %one = arith.constant 1 : i32
              return %one : i32
            ^right:
              %zero = arith.constant 0 : i32
              return %zero : i32
            }
            """,
            show_ops=False,
        )
    assert result is None
    cfg_svg = display.call_args.args[0].data
    assert "<svg" in cfg_svg
    assert "left" in cfg_svg
    assert "right" in cfg_svg
