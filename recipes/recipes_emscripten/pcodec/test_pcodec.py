import numpy as np
import pytest


@pytest.mark.parametrize("dtype", ["f4", "f8", "i4", "i8", "u4", "u8"])
def test_simple_round_trip(dtype):
    from pcodec import ChunkConfig, standalone

    np.random.seed(42)

    data = np.random.uniform(0, 1000, size=100).astype(dtype)
    compressed = standalone.simple_compress(data, ChunkConfig())
    decompressed = standalone.simple_decompress(compressed)

    np.testing.assert_array_equal(data, decompressed)


def test_partial_decompression():
    from pcodec import ChunkConfig, standalone

    np.random.seed(42)

    data = np.random.uniform(0, 1000, size=50).astype(np.float32)
    compressed = standalone.simple_compress(data, ChunkConfig())

    out = np.zeros(10, dtype=np.float32)
    progress = standalone.simple_decompress_into(compressed, out)

    np.testing.assert_array_equal(out, data[:10])
    assert progress.n_processed == 10
    assert not progress.finished


@pytest.mark.parametrize("length", [0, 100, 1000])
def test_different_lengths(length):
    from pcodec import ChunkConfig, standalone

    np.random.seed(42)

    data = np.random.uniform(0, 1000, size=length).astype(np.float64)

    compressed = standalone.simple_compress(data, ChunkConfig())
    decompressed = standalone.simple_decompress(compressed)

    np.testing.assert_array_equal(data, decompressed)
