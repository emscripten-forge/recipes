def test_md5():
    from Crypto.Hash import MD5

    hasher = MD5.new()
    hasher.update(b"Hello, World!")
    assert hasher.hexdigest() == "65a8e27d8879283831b664bd8b7f0ad4"


def test_aes_roundtrip():
    from Crypto.Cipher import AES
    from Crypto.Random import get_random_bytes
    from Crypto.Util.Padding import pad, unpad

    key = get_random_bytes(16)
    iv = get_random_bytes(16)
    plaintext = b"emscripten-forge test!"
    ciphertext = AES.new(key, AES.MODE_CBC, iv).encrypt(pad(plaintext, AES.block_size))
    decrypted = unpad(AES.new(key, AES.MODE_CBC, iv).decrypt(ciphertext), AES.block_size)
    assert decrypted == plaintext
