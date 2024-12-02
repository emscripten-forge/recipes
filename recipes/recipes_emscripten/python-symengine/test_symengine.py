
def test_symengine():
    import symengine
    x = symengine.Symbol('x')
    assert x.diff(x) == 1
