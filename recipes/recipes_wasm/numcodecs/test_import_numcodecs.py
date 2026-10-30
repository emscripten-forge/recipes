import numpy as np


def test_import_numcodecs():
    import numcodecs
    from numcodecs.blosc import Blosc


def test_codec_roundtrip():
    from numcodecs import Blosc, Zstd, LZ4, Zlib

    data = np.arange(10000, dtype="i4")
    for codec in (Blosc(cname="zstd", clevel=3), Zstd(level=3), LZ4(), Zlib(level=3)):
        enc = codec.encode(data)
        dec = np.frombuffer(codec.decode(enc), dtype="i4")
        assert np.array_equal(dec, data)
