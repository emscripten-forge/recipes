import numpy as np
import pytest


def test_import_numba():
    import numba

    assert numba.__version__


def test_scalar_jit():
    from numba import njit

    @njit
    def scalar_add(a, b):
        return a + b

    assert scalar_add(1.0, 2.5) == 3.5


def test_array_jit_and_specialization_cache():
    import ctypes
    from numba import njit

    # pytester also exercises an eager-preload mode which loads CPython
    # extensions with RTLD_LOCAL before Numba can request RTLD_GLOBAL. Numba's
    # generated array wrapper needs this NRT helper in the global symbol scope.
    try:
        getattr(ctypes.CDLL(None), "NRT_adapt_ndarray_from_python")
    except AttributeError:
        pytest.skip("pytester eagerly preloaded Numba's NRT extension locally")

    @njit
    def vector_add(a, b):
        out = np.empty_like(a)
        for i in range(len(a)):
            out[i] = a[i] + b[i]
        return out

    a = np.array([1.0, 2.0, 3.0], dtype=np.float64)
    b = np.array([4.0, 5.0, 6.0], dtype=np.float64)

    np.testing.assert_array_equal(vector_add(a, b), [5.0, 7.0, 9.0])
    assert len(vector_add.signatures) == 1

    # Second call must reuse the existing specialization.
    np.testing.assert_array_equal(vector_add(a, b), [5.0, 7.0, 9.0])
    assert len(vector_add.signatures) == 1
