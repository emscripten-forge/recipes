def test_import_ruamel_yaml_clib():
    # Workaround for the cyclic dependency with ruamel.yaml
    from importlib.util import find_spec
    assert find_spec('_ruamel_yaml')
