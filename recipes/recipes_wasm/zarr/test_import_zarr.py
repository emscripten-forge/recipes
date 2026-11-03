import numpy as np


def test_import_zarr():
    import zarr  # noqa: F401


def test_memory_store_roundtrip():
    import zarr

    z = zarr.create_array(store={}, shape=(100, 100), chunks=(10, 10), dtype="i4")
    z[:] = np.arange(10000, dtype="i4").reshape(100, 100)
    assert z[5, 7] == 507
    np.testing.assert_array_equal(z[:], np.arange(10000).reshape(100, 100))


def test_local_store_roundtrip(tmp_path):
    import zarr

    path = str(tmp_path / "data.zarr")
    root = zarr.open_group(path, mode="w")
    a = root.create_array("a", shape=(50,), chunks=(10,), dtype="f8")
    a[:] = np.linspace(0, 1, 50)
    root.attrs["answer"] = 42

    root2 = zarr.open_group(path, mode="r")
    assert root2.attrs["answer"] == 42
    np.testing.assert_allclose(root2["a"][:], np.linspace(0, 1, 50))


def test_numcodecs_compressor():
    import zarr
    from zarr.codecs import BloscCodec

    z = zarr.create_array(
        store={}, shape=(1000,), chunks=(100,), dtype="i8", compressors=BloscCodec()
    )
    z[:] = np.arange(1000)
    np.testing.assert_array_equal(z[:], np.arange(1000))
