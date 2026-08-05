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
    from numba import njit

    require_global_nrt()

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


def test_wasm_simd_autovectorization():
    from numba import njit

    require_global_nrt()

    @njit(fastmath=True)
    def add_one_inplace(values):
        for i in range(values.size):
            values[i] += np.float32(1.0)

    values = np.arange(1024, dtype=np.float32)
    expected = values + np.float32(1.0)
    add_one_inplace(values)

    np.testing.assert_array_equal(values, expected)
    assembly = add_one_inplace.inspect_asm(add_one_inplace.signatures[0])
    assert "f32x4.add" in assembly
    assert '"simd128"' in assembly
