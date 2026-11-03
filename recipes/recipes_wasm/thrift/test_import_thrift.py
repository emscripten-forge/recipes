def test_import_thrift():
    """Test that the thrift package can be imported and basic functionality works."""
    import thrift
    from thrift.transport import TTransport
    from thrift.protocol import TBinaryProtocol
    
    # Test basic memory buffer and protocol
    transport = TTransport.TMemoryBuffer()
    protocol = TBinaryProtocol.TBinaryProtocol(transport)
    
    # Write some basic types
    protocol.writeI32(42)
    protocol.writeString("Hello, Thrift!")
    protocol.writeBool(True)
    
    # Get the buffer and create a new one for reading
    data = transport.getvalue()
    read_transport = TTransport.TMemoryBuffer(data)
    read_protocol = TBinaryProtocol.TBinaryProtocol(read_transport)
    
    # Read back
    i32_value = read_protocol.readI32()
    str_value = read_protocol.readString()
    bool_value = read_protocol.readBool()
    
    # Verify
    assert i32_value == 42, f"Expected 42, got {i32_value}"
    assert str_value == "Hello, Thrift!", f"Expected 'Hello, Thrift!', got {str_value}"
    assert bool_value == True, f"Expected True, got {bool_value}"
    
    print("Thrift Python bindings test passed!")
