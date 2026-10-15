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


def test_import_pytensor_base():
    import pytensor


def test_pytensor_function():
    import numba
    import pytensor
    import pytensor.tensor as pt
    from pytensor.link.numba import NumbaLinker

    assert numba.__version__
    require_global_nrt()

    x = pt.vector("x")
    y = x * 2
    fn = pytensor.function([x], y)
    result = fn([1.0, 2.0, 3.0])
    assert list(result) == [2.0, 4.0, 6.0]
    assert isinstance(fn.maker.linker, NumbaLinker)


def test_pytensor_numba_elementwise_and_reduction():
    import numba
    import pytensor
    import pytensor.tensor as pt
    from pytensor.link.numba import NumbaLinker

    assert numba.__version__
    require_global_nrt()

    x = pt.vector("x", dtype="float64")
    y = pt.sum((x + 1.0) * (x - 2.0))
    fn = pytensor.function([x], y, mode="NUMBA")

    values = np.array([1.0, 2.0, 3.0, 4.0])
    expected = np.sum((values + 1.0) * (values - 2.0))

    np.testing.assert_allclose(fn(values), expected)
    assert isinstance(fn.maker.linker, NumbaLinker)
