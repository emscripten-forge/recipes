import polars as pl

def test_basic():
    df = pl.DataFrame({
        "letter": ["a", "b", "c"],
        "number": [1, 2, 3],
    })

    expected = pl.DataFrame({"letter": ["b"], "number": [2]})
    assert df.filter(pl.col("letter") == "b").equals(expected)
