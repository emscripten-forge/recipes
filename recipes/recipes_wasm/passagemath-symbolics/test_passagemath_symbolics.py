import pytest


def test_import_passagemath_symbolics():
    import passagemath_symbolics


def test_symbolic_calculus():
    from sage.all__sagemath_symbolics import var, sin, cos, diff, expand

    x, y = var("x y")
    assert diff(sin(x) ** 2, x) == 2 * sin(x) * cos(x)
    assert expand((x + y) ** 2) == x**2 + 2 * x * y + y**2
