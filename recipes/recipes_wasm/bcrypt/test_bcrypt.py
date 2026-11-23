import pytest

_test_vectors = [
    (
        b"Kk4DQuMMfZL9o",
        b"$2b$04$cVWp4XaNU8a4v1uMRum2SO",
        b"$2b$04$cVWp4XaNU8a4v1uMRum2SO026BWLIoQMD/TXg5uZV.0P.uO8m3YEm",
    ),
    (
        b"9IeRXmnGxMYbs",
        b"$2b$04$pQ7gRO7e6wx/936oXhNjrO",
        b"$2b$04$pQ7gRO7e6wx/936oXhNjrOUNOHL1D0h1N2IDbJZYs.1ppzSof6SPy",
    ),
    (
        b"xVQVbwa1S0M8r",
        b"$2b$04$SQe9knOzepOVKoYXo9xTte",
        b"$2b$04$SQe9knOzepOVKoYXo9xTteNYr6MBwVz4tpriJVe3PNgYufGIsgKcW",
    ),
]

_2y_test_vectors = [
    (
        b"\xa3",
        b"$2y$05$/OK.fbVrR/bpIqNJ5ianF.Sa7shbm4.OzKpvFnX1pQLmQW96oUlCq",
        b"$2y$05$/OK.fbVrR/bpIqNJ5ianF.Sa7shbm4.OzKpvFnX1pQLmQW96oUlCq",
    ),
]


def test_gensalt_basic():
    import bcrypt

    salt = bcrypt.gensalt()
    assert salt.startswith(b"$2b$12$")


@pytest.mark.parametrize(
    ("rounds", "expected_prefix"),
    [(4, b"$2b$04$"), (8, b"$2b$08$"), (12, b"$2b$12$")],
)
def test_gensalt_rounds_valid(rounds, expected_prefix):
    import bcrypt

    assert bcrypt.gensalt(rounds).startswith(expected_prefix)


@pytest.mark.parametrize("rounds", [1, 2, 3])
def test_gensalt_rounds_invalid(rounds):
    import bcrypt

    with pytest.raises(ValueError):
        bcrypt.gensalt(rounds)


def test_gensalt_bad_prefix():
    import bcrypt

    with pytest.raises(ValueError):
        bcrypt.gensalt(prefix=b"bad")


def test_gensalt_2a_prefix():
    import bcrypt

    assert bcrypt.gensalt(prefix=b"2a").startswith(b"$2a$12$")


@pytest.mark.parametrize(("password", "salt", "hashed"), _test_vectors)
def test_hashpw_new(password, salt, hashed):
    import bcrypt

    assert bcrypt.hashpw(password, salt) == hashed


@pytest.mark.parametrize(("password", "salt", "hashed"), _test_vectors)
def test_checkpw(password, salt, hashed):
    import bcrypt

    assert bcrypt.checkpw(password, hashed) is True


@pytest.mark.parametrize(("password", "salt", "hashed"), _test_vectors)
def test_hashpw_existing(password, salt, hashed):
    import bcrypt

    assert bcrypt.hashpw(password, hashed) == hashed


@pytest.mark.parametrize(("password", "hashed", "expected"), _2y_test_vectors)
def test_hashpw_2y_prefix(password, hashed, expected):
    import bcrypt

    assert bcrypt.hashpw(password, hashed) == expected


def test_hashpw_invalid_prefix():
    import bcrypt

    with pytest.raises(ValueError):
        bcrypt.hashpw(b"password", b"$2z$04$cVWp4XaNU8a4v1uMRum2SO")


def test_checkpw_wrong_password():
    import bcrypt

    hashed = b"$2b$04$cVWp4XaNU8a4v1uMRum2SO026BWLIoQMD/TXg5uZV.0P.uO8m3YEm"
    assert bcrypt.checkpw(b"not the password", hashed) is False


def test_hash_and_verify_roundtrip():
    import bcrypt

    hashed = bcrypt.hashpw(b"correct horse", bcrypt.gensalt(4))
    assert bcrypt.checkpw(b"correct horse", hashed) is True
    assert bcrypt.checkpw(b"wrong", hashed) is False
