def test_import_ujson():
    import decimal
    import json
    import math

    import ujson


    def assert_almost_equal(a, b):
        assert round(abs(a - b), 7) == 0

    test_encode_decimal
    sut = decimal.Decimal("1337.1337")
    encoded = ujson.encode(sut)
    decoded = ujson.decode(encoded)
    assert decoded == 1337.1337

    # test_write_escaped_string
    assert "\"\\u003cimg src='\\u0026amp;'\\/\\u003e\"" == ujson.dumps(
        "<img src='&amp;'/>", encode_html_chars=True
    )

    # test_double_long_issue
    sut = {"a": -4342969734183514}
    encoded = json.dumps(sut)
    decoded = json.loads(encoded)
    assert sut == decoded
    encoded = ujson.encode(sut)
    decoded = ujson.decode(encoded)
    assert sut == decoded

    # test_double_long_decimal_issue
    sut = {"a": -12345678901234.56789012}
    encoded = json.dumps(sut)
    decoded = json.loads(encoded)
    assert sut == decoded
    encoded = ujson.encode(sut)
    decoded = ujson.decode(encoded)
    assert sut == decoded

    # test_encode_decode_long_decimal
    sut = {"a": -528656961.4399388}
    encoded = ujson.dumps(sut)
    ujson.decode(encoded)

    # test_decimal_decode_test
    sut = {"a": 4.56}
    encoded = ujson.encode(sut)
    decoded = ujson.decode(encoded)
    assert_almost_equal(sut["a"], decoded["a"])

    # test_encode_double_conversion
    test_input = math.pi
    output = ujson.encode(test_input)
    assert round(test_input, 5) == round(json.loads(output), 5)
    assert round(test_input, 5) == round(ujson.decode(output), 5)

    # test_encode_double_neg_conversion
    test_input = -math.pi
    output = ujson.encode(test_input)

    assert round(test_input, 5) == round(json.loads(output), 5)
    assert round(test_input, 5) == round(ujson.decode(output), 5)

    # test_encode_array_of_nested_arrays
    test_input = [[[[]]]] * 20
    output = ujson.encode(test_input)
    assert test_input == json.loads(output)
    # assert output == json.dumps(test_input)
    assert test_input == ujson.decode(output)

    # test_encode_array_of_doubles
    test_input = [31337.31337, 31337.31337, 31337.31337, 31337.31337] * 10
    output = ujson.encode(test_input)
    assert test_input == json.loads(output)
    # assert output == json.dumps(test_input)
    assert test_input == ujson.decode(output)

    # test_encode_string_conversion2
    test_input = "A string \\ / \b \f \n \r \t"
    output = ujson.encode(test_input)
    assert test_input == json.loads(output)
    assert output == '"A string \\\\ \\/ \\b \\f \\n \\r \\t"'
    assert test_input == ujson.decode(output)

    # test_encode_unicode_bmp
    s = "\U0001f42e\U0001f42e\U0001f42d\U0001f42d"  # 🐮🐮🐭🐭
    encoded = ujson.dumps(s)
    encoded_json = json.dumps(s)

    if len(s) == 4:
        assert len(encoded) == len(s) * 12 + 2
    else:
        assert len(encoded) == len(s) * 6 + 2

    assert encoded == encoded_json
    decoded = ujson.loads(encoded)
    assert s == decoded

    # ujson outputs a UTF-8 encoded str object
    encoded = ujson.dumps(s, ensure_ascii=False)

    # json outputs an unicode object
    encoded_json = json.dumps(s, ensure_ascii=False)
    assert len(encoded) == len(s) + 2  # original length + quotes
    assert encoded == encoded_json
    decoded = ujson.loads(encoded)
    assert s == decoded

    # test_encode_symbols
    s = "\u273f\u2661\u273f"  # ✿♡✿
    encoded = ujson.dumps(s)
    encoded_json = json.dumps(s)
    assert len(encoded) == len(s) * 6 + 2  # 6 characters + quotes
    assert encoded == encoded_json
    decoded = ujson.loads(encoded)
    assert s == decoded

    # ujson outputs a UTF-8 encoded str object
    encoded = ujson.dumps(s, ensure_ascii=False)

    # json outputs an unicode object
    encoded_json = json.dumps(s, ensure_ascii=False)
    assert len(encoded) == len(s) + 2  # original length + quotes
    assert encoded == encoded_json
    decoded = ujson.loads(encoded)
    assert s == decoded

    # test_encode_list_conversion
    test_input = [1, 2, 3, 4]
    output = ujson.encode(test_input)
    assert test_input == json.loads(output)
    assert test_input == ujson.decode(output)

    # test_encode_dict_conversion
    test_input = {"k1": 1, "k2": 2, "k3": 3, "k4": 4}
    output = ujson.encode(test_input)
    assert test_input == json.loads(output)
    assert test_input == ujson.decode(output)
    assert test_input == ujson.decode(output)

    # test_encode_to_utf8
    test_input = b"\xe6\x97\xa5\xd1\x88".decode("utf-8")
    enc = ujson.encode(test_input, ensure_ascii=False)
    dec = ujson.decode(enc)
    assert enc == json.dumps(test_input, ensure_ascii=False)
    assert dec == json.loads(enc)

    # test_decode_from_unicode
    test_input = '{"obj": 31337}'
    dec1 = ujson.decode(test_input)
    dec2 = ujson.decode(str(test_input))
    assert dec1 == dec2
