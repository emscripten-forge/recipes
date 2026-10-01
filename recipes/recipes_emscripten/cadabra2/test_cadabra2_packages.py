"""Tests of the `cdb` library packages. These are Cadabra notebooks (.cnb)
which are compiled to Python on first import by the import hook installed by
`cadabra2_defaults`; two of them use compiled helpers which, in this build,
live inside the cadabra2 extension module."""

import os
import textwrap


def run_cdb(source):
    """Run Cadabra notation the way the `cadabra2` REPL does: in a namespace
    set up by cadabra2_defaults and using the global kernel, which is also the
    kernel used by the (compiled) `cdb` packages."""
    import cadabra2

    code = cadabra2.cdb2python_string(textwrap.dedent(source), False, "")
    namespace = {}
    exec("from cadabra2 import *\nfrom cadabra2_defaults import *\n", namespace)
    namespace["__cdbkernel__"] = cadabra2.__cdbkernel__
    exec(compile(code, "<cadabra>", "exec"), namespace)
    return namespace


def test_import_hook_installed():
    import importlib
    import sys

    import cadabra2_defaults

    assert cadabra2_defaults.PackageCompiler in sys.meta_path
    # Called by micropip/pip after installing packages; must not trip over
    # the import hook (patches/0002).
    importlib.invalidate_caches()


def test_compile_package(tmp_path):
    import cadabra2

    src = tmp_path / "mypkg.cdb"
    src.write_text("def twice(ex):\n    return ex + ex\n\nfoo:= A_{m} + B_{m};\n")
    out = tmp_path / "mypkg.py"
    cadabra2.compile_package__(str(src), str(out))
    code = out.read_text()
    assert "def twice" in code
    assert "Ex(" in code


def test_import_user_cdb_package(tmp_path, monkeypatch):
    # A .cdb file on sys.path can be imported like a Python module.
    (tmp_path / "userpkg_cdb.cdb").write_text(
        textwrap.dedent(
            r"""
            def make():
                ex:= C_{m n} + C_{n m};
                return ex
            """
        )
    )
    monkeypatch.syspath_prepend(str(tmp_path))
    ns = run_cdb(
        r"""
        import userpkg_cdb
        C_{m n}::Symmetric.
        res = userpkg_cdb.make()
        canonicalise(res)
        collect_terms(res)
        """
    )
    assert ns["res"] == ns["Ex"](r"2 C_{m n}")


def test_cdb_core_manip():
    ns = run_cdb(
        r"""
        from cdb.core.manip import get_lhs, get_rhs, swap_sides, eq_to_subrule
        ex:= a = b + c;
        lhs = get_lhs(ex)
        rhs = get_rhs(ex)
        rule = eq_to_subrule(ex)
        swap_sides(ex)
        """
    )
    Ex = ns["Ex"]
    assert ns["lhs"] == Ex(r"a")
    assert ns["rhs"] == Ex(r"b + c")
    assert ns["rule"] == Ex(r"b + c -> a")
    assert ns["ex"] == Ex(r"b + c = a")


def test_cdb_utils_node_and_indices():
    ns = run_cdb(
        r"""
        from cdb.utils.node import n_children
        from cdb.utils.indices import get_free_indices
        ex:= A_{m n} B_{n p};
        nfree = len(get_free_indices(ex.top()))
        """
    )
    assert ns["nfree"] == 2


def test_cdb_core_component_compiled():
    # cdb.core.component imports the compiled cdb.core._component.
    ns = run_cdb(
        r"""
        from cdb.core.component import get_component
        {t,x}::Coordinate.
        {i,j}::Indices(values={t,x}).
        ex:= b_{i} = a_{i};
        evaluate(ex, $a_{t}=1, a_{x}=2$, rhsonly=True)
        cx = get_component(ex, $x$)
        expected:= b_{x} = 2;
        """
    )
    import cadabra2

    assert ns["cx"] == ns["expected"]
    import cdb.core._component as comp

    assert comp is cadabra2._component


def test_cdb_utils_develop_algo():
    # cdb.utils.develop builds on the compiled cdb.utils._algorithm.
    ns = run_cdb(
        r"""
        from cdb.utils.develop import algo
        @algo
        def switch_indices(node):
            if node.parent_rel == parent_rel_t.sub:
                node.parent_rel = parent_rel_t.super
                return result_t.changed
            if node.parent_rel == parent_rel_t.super:
                node.parent_rel = parent_rel_t.sub
                return result_t.changed
            return result_t.unchanged

        ex:= A_{\mu} + B_{\mu};
        switch_indices(ex)
        expected:= A^{\mu} + B^{\mu};
        """
    )
    assert ns["ex"] == ns["expected"]


def test_compiled_packages_are_cached():
    # The import hook writes the translated notebooks below the user config dir.
    import cadabra2_defaults  # noqa: F401  (installs the import hook)
    from cdb_appdirs import user_config_dir

    import cdb.core.manip  # noqa: F401

    cache = os.path.join(user_config_dir(), "cadabra_packages")
    found = []
    for root, _dirs, files in os.walk(cache):
        found += [f for f in files if f == "manip.py"]
    assert found
