
def test_import_orjson():
    import orjson

    assert orjson.dumps([1, 2, 3]) == b'[1,2,3]'
    assert orjson.loads(b'[1,2,3]') == [1, 2, 3]

    assert orjson.dumps({'a': 1, 'b': 2, 'c': 3}) == b'{"a":1,"b":2,"c":3}'
    assert orjson.loads(b'{"a":1,"b":2,"c":3}') == {'a': 1, 'b': 2, 'c': 3}

    assert orjson.dumps(1) == b'1'
    assert orjson.loads(b'1') == 1

    assert orjson.dumps(1.0) == b'1.0'
    assert orjson.loads(b'1.0') == 1.0

    assert orjson.dumps('hello') == b'"hello"'
    assert orjson.loads(b'"hello"') == 'hello'

    assert orjson.dumps(True) == b'true'
    assert orjson.loads(b'true') == True

    assert orjson.dumps(False) == b'false'
    assert orjson.loads(b'false') == False

    assert orjson.dumps(None) == b'null'
    assert orjson.loads(b'null') == None

    assert orjson.dumps([1, 2, 3], option=orjson.OPT_INDENT_2) == b'[\n  1,\n  2,\n  3\n]'
    assert orjson.loads(b'[\n  1,\n  2,\n  3\n]') == [1, 2, 3]

    assert orjson.dumps([1, 2, 3], option=orjson.OPT_SORT_KEYS) == b'[1,2,3]'
    assert orjson.loads(b'[1,2,3]') == [1, 2, 3]

    assert orjson.dumps([1, 2, 3], option=orjson.OPT_SERIALIZE_NUMPY) == b'[1,2,3]'
    assert orjson.loads(b'[1,2,3]') == [1, 2, 3]

    assert orjson.dumps([1, 2, 3],