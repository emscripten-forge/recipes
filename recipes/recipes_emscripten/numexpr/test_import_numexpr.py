
def test_import_numexpr():
    import numexpr
    import numexpr.interpreter
    import numpy as np
    a = np.arange(1e6)
    b = np.arange(1e6)
    result = numexpr.evaluate("3*a + 4*b")
    assert result.shape == a.shape
