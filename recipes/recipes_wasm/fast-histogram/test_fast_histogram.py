def test_fast_histogram():
    from fast_histogram import histogram1d
    result = histogram1d([1, 2, 3], bins=2, range=[0.5, 4.5])
    assert result.shape == (2,)
    assert result[0] == 2
    assert result[1] == 1
