def test_import_jiter():
    import jiter


def test_jiter():
    import jiter
    json_string = b'{"name": "Alice", "age": 30, "city": "New York"}'
    json_data = jiter.from_json(json_string)
    assert json_data == {"name": "Alice", "age": 30, "city": "New York"}

    json_string = b'{"name": "Alice", "age": 30, "city": "New'
    json_data = jiter.from_json(json_string, partial_mode="trailing-strings")
    assert json_data == {"name": "Alice", "age": 30, "city": "New"}
