def test_mlir_cfg_renders_with_in_process_graphviz():
    from graphviz import Digraph
    from mlir.utils import show_dot

    graph = Digraph("mlir_test")
    graph.edge("Tensor", "LLVM")

    # On Emscripten this must use the local gv SWIG binding. Any attempt to
    # launch dot as a subprocess or fetch @hpcc-js/wasm cannot satisfy this
    # browser-worker test.
    rendered = show_dot(graph, title="MLIR lowering")

    assert "<svg" in rendered.data
    assert "Tensor" in rendered.data
    assert "LLVM" in rendered.data
