def test_hash_trie_map():
    from rpds import HashTrieMap

    original = HashTrieMap({"key": "value"})
    updated = original.insert("key", "updated")

    assert original["key"] == "value"
    assert updated["key"] == "updated"
