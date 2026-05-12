def test_import_argon2_cffi_bindings():
    import argon2_cffi_bindings

    assert hasattr(argon2_cffi_bindings, '__version__')
