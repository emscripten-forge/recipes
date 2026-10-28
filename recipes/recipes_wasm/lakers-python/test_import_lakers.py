def test_lakers_import():
    """Test that lakers package can be imported successfully."""
    import lakers

    # Test basic import and availability of key functions
    assert hasattr(lakers, 'EdhocInitiator'), "EdhocInitiator should be available"
    assert hasattr(lakers, 'p256_generate_key_pair'), "p256_generate_key_pair should be available"

    # Test basic functionality
    # Generate a keypair
    key_pair = lakers.p256_generate_key_pair()
    assert key_pair is not None, "Key pair generation should work"

    # Instantiate an initiator
    initiator = lakers.EdhocInitiator()
    assert initiator is not None, "EdhocInitiator should be instantiable"

    print("lakers-python import and basic functionality test passed")