
def test_import_boost_histogram():
    import boost_histogram


def test_fill_histogram():
    import boost_histogram as bh

    h = bh.Histogram(bh.axis.Regular(10, 0, 1))
    h.fill([0.05, 0.15, 0.15, 0.95])
    assert h.sum() == 4
    assert h[1] == 2
