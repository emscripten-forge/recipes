import importlib.util
import pathlib
import shutil
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


def _install_scipy_wasm_skips():
    # scipy.test() starts a nested pytest with --pyargs scipy. That session
    # does not import plugins from this test-file directory, so put the
    # overlay on site-packages (already on sys.path) and in sys.modules.
    src = pathlib.Path(__file__).resolve().with_name("scipy_wasm_skips.py")
    assert src.is_file(), src
    dst = pathlib.Path(scipy.__file__).resolve().parent.parent / src.name
    try:
        shutil.copy(src, dst)
        load_from = dst
    except OSError:
        load_from = src
    spec = importlib.util.spec_from_file_location("scipy_wasm_skips", load_from)
    module = importlib.util.module_from_spec(spec)
    sys.modules["scipy_wasm_skips"] = module
    spec.loader.exec_module(module)


def test_scipy_suite():
    # Full SciPy fast suite (upstream CI: -m "not slow").
    # scipy-tests overlays the test modules but not scipy/conftest.py, so
    # wasm skips from emscripten-forge/recipes#6320 are loaded here until
    # that PR lands. Default pytest verbosity: progress, not per-test names.
    _install_scipy_wasm_skips()
    assert scipy.test(
        label="fast",
        extra_argv=[
            "--tb=line",
            "--continue-on-collection-errors",
            "-p",
            "scipy_wasm_skips",
        ],
    ), "SciPy tests failed"
