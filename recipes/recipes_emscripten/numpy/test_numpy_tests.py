import pathlib

import numpy as np


def test_numpy_tests_are_installed():
    root = pathlib.Path(np.__file__).resolve().parent
    test_files = list(root.glob("**/tests/test_*.py"))
    assert test_files, (
        "numpy-tests must overlay NumPy test modules under site-packages/numpy"
    )


def test_c_test_extensions():
    # Built with meson install_tag=tests: NumPy's C test helpers.
    from numpy._core import _multiarray_tests, _umath_tests

    assert hasattr(_multiarray_tests, "test_neighborhood_iterator")
    assert hasattr(_umath_tests, "test_dispatch")


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
