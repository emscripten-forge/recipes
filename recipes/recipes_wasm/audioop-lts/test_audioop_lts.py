def test_add():
    import audioop

    assert audioop.add(b"1234", b"5678", 2) == b"fhjl"


def test_max_and_rms():
    import audioop

    assert audioop.max(b"\x01\x00\x05\x00", 2) == 5
    assert audioop.rms(b"\x00\x00\x00\x00", 2) == 0
