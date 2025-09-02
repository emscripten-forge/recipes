import rpds

# Test basic functionality
list_data = rpds.List([1, 2, 3])
assert len(list_data) == 3
assert list_data[0] == 1

hash_map = rpds.HashTrieMap({"a": 1, "b": 2})
assert hash_map["a"] == 1

print("rpds import and basic functionality test passed")