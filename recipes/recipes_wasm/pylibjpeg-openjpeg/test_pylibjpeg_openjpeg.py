import numpy as np


def test_version():
    import openjpeg

    assert openjpeg.__version__


def test_lossless_roundtrip_u8():
    from openjpeg import decode, encode

    arr = (np.arange(64 * 48) % 256).astype(np.uint8).reshape(64, 48)
    encoded = encode(arr, photometric_interpretation=2)
    np.testing.assert_array_equal(decode(encoded), arr)


def test_lossless_roundtrip_u16():
    from openjpeg import decode, encode

    arr = (np.arange(32 * 32) * 37 % 65536).astype(np.uint16).reshape(32, 32)
    encoded = encode(arr, photometric_interpretation=2)
    np.testing.assert_array_equal(decode(encoded), arr)
