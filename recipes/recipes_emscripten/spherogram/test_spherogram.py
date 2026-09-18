def test_spherogram():
    import spherogram

    # The figure-eight knot. Its diagram has four crossings and is
    # alternating, and this exercises the vendored planarity extension.
    K = spherogram.Link('4_1')
    assert len(K.crossings) == 4
    assert K.DT_code() == [(4, 6, 8, 2)]
    assert K.is_alternating()


def test_spherogram_knot_floer():
    import spherogram

    # knot_floer_homology imports the knot_floer_homology module lazily, so
    # this is what checks that run dependency is actually installed and
    # working. The figure-eight knot has total rank 5.
    K = spherogram.Link('4_1')
    assert K.knot_floer_homology()['total_rank'] == 5
