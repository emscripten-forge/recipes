from ligo.segments import segment


def test_ligo_segments():
    a = segment(1, 2)
    b = segment(2, 3)
    c = segment(5, 6)

    assert a.connects(b)
    assert a in (a + b)
    assert (a + b).intersects(b)
    assert a.disjoint(c)
