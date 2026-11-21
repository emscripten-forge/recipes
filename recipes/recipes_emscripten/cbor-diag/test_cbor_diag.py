def test_cbor_diag():
    from cbor_diag import diag2cbor

    assert diag2cbor('{1: "hello"}') == bytes.fromhex("a1016568656c6c6f")
