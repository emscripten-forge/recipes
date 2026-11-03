import numpy as np


def test_lossless_roundtrip_u8():
    import jpeg_ls

    arr = (np.arange(64 * 48) % 256).astype(np.uint8).reshape(64, 48)
    encoded = jpeg_ls.encode(arr)
    np.testing.assert_array_equal(jpeg_ls.decode(encoded), arr)


def test_lossless_roundtrip_u16():
    import jpeg_ls

    arr = (np.arange(32 * 32) * 37 % 4096).astype(np.uint16).reshape(32, 32)
    encoded = jpeg_ls.encode(arr)
    np.testing.assert_array_equal(jpeg_ls.decode(encoded), arr)


def test_near_lossless():
    import jpeg_ls

    arr = (np.arange(64 * 64) % 200).astype(np.uint8).reshape(64, 64)
    encoded = jpeg_ls.encode(arr, lossy_error=2)
    decoded = jpeg_ls.decode(encoded)
    assert np.abs(decoded.astype(int) - arr.astype(int)).max() <= 2
