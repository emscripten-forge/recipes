def test_cramjam():
    import cramjam

    compressed = cramjam.snappy.compress(b"bytes")
    decompressed = cramjam.snappy.decompress(compressed)
    assert bytes(decompressed) == b"bytes"
