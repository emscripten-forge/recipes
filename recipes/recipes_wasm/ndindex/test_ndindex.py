def test_ndindex_basics():
    from ndindex import Integer, Slice, Tuple, ndindex

    idx1 = Integer(3)
    idx2 = Slice(1, 10, 2)
    idx3 = Tuple(0, Slice(None, 5))

    assert idx1.raw == 3
    assert idx2.raw == slice(1, 10, 2)
    assert idx3.raw == (0, slice(None, 5, None))
    assert len(Slice(2, 5)) == 3

    assert ndindex(3) == Integer(3)
    assert ndindex[1:5] == Slice(1, 5)
    assert ndindex[2, :5] == Tuple(2, Slice(None, 5))


def test_ndindex_methods():
    from ndindex import Integer, Slice, Tuple

    assert Slice(None, 10, None).reduce() == Slice(0, 10, 1)
    assert Integer(-2).reduce((5,)) == Integer(3)

    shape = (5, 6, 7)
    assert Integer(2).newshape(shape) == (6, 7)
    assert Slice(1, 4).newshape(shape) == (3, 6, 7)
    assert Tuple(0, Slice(1, 4), ...).newshape(shape) == (3, 7)

    assert Integer(2).isvalid((5,))
    assert not Integer(2).isvalid((2,))
