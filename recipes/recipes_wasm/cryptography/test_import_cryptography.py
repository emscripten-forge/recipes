
def test_import_cryptography():
    import cryptography
    import cryptography.fernet
    from cryptography.hazmat.primitives.padding import ANSIX923, PKCS7
    import cryptography.hazmat
    import cryptography.utils
    import cryptography.x509


def test_fernet_roundtrip():
    from cryptography.fernet import Fernet

    f = Fernet(Fernet.generate_key())
    assert f.decrypt(f.encrypt(b"hello wasm")) == b"hello wasm"


def test_hashes_and_aead():
    import os
    from cryptography.hazmat.primitives import hashes
    from cryptography.hazmat.primitives.ciphers.aead import AESGCM

    h = hashes.Hash(hashes.SHA256())
    h.update(b"abc")
    assert h.finalize().hex() == (
        "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad"
    )

    key = AESGCM.generate_key(bit_length=128)
    nonce = os.urandom(12)
    aes = AESGCM(key)
    assert aes.decrypt(nonce, aes.encrypt(nonce, b"data", b"aad"), b"aad") == b"data"


def test_rsa_sign_verify():
    # RSA key generation and signing go through OpenSSL's BIGNUM code
    # (BN_*_word etc.), whose BN_ULONG must match between OpenSSL and the
    # Rust openssl crate (64-bit on wasm64)
    from cryptography.hazmat.primitives import hashes
    from cryptography.hazmat.primitives.asymmetric import padding, rsa

    key = rsa.generate_private_key(public_exponent=65537, key_size=1024)
    assert key.public_key().public_numbers().e == 65537
    sig = key.sign(b"message", padding.PKCS1v15(), hashes.SHA256())
    key.public_key().verify(sig, b"message", padding.PKCS1v15(), hashes.SHA256())

    numbers = key.private_numbers()
    assert numbers.p * numbers.q == key.public_key().public_numbers().n


def test_ec_and_x509():
    import datetime
    from cryptography import x509
    from cryptography.hazmat.primitives import hashes, serialization
    from cryptography.hazmat.primitives.asymmetric import ec
    from cryptography.x509.oid import NameOID

    key = ec.generate_private_key(ec.SECP256R1())
    name = x509.Name([x509.NameAttribute(NameOID.COMMON_NAME, "emscripten-forge")])
    now = datetime.datetime(2026, 1, 1, tzinfo=datetime.timezone.utc)
    cert = (
        x509.CertificateBuilder()
        .subject_name(name)
        .issuer_name(name)
        .public_key(key.public_key())
        .serial_number(12345678901234567890)
        .not_valid_before(now)
        .not_valid_after(now + datetime.timedelta(days=1))
        .sign(key, hashes.SHA256())
    )
    pem = cert.public_bytes(serialization.Encoding.PEM)
    loaded = x509.load_pem_x509_certificate(pem)
    assert loaded.serial_number == 12345678901234567890
    assert loaded.subject == name
    loaded.public_key().verify(
        loaded.signature, loaded.tbs_certificate_bytes, ec.ECDSA(hashes.SHA256())
    )
