from lazy_object_proxy import Proxy

# Test basic functionality
def get_value():
    return "test value"

proxy = Proxy(get_value)
assert str(proxy) == "test value"

print("lazy-object-proxy import and basic functionality test passed")