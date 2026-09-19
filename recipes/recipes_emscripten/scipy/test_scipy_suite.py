import pathlib

import numpy as np
import scipy


def test_scipy_tests_are_installed():
    root = pathlib.Path(scipy.__file__).resolve().parent
    test_files = list(root.glob("**/tests/test_*.py"))
    assert test_files, (
        "scipy-tests must overlay SciPy test modules under site-packages/scipy"
    )


def _assert_openblas(pkg, cfg):
    # Meson CONFIG _cleanup() drops falsey values, so "found" is absent when
    # BLAS was not found and name is "auto". OpenBLAS builds record the name
    # as "openblas" or "scipy-openblas" (NumPy's pkg-config alias).
    deps = cfg["Build Dependencies"]
    for kind in ("blas", "lapack"):
        dep = deps.get(kind) or {}
        name = str(dep.get("name") or "").lower()
        assert "openblas" in name, f"{pkg} {kind} is not OpenBLAS: {dep!r}"
        if "found" in dep:
            assert dep["found"] is True, (pkg, kind, dep)
        obcfg = dep.get("openblas configuration")
        if obcfg is not None:
            assert obcfg != "unknown", (pkg, kind, dep)


def test_openblas_build_config():
    _assert_openblas("numpy", np.show_config(mode="dicts"))
    _assert_openblas("scipy", scipy.show_config(mode="dicts"))


def test_scipy_suite():
    # Full SciPy fast suite (upstream CI: -m "not slow"). No module filter.
    # Runs on OpenBLAS-linked NumPy (emscripten-forge/recipes#6310).
    # Wasm-incompatible tests (threads, processes, mmap, FITPACK flang ABI,
    # FFT backends, batched tridiagonal eigensolvers) are skipped in
    # scipy/conftest.py. Default pytest verbosity already prints a running
    # [ 12%] on each module line; --tb=line keeps failure output short.
    assert scipy.test(
        label="fast",
        extra_argv=["--tb=line", "--continue-on-collection-errors"],
    ), "SciPy tests failed"
