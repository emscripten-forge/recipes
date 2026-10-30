import numpy as np


def _roundtrip(arr, bits_allocated):
    from rle import decode_pixel_data, encode_pixel_data

    encoded = encode_pixel_data(
        arr.tobytes(),
        byteorder="<",
        rows=arr.shape[0],
        columns=arr.shape[1],
        samples_per_pixel=1,
        bits_allocated=bits_allocated,
        number_of_frames=1,
    )
    decoded = decode_pixel_data(
        encoded,
        version=2,
        rows=arr.shape[0],
        columns=arr.shape[1],
        bits_allocated=bits_allocated,
    )
    return np.frombuffer(decoded, dtype=arr.dtype).reshape(arr.shape)


def test_roundtrip_u8():
    arr = np.repeat(np.arange(16, dtype=np.uint8), 8).reshape(8, 16)
    np.testing.assert_array_equal(_roundtrip(arr, 8), arr)


def test_roundtrip_u16():
    arr = (np.arange(32 * 32) * 37 % 65536).astype(np.uint16).reshape(32, 32)
    np.testing.assert_array_equal(_roundtrip(arr, 16), arr)
