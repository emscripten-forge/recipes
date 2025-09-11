def test_import_ruamel_yaml():
    import ruamel.yaml
    from io import StringIO

    # Test basic YAML loading
    yaml = ruamel.yaml.YAML()

    # Test loading YAML string
    yaml_str = "key: value\nnumber: 42\n"
    loaded_data = yaml.load(yaml_str)

    assert loaded_data['key'] == 'value'
    assert loaded_data['number'] == 42
