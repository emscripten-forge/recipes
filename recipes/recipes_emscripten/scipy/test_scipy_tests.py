import pathlib

import scipy


def test_scipy_tests_are_installed():
    root = pathlib.Path(scipy.__file__).resolve().parent
    test_files = list(root.glob("**/tests/test_*.py"))
    assert test_files, (
        "scipy-tests must overlay SciPy test modules under site-packages/scipy"
    )
