import json
import outlines_core

def test_import():
    assert outlines_core is not None
    
def test_basic_functionality():
    schema =  {
      "title": "Foo",
      "type": "object",
      "properties": {"date": {"type": "string", "format": "date"}}
    }
    regex = outlines_core.json_schema.build_regex_from_schema(json.dumps(schema))
    assert regex=='\\{([ ]?"date"[ ]?:[ ]?"(?:\\d{4})-(?:0[1-9]|1[0-2])-(?:0[1-9]|[1-2][0-9]|3[0-1])")?[ ]?\\}'

if __name__ == "__main__":
    test_import()
    test_basic_functionality()
