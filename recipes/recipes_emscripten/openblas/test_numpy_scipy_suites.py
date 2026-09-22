import numpy as np
import scipy


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


def test_numpy_suite():
    # Entire NumPy suite, including tests marked slow (label="full").
    # np.test() always passes -q; verbose=2 adds -v so they cancel and
    # pytest's default progress output ([ 42%]) is shown, not per-test -v.
    assert np.test(
        label="full",
        verbose=2,
        extra_argv=["--tb=short"],
    ), "NumPy tests failed"


def test_scipy_suite():
    # Full SciPy fast suite (upstream CI: -m "not slow").
    # scipy-tests overlays the test modules. Wasm-incompatible tests
    # are skipped in scipy/conftest.py (emscripten-forge/recipes#6320).
    # Default pytest verbosity: progress percentage, not per-test names.
    assert scipy.test(
        label="fast",
        extra_argv=["--tb=line", "--continue-on-collection-errors"],
    ), "SciPy tests failed"
