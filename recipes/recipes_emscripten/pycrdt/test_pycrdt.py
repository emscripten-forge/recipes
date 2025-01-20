import json
from pycrdt import Array, Doc, Map, Text 

def callback(events, event):
    events.append(
        dict(
            delta=event.delta,
            path=event.path,
        )
    )


def test_str():
    doc = Doc()
    map2 = Map({"key": "val"})
    array1 = Array([2, 3, map2])
    map1 = Map({"foo": array1})
    array0 = Array([0, 1, None, map1])
    doc["array"] = array0
    assert str(array0) == '[0,1,null,{"foo":[2,3,{"key":"val"}]}]'


def test_nested():
    doc = Doc()
    text1 = Text("my_text1")
    array1 = Array([0, "foo", 2])
    text2 = Text("my_text2")
    map1 = Map({"foo": [3, 4, 5], "bar": "hello", "baz": text2})
    array0 = Array([text1, array1, map1])
    doc["array"] = array0
    ref = [
        "my_text1",
        [0, "foo", 2],
        {"bar": "hello", "foo": [3, 4, 5], "baz": "my_text2"},
    ]
    assert json.loads(str(array0)) == ref
    assert isinstance(array0[2], Map)
    assert isinstance(array0[2]["baz"], Text)
