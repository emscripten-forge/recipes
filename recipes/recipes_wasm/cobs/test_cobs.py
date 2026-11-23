def test_cobs_encode_decode():
    from cobs import cobs

    assert cobs.encode(b"12345") == b"\x0612345"
    assert cobs.decode(b"\x01\x01\x01\x01") == b"\x00\x00\x00"


def test_cobsr_encode_decode():
    from cobs import cobsr

    assert cobsr.encode(b"\x01") == b"\x02\x01"
    assert cobsr.decode(b"\xFFa") == b"a\xFF"
