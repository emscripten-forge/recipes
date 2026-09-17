import pytest


def test_import():
    import zarr  # noqa: F401


@pytest.mark.xfail(reason="zarr sync API requires JSPI, not enabled in pyjs runtime")
def test_basic_array():
    import numpy as np
    import zarr

    z = zarr.zeros((100, 100), chunks=(10, 10), dtype="i4")
    assert z.shape == (100, 100)
    z[0, :] = np.arange(100)
    assert z[0, 1] == 1


@pytest.mark.xfail(reason="zarr sync API requires JSPI, not enabled in pyjs runtime")
def test_memory_store_roundtrip():
    import numpy as np
    import zarr

    store = zarr.storage.MemoryStore()
    root = zarr.open_group(store=store, mode="w")
    arr = root.require_array("data", shape=(50,), chunks=(10,), dtype="f4")
    arr[:] = np.ones(50, dtype="f4")
    np.testing.assert_array_equal(arr[:], np.ones(50, dtype="f4"))


@pytest.mark.xfail(reason="zarr sync API requires JSPI, not enabled in pyjs runtime")
def test_local_store_roundtrip(tmp_path):
    import numpy as np
    import zarr

    store = zarr.storage.LocalStore(str(tmp_path / "test.zarr"))
    root = zarr.open_group(store=store, mode="w")
    arr = root.require_array("x", shape=(50,), chunks=(10,), dtype="i4")
    arr[:] = np.arange(50)
    np.testing.assert_array_equal(arr[:], np.arange(50))
