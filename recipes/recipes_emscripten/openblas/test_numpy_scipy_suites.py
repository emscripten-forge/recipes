import pathlib
import sys

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
    # np.test() always passes -q; verbose=2 adds -v so they cancel and
    # pytest's default progress output ([ 42%]) is shown, not per-test -v.
    assert np.test(
        label="full",
        verbose=2,
        extra_argv=["--tb=short"],
    ), "NumPy tests failed"


def test_scipy_suite():
    # Full SciPy fast suite (upstream CI: -m "not slow").
    # scipy-tests overlays the test modules but not scipy/conftest.py, so
    # wasm skips from emscripten-forge/recipes#6320 are loaded here until
    # that PR lands. Default pytest verbosity: progress, not per-test names.
    plugin_dir = str(pathlib.Path(__file__).resolve().parent)
    if plugin_dir not in sys.path:
        sys.path.insert(0, plugin_dir)
    assert scipy.test(
        label="fast",
        extra_argv=[
            "--tb=line",
            "--continue-on-collection-errors",
            "-p",
            "scipy_wasm_skips",
        ],
    ), "SciPy tests failed"
