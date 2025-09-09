def test_import_msgspec():
    import msgspec
    
    # Test basic functionality to ensure the C extensions work
    import msgspec.json
    
    # Test basic JSON serialization/deserialization
    data = {"test": "value", "number": 42}
    encoded = msgspec.json.encode(data)
    decoded = msgspec.json.decode(encoded)
    assert decoded == data
    
    print("msgspec import and basic functionality test passed")