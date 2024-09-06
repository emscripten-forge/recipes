import orjson


def test_orjson():
    json_string = '{"name": "Alice", "age": 30, "city": "New York"}'
    json_data = orjson.loads(json_string)

    assert json_data == {"name": "Alice", "age": 30, "city": "New York"}
