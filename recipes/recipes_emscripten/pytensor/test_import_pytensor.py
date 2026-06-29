
def test_import_pytensor():
    import pytensor


def test_pytensor_function():
    import pytensor
    import pytensor.tensor as pt

    x = pt.vector("x")
    y = x * 2
    fn = pytensor.function([x], y)
    result = fn([1.0, 2.0, 3.0])
    assert list(result) == [2.0, 4.0, 6.0]
