def test_import_xgboost():
    import xgboost

    assert xgboost.__version__.startswith("2.1")
