def test_import_pyzmq():
    import pyzmq
    assert hasattr(pyzmq, '__version__')
