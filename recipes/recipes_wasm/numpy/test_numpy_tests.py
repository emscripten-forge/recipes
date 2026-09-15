import pathlib

import numpy as np


def test_numpy_tests_are_installed():
    root = pathlib.Path(np.__file__).resolve().parent
    test_files = list(root.glob("**/tests/test_*.py"))
    assert test_files, (
        "numpy-tests must overlay NumPy test modules under site-packages/numpy"
    )
