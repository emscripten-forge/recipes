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
    # This PR keeps the current allow-noblas numpy recipe (no OpenBLAS)
    # so we can compare failures against #6310.
    assert np.test(
        label="full",
        extra_argv=["--tb=short"],
    ), "NumPy tests failed"
