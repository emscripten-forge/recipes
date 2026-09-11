import numpy as np
import scipy


def test_openblas_build_config():
    for pkg, cfg in (
        ("numpy", np.show_config(mode="dicts")),
        ("scipy", scipy.show_config(mode="dicts")),
    ):
        blas = cfg["Build Dependencies"]["blas"]
        lapack = cfg["Build Dependencies"]["lapack"]
        assert blas["found"] is True, pkg
        assert lapack["found"] is True, pkg
        assert "openblas" in blas["name"], (pkg, blas["name"])
        assert "openblas" in lapack["name"], (pkg, lapack["name"])
        assert blas["openblas configuration"] != "unknown", (pkg, blas)


def test_numpy_suite():
    # Entire NumPy suite, including tests marked slow (label="full").
    # np.test() always passes -q, which cancels one -v. verbose=2 plus
    # extra_argv -v nets pytest -v: test names without flooding the
    # browser console (which made Playwright's wait expire under -vvv).
    assert np.test(
        label="full",
        verbose=2,
        extra_argv=["--tb=short", "-v"],
    ), "NumPy tests failed"


def test_scipy_suite():
    # Full SciPy fast suite (upstream CI: -m "not slow").
    # scipy-tests overlays the test modules; wasm skips live in SciPy's
    # conftest.py once emscripten-forge/recipes#6320 lands.
    assert scipy.test(
        label="fast",
        extra_argv=["--tb=line", "-v", "-s", "--continue-on-collection-errors"],
    ), "SciPy tests failed"
