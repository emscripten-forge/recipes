import gv


def test_graphviz_python_binding():
    graph = gv.digraph("G")
    a = gv.node(graph, "A")
    b = gv.node(graph, "B")
    c = gv.node(graph, "C")

    assert a is not None
    assert b is not None
    assert c is not None

    assert gv.edge(a, b) is not None
    assert gv.edge(b, c) is not None
    assert gv.edge(a, c) is not None

    gv.setv(graph, "label", "Test Graph")
    gv.layout(graph, "dot")
    result = gv.renderdata(graph, "dot")

    assert result
    assert "digraph" in result
    assert "A -> B" in result
