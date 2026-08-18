def test_mlir_cfg_renders_with_in_process_graphviz():
    from unittest.mock import patch

    from graphviz import Digraph
    from mlir.utils import show_dot

    graph = Digraph("mlir_test")
    graph.edge("Tensor", "LLVM")

    # On Emscripten this must use the local gv SWIG binding. Any attempt to
    # launch dot as a subprocess or fetch @hpcc-js/wasm cannot satisfy this
    # browser-worker test.
    with patch("IPython.display.display") as display:
        result = show_dot(graph, title="MLIR lowering")

    # show_dot is display-only. Returning the SVG would make IPython render it
    # a second time whenever show_dot is the cell's final expression.
    assert result is None
    assert display.call_count == 2

    rendered = display.call_args_list[-1].args[0]
    assert "<svg" in rendered.data
    assert "Tensor" in rendered.data
    assert "LLVM" in rendered.data
