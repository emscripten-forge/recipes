def test_import_psutil():
    import psutil

    assert hasattr(psutil, '__version__')
