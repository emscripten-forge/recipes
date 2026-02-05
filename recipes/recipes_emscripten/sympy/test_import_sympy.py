
def test_import_sympy():
    import sympy
    from sympy import Symbol, cos
    x = Symbol('x')
    e = 1/cos(x)
    print(e.series(x, 0, 10))