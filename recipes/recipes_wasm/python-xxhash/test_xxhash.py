import xxhash


def test_known_digests():
    # reference values from xxHash's own test vectors (empty input, seed 0)
    assert xxhash.xxh32_hexdigest(b"") == "02cc5d05"
    assert xxhash.xxh64_hexdigest(b"") == "ef46db3751d8e999"
    assert xxhash.xxh3_64_hexdigest(b"") == "2d06800538d394c2"
    assert xxhash.xxh3_128_hexdigest(b"") == "99aa06d3014798d86001c324468d497f"


def test_streaming_equals_oneshot():
    data = bytes(range(256)) * 1000
    h = xxhash.xxh3_64()
    for i in range(0, len(data), 4096):
        h.update(data[i:i + 4096])
    assert h.intdigest() == xxhash.xxh3_64_intdigest(data)


def test_seed_and_copy():
    a = xxhash.xxh64(b"hello", seed=42)
    b = a.copy()
    b.update(b" world")
    assert a.hexdigest() == xxhash.xxh64_hexdigest(b"hello", seed=42)
    assert b.hexdigest() == xxhash.xxh64_hexdigest(b"hello world", seed=42)
    assert a.hexdigest() != xxhash.xxh64_hexdigest(b"hello")
