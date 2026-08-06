import numpy as np
import pytest

from interpolation import interp


def require_global_nrt():
    import ctypes

    # pytester also exercises eager-preload modes which load CPython extensions
    # with RTLD_LOCAL before Numba can request RTLD_GLOBAL.
    try:
        getattr(ctypes.CDLL(None), "NRT_adapt_ndarray_from_python")
    except AttributeError:
        pytest.skip("pytester eagerly preloaded Numba's NRT extension locally")


def test_numba_multilinear_interpolation():
    require_global_nrt()

    grid = np.linspace(0.0, 2.0, 3)
    values = np.array([0.0, 2.0, 4.0])
    points = np.array([0.25, 0.75, 1.5])

    result = interp(grid, values, points)

    np.testing.assert_allclose(result, 2.0 * points)
