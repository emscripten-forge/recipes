import pathlib

import scipy


def test_scipy_tests_are_installed():
    root = pathlib.Path(scipy.__file__).resolve().parent
    test_files = list(root.glob("**/tests/test_*.py"))
    assert test_files, (
        "scipy-tests must overlay SciPy test modules under site-packages/scipy"
    )


def test_scipy_suite():
    # Full SciPy fast suite (upstream CI: -m "not slow"). No module filter.
    # Used as a control against OpenBLAS-linked NumPy in emscripten-forge/recipes#6310.
    # Wasm-incompatible tests (threads, processes, mmap, FITPACK flang ABI,
    # FFT backends, batched tridiagonal eigensolvers) are skipped in
    # scipy/conftest.py; -v names the last test if a Fortran ABI abort
    # still kills the runtime.
    assert scipy.test(
        label="fast",
        extra_argv=["--tb=line", "-v", "-s", "--continue-on-collection-errors"],
    ), "SciPy tests failed"
