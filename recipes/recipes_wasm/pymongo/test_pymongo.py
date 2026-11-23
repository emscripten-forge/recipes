import datetime


def test_import_pymongo():
    import pymongo

    assert isinstance(pymongo.version, str)
    assert pymongo.version.startswith("4.20.")


def test_c_extensions_loaded():
    # The build sets PYMONGO_C_EXT_MUST_BUILD=1, so these must be importable.
    from bson import _cbson  # noqa: F401
    from bson import has_c as bson_has_c
    from pymongo import _cmessage  # noqa: F401
    from pymongo.common import has_c as pymongo_has_c

    assert bson_has_c()
    assert pymongo_has_c()


def test_objectid_roundtrip():
    from bson import ObjectId

    oid = ObjectId()
    assert len(str(oid)) == 24
    assert ObjectId(str(oid)) == oid


def test_bson_roundtrip():
    import bson
    from bson import ObjectId, Binary
    from bson.int64 import Int64

    doc = {
        "_id": ObjectId("65f0c0ffee0000000000abcd"),
        "name": "pyodide",
        "count": 3,
        "big": Int64(2**40),
        "blob": Binary(b"\x00\x01\x02"),
        "when": datetime.datetime(2020, 1, 1, 12, 30, 0),
        "nested": {"a": [1, 2.5, None, True]},
    }
    decoded = bson.decode(bson.encode(doc))
    assert decoded["_id"] == doc["_id"]
    assert decoded["name"] == "pyodide"
    assert decoded["count"] == 3
    assert decoded["big"] == 2**40
    assert decoded["blob"] == b"\x00\x01\x02"
    assert decoded["when"] == doc["when"]
    assert decoded["nested"] == {"a": [1, 2.5, None, True]}


def test_json_util_roundtrip():
    from bson import ObjectId, json_util

    oid = ObjectId()
    doc = {
        "_id": oid,
        "x": 1,
        "when": datetime.datetime(2020, 1, 1, tzinfo=datetime.timezone.utc),
    }
    loaded = json_util.loads(json_util.dumps(doc))
    assert loaded["_id"] == oid
    assert loaded["x"] == 1
    assert loaded["when"].year == 2020


def test_son_preserves_order():
    from bson.son import SON

    son = SON([("a", 1), ("b", 2), ("c", 3)])
    assert list(son.keys()) == ["a", "b", "c"]


def test_uri_parsing():
    import pytest
    from pymongo.errors import InvalidURI
    from pymongo.uri_parser import parse_uri

    parsed = parse_uri("mongodb://user:pass@localhost:27017/mydb?appName=pyodide")
    assert parsed["nodelist"] == [("localhost", 27017)]
    assert parsed["username"] == "user"
    assert parsed["password"] == "pass"
    assert parsed["database"] == "mydb"
    assert parsed["options"]["appname"] == "pyodide"

    with pytest.raises(InvalidURI):
        parse_uri("not-a-mongodb-uri")


def test_client_construction_without_connecting():
    from bson.codec_options import CodecOptions
    from pymongo import MongoClient
    from pymongo.read_preferences import ReadPreference
    from pymongo.write_concern import WriteConcern

    # connect=False prevents an eager connection attempt, so no sockets are used.
    client = MongoClient("mongodb://localhost:27017", connect=False)
    db = client.get_database("testdb")
    coll = db.get_collection("testcoll")
    assert db.name == "testdb"
    assert coll.name == "testcoll"

    db2 = client.get_database(
        "testdb2",
        write_concern=WriteConcern(w=1),
        read_preference=ReadPreference.PRIMARY,
        codec_options=CodecOptions(tz_aware=True),
    )
    coll2 = db2.get_collection("testcoll2")
    assert db2.codec_options.tz_aware is True
    assert db2.read_preference == ReadPreference.PRIMARY
    assert db2.write_concern.document.get("w") == 1
    assert coll2.full_name == "testdb2.testcoll2"
    client.close()
