def test_import_ruamel_yaml_clib():
    import ruamel.yaml.clib
    # Basic functionality test
    from ruamel.yaml.clib import _CLoader, _CEmitter
    assert _CLoader is not None
    assert _CEmitter is not None