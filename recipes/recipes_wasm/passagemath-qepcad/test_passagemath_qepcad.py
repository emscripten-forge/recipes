import pytest


def test_import_passagemath_qepcad():
    import passagemath_qepcad


def test_qepcad_formulas():
    # the formula builder is pure Python (the qepcad program itself is not
    # run here); qformula strings instead of symbolic expressions
    from sage.interfaces.qepcad import qepcad_formula as qf
    from sage.interfaces.qepcad import qformula

    x = qformula("x > 0", frozenset(["x"]))
    y = qformula("y < 1", frozenset(["y"]))

    assert repr(qf.and_(x, y)) == r"[x > 0 /\ y < 1]"
    assert repr(qf.or_(x, y)) == r"[x > 0 \/ y < 1]"
    assert repr(qf.not_(x)) == "[~x > 0]"
    assert repr(qf.implies(x, y)) == "[x > 0 ==> y < 1]"
    assert repr(qf.iff(x, y)) == "[x > 0 <==> y < 1]"

    both = qf.and_(x, y)
    assert both.vars == frozenset(["x", "y"])
    quantified = qf.exists("x", both)
    assert repr(quantified) == r"(E x)[x > 0 /\ y < 1]"
    assert quantified.qvars == ["x"]
    assert repr(qf.forall("y", y)) == "(A y)[y < 1]"
