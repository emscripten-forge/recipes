def test_import_ruamel_yaml():
    import ruamel.yaml
    
    # Basic functionality test
    yaml = ruamel.yaml.YAML()
    
    # Test basic parsing and dumping
    test_data = {'key': 'value', 'number': 42, 'list': [1, 2, 3]}
    
    # Test dump to string
    from io import StringIO
    stream = StringIO()
    yaml.dump(test_data, stream)
    yaml_string = stream.getvalue()
    
    # Test load from string
    stream2 = StringIO(yaml_string)
    loaded_data = yaml.load(stream2)
    
    assert loaded_data == test_data