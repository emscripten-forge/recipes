def test_fastcan():
    from fastcan import FastCan
    X = [[1, 0], [0, 1]]
    y = [1, 0]
    s = FastCan(verbose=0).fit(X, y).get_support()
    assert (s == [True, False]).all()
