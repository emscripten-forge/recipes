def test_pycdfpp():
    import pycdfpp

    assert pycdfpp.__version__ is not None
    cdf = pycdfpp.CDF()
    assert cdf is not None