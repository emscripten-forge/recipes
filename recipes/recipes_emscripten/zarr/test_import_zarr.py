def test_import_zarr():
    import zarr

def test_create_array():
    import zarr
    zarr.config.set({'async.concurrency': 1, 'threading.max_workers': 0})
    import numpy as np
    z = zarr.zeros((100, 100), chunks=(10, 10), dtype='f4')
    # This only writes to 1 chunk out of 100!
    z[0:10, 0:10] = 1
    # This only reads 1 chunk
    slice_data = z[0:10, 0:10]
    assert np.all(slice_data == 1)
