"""Tests of the cadabra2 Python API (no Cadabra notation involved)."""

import pytest


@pytest.fixture
def cdb():
    import cadabra2

    return cadabra2


def test_import(cdb):
    assert "wasm32-emscripten" in cdb.__file__
    for name in [
        "Ex",
        "ExNode",
        "Kernel",
        "create_scope",
        "canonicalise",
        "collect_terms",
        "distribute",
        "substitute",
        "sort_product",
        "cdb2python_string",
        "compile_package__",
    ]:
        assert hasattr(cdb, name), name


def test_kernel(cdb):
    kernel = cdb.create_scope()
    assert kernel.version == "2.5.14"
    assert isinstance(kernel.build, str)
    # Module-level kernel created on import.
    assert isinstance(cdb.__cdbkernel__, cdb.Kernel)


def test_ex_roundtrip(cdb):
    __cdbkernel__ = cdb.create_scope()
    ex = cdb.Ex(r"A_{m n} B^{m n}")
    assert ex.input_form() == "A_{m n} B^{m n}"
    assert "A_{m n}" in ex._latex_()
    assert str(ex).startswith("A")


def test_ex_arithmetic(cdb):
    __cdbkernel__ = cdb.create_scope()
    a = cdb.Ex(r"x + y")
    b = cdb.Ex(r"x + y")
    diff = a - b
    cdb.collect_terms(diff)
    assert diff == 0
    assert a == b


def test_symmetric_canonicalise(cdb):
    __cdbkernel__ = cdb.create_scope()
    cdb.Symmetric(cdb.Ex(r"A_{m n}"))
    ex = cdb.Ex(r"A_{m n} + A_{n m}")
    cdb.canonicalise(ex)
    cdb.collect_terms(ex)
    assert ex == cdb.Ex(r"2 A_{m n}")


def test_antisymmetric_vanishes(cdb):
    __cdbkernel__ = cdb.create_scope()
    cdb.AntiSymmetric(cdb.Ex(r"F_{m n}"))
    cdb.Symmetric(cdb.Ex(r"S^{m n}"))
    ex = cdb.Ex(r"F_{m n} S^{m n}")
    cdb.canonicalise(ex)
    assert ex == 0


def test_distribute_and_collect(cdb):
    __cdbkernel__ = cdb.create_scope()
    ex = cdb.Ex(r"(a + b) (a - b)")
    cdb.distribute(ex)
    cdb.sort_product(ex)
    cdb.collect_terms(ex)
    # a*b - b*a cancel once products are sorted
    assert ex == cdb.Ex(r"a a - b b")


def test_substitute(cdb):
    __cdbkernel__ = cdb.create_scope()
    ex = cdb.Ex(r"A_{m} B_{m}")
    cdb.substitute(ex, cdb.Ex(r"A_{m} -> C_{m n} D_{n}"))
    assert ex == cdb.Ex(r"C_{m n} D_{n} B_{m}")


def test_eliminate_kronecker(cdb):
    __cdbkernel__ = cdb.create_scope()
    cdb.KroneckerDelta(cdb.Ex(r"\delta_{m n}"))
    ex = cdb.Ex(r"\delta_{m n} A_{n}")
    cdb.eliminate_kronecker(ex)
    assert ex == cdb.Ex(r"A_{m}")


def test_anticommuting_sort(cdb):
    __cdbkernel__ = cdb.create_scope()
    cdb.AntiCommuting(cdb.Ex(r"{A, B}"))
    ex = cdb.Ex(r"B A")
    cdb.sort_product(ex)
    assert ex == cdb.Ex(r"-A B")


def test_tree_iteration(cdb):
    __cdbkernel__ = cdb.create_scope()
    ex = cdb.Ex(r"A_{m} + B_{m} + C_{m}")
    names = [node.name for node in ex.top().terms()]
    assert names == ["A", "B", "C"]


def test_exception_is_raised(cdb):
    # C++ exceptions (cadabra::ConsistencyException) must propagate as
    # Python exceptions; this relies on wasm exception handling.
    __cdbkernel__ = cdb.create_scope()
    with pytest.raises(RuntimeError, match="Free indices"):
        cdb.Ex(r"A_{m} + B_{n}")
    # ... and the module must still be usable afterwards.
    ex = cdb.Ex(r"A_{m} + A_{m}")
    cdb.collect_terms(ex)
    assert ex == cdb.Ex(r"2 A_{m}")
