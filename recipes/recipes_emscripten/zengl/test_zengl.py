def test_import_zengl():
    import zengl

    assert hasattr(zengl, "context")
