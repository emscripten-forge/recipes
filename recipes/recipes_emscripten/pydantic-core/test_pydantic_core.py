
def test_pydantic_core():
    from pydantic_core import SchemaValidator, ValidationError

    v = SchemaValidator(
        {
            'type': 'typed-dict',
            'fields': {
                'name': {
                    'type': 'typed-dict-field',
                    'schema': {
                        'type': 'str',
                    },
                },
                'age': {
                    'type': 'typed-dict-field',
                    'schema': {
                        'type': 'int',
                        'ge': 18,
                    },
                },
                'is_developer': {
                    'type': 'typed-dict-field',
                    'schema': {
                        'type': 'default',
                        'schema': {'type': 'bool'},
                        'default': True,
                    },
                },
            },
        }
    )

    r1 = v.validate_python({'name': 'Samuel', 'age': 35})
    assert r1 == {'name': 'Samuel', 'age': 35, 'is_developer': True}

    # pydantic-core can also validate JSON directly
    r2 = v.validate_json('{"name": "Samuel", "age": 35}')
    assert r1 == r2
