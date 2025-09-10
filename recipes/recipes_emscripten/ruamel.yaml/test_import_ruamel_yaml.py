def test_import_ruamel_yaml():
    import ruamel.yaml
    
    # Test basic YAML operations
    yaml = ruamel.yaml.YAML()
    
    # Test loading/dumping
    data = {'key': 'value', 'number': 42}
    yaml_str = yaml.dump(data, stream=None)
    
    # Test that we can load it back
    loaded_data = yaml.load(yaml_str)
    assert loaded_data['key'] == 'value'
    assert loaded_data['number'] == 42
    