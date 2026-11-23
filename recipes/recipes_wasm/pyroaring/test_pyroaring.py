def test_bitmap_set_operations():
    from pyroaring import BitMap

    bm1 = BitMap()
    bm1.add(3)
    bm1.add(18)
    assert 3 in bm1
    assert 4 not in bm1

    bm2 = BitMap([3, 27, 42])
    assert bm1 == BitMap([3, 18])
    assert bm2 == BitMap([3, 27, 42])
    assert bm1 & bm2 == BitMap([3])
    assert bm1 | bm2 == BitMap([3, 18, 27, 42])


def test_bitmap_serialization_round_trip():
    from pyroaring import BitMap

    bm = BitMap(range(0, 1000, 7))
    assert BitMap.deserialize(bm.serialize()) == bm
    assert len(bm) == len(range(0, 1000, 7))
