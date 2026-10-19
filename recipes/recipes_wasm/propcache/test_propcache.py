def test_import():
    import propcache

def test_basic_functionality():
    import propcache
    
    # Test that we can use cached_property
    class TestClass:
        @propcache.cached_property
        def test_property(self):
            return "test_value"
    
    obj = TestClass()
    assert obj.test_property == "test_value"
    # Accessing again should return cached value
    assert obj.test_property == "test_value"