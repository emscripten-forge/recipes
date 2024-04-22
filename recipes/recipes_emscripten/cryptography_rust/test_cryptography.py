def test_cryptography(selenium):
    import base64

    from cryptography.fernet import Fernet, MultiFernet

    f1 = Fernet(base64.urlsafe_b64encode(b"\x00" * 32))
    f2 = Fernet(base64.urlsafe_b64encode(b"\x01" * 32))
    f = MultiFernet([f1, f2])

    assert f1.decrypt(f.encrypt(b"abc")) == b"abc"
