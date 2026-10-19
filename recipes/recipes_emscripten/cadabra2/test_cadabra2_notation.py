"""Tests of Cadabra notation, translated to Python with the pre-processor
that the `cadabra2` REPL and notebooks use (`cadabra2.cdb2python_string`)."""

import textwrap

import pytest


def run_cdb(source, display=False):
    """Translate a block of Cadabra notation to Python and run it in a fresh
    namespace which has the usual `cadabra2_defaults` environment."""
    import cadabra2

    code = cadabra2.cdb2python_string(textwrap.dedent(source), display, "")
    namespace = {}
    exec("from cadabra2 import *\nfrom cadabra2_defaults import *\n", namespace)
    namespace["__cdbkernel__"] = cadabra2.create_scope()
    exec(compile(code, "<cadabra>", "exec"), namespace)
    return namespace


def test_translation():
    import cadabra2

    code = cadabra2.cdb2python_string("ex:= A_{m} B^{m};\n", False, "")
    assert "Ex(" in code
    assert "A_{m} B^{m}" in code

    code = cadabra2.cdb2python_string("{m,n}::Indices(position=free).\n", False, "")
    assert "Indices(" in code


def test_properties_and_canonicalise():
    ns = run_cdb(
        r"""
        {m,n,p,q}::Indices.
        A_{m n}::Symmetric.
        B_{m n}::AntiSymmetric.
        ex:= A_{m n} B_{m n};
        canonicalise(_)
        """
    )
    assert ns["ex"] == 0


def test_pull_in_and_collect():
    # Pattern used throughout the Cadabra test-suite.
    ns = run_cdb(
        r"""
        {X,G,Y,A,B}::SortOrder.
        {X,A}::AntiCommuting.
        obj6:= A B G X A X;
        sort_product(obj6)
        tst6:= X X G A A B + @(obj6);
        collect_terms(_)
        """
    )
    assert ns["tst6"] == 0


def test_riemann_bianchi():
    ns = run_cdb(
        r"""
        {a,b,c,d,e,f}::Indices.
        R_{a b c d}::RiemannTensor.
        ex:= R_{a b c d} + R_{a c d b} + R_{a d b c};
        young_project_tensor(ex, modulo_monoterm=True)
        """
    )
    assert ns["ex"] == 0


def test_derivative_product_rule():
    ns = run_cdb(
        r"""
        \partial{#}::PartialDerivative.
        {A, B}::Depends(\partial{#}).
        ex:= \partial_{m}{A B};
        product_rule(_);
        tst:= \partial_{m}{A} B + A \partial_{m}{B} - @(ex);
        collect_terms(_)
        """
    )
    assert ns["tst"] == 0


def test_gamma_matrix_algebra():
    ns = run_cdb(
        r"""
        {m,n,p,q}::Indices(vector).
        {m,n,p,q}::Integer(0..3).
        \Gamma{#}::GammaMatrix(metric=\delta).
        \delta{#}::KroneckerDelta.
        ex:= \Gamma_{m} \Gamma_{m};
        join_gamma(_)
        eliminate_kronecker(_)
        canonicalise(_)
        collect_terms(_)
        """
    )
    assert ns["ex"] == ns["Ex"](r"4")


def test_evaluate_components():
    ns = run_cdb(
        r"""
        {t,r}::Coordinate.
        {a,b}::Indices(values={t,r}, position=independent).
        \partial{#}::PartialDerivative.
        ex:= A_{a} A_{a};
        evaluate(ex, $A_{t}=1, A_{r}=r$, rhsonly=False)
        """
    )
    # A_t A_t + A_r A_r = 1 + r**2
    assert "r" in ns["ex"].input_form()


def test_sympy_bridge():
    ns = run_cdb(
        r"""
        ex:= \sin(x)**2 + \cos(x)**2;
        simplify(_)
        """
    )
    assert ns["ex"] == ns["Ex"](r"1")


def test_display_plain():
    # `;` means display; the terminal Server of cadabra2_defaults prints it.
    ns = run_cdb(
        r"""
        ex:= A_{m} + B_{m};
        """,
        display=True,
    )
    assert ns["ex"].input_form() == "A_{m} + B_{m}"
