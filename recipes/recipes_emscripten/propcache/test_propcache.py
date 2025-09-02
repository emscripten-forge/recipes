def test_import():
    import propcache

def test_api_import():
    # Test the specific import that yarl 1.14.0 uses
    from propcache.api import under_cached_property

def test_basic_functionality():
    from propcache.api import under_cached_property as cached_property
    
    # Test that we can use cached_property (as yarl does)
    class TestClass:
        @cached_property
        def test_property(self):
            return "test_value"
    
    obj = TestClass()
    assert obj.test_property == "test_value"
    # Accessing again should return cached value
    assert obj.test_property == "test_value"