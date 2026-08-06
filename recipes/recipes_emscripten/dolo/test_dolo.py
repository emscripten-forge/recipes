import sys

import numpy as np
import pytest


def require_global_nrt():
    import ctypes

    # pytester also exercises eager-preload modes which load CPython extensions
    # with RTLD_LOCAL before Numba can request RTLD_GLOBAL.
    try:
        getattr(ctypes.CDLL(None), "NRT_adapt_ndarray_from_python")
    except AttributeError:
        pytest.skip("pytester eagerly preloaded Numba's NRT extension locally")


def test_import_dolo_on_emscripten():
    import dolo

    assert sys.platform == "emscripten"
    assert dolo is not None


def test_numba_kernel():
    from dolo.algos.fb import PhiFB

    result = PhiFB(3.0, 4.0)

    assert result == 2.0
    assert PhiFB.nopython_signatures


def test_numba_generalized_ufunc():
    require_global_nrt()

    from dolo.numeric.taylor_expansion import eval_te_order_1

    result = eval_te_order_1(
        np.array([0.0]),
        np.array([1.0]),
        np.array([[2.0]]),
        np.array([3.0]),
    )

    np.testing.assert_allclose(result, np.array([7.0]))
