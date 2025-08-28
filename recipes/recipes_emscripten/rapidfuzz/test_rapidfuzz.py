def test_rapidfuzz():
    from rapidfuzz import fuzz
    r = fuzz.ratio("this is a test", "this is a test!")
    assert r>=96.0
    assert r<=97.0