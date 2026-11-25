def test_decode_astc():
    import texture2ddecoder

    width, height = 64, 64
    decoded = texture2ddecoder.decode_astc(b"\x00" * 4096, width, height, 4, 4)
    assert isinstance(decoded, bytes)
    assert len(decoded) == width * height * 4
