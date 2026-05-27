def test_import_keyring():
    import keyring  # type: ignore[import-not-found]

    assert keyring.get_keyring() is not None
