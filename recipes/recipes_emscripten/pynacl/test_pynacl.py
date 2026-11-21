import nacl.bindings
import nacl.encoding
import nacl.hash
import nacl.public
import nacl.secret
import nacl.signing
import nacl.utils


def test_import_pynacl():
    nacl.bindings.sodium_init()
    assert nacl.bindings.crypto_secretbox_KEYBYTES == 32


def test_secretbox_roundtrip():
    key = nacl.utils.random(nacl.secret.SecretBox.KEY_SIZE)
    box = nacl.secret.SecretBox(key)
    message = b"the quick brown fox"
    ciphertext = box.encrypt(message)
    assert box.decrypt(ciphertext) == message


def test_public_box_roundtrip():
    alice = nacl.public.PrivateKey.generate()
    bob = nacl.public.PrivateKey.generate()
    message = b"hello bob"
    encrypted = nacl.public.Box(alice, bob.public_key).encrypt(message)
    assert nacl.public.Box(bob, alice.public_key).decrypt(encrypted) == message


def test_ed25519_rfc8032_vector():
    # RFC 8032, section 7.1, test 1 (empty message)
    seed = bytes.fromhex(
        "9d61b19deffd5a60ba844af492ec2cc44449c5697b326919703bac031cae7f60"
    )
    key = nacl.signing.SigningKey(seed)
    assert key.verify_key.encode() == bytes.fromhex(
        "d75a980182b10ab7d54bfed3c964073a0ee172f3daa62325af021a68f707511a"
    )
    signed = key.sign(b"")
    assert signed.signature.hex() == (
        "e5564300c360ac729086e2cc806e828a84877f1eb8e5d974d873e065224901555"
        "fb8821590a33bacc61e39701cf9b46bd25bf5f0595bbe24655141438e7a100b"
    )
    key.verify_key.verify(b"", signed.signature)


def test_sha256_known_answer():
    digest = nacl.hash.sha256(b"abc", encoder=nacl.encoding.HexEncoder)
    assert digest.decode() == (
        "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad"
    )
