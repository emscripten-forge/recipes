def test_import_spherogram():
    import spherogram

    assert spherogram.__version__ == '2.4.1'


def test_compiled_extensions_load():
    import spherogram.planarity
    import spherogram.planarmap

    assert spherogram.planarity is not None
    assert spherogram.planarmap is not None


def test_knot_from_census():
    # Looking a knot up by name goes through the DT code tables in
    # snappy_manifolds.
    import spherogram

    knot = spherogram.Link('4_1')
    assert len(knot.crossings) == 4
    assert len(knot.link_components) == 1
    assert knot.writhe() == 0
    assert knot.DT_code() == [(4, 6, 8, 2)]
    assert knot.braid_word() == [1, -2, 1, -2]


def test_link_with_two_components():
    import spherogram

    link = spherogram.Link('L6a1')
    assert len(link.link_components) == 2
    assert link.writhe() == 2


def test_link_from_braid_word():
    import spherogram

    trefoil = spherogram.Link(braid_closure=[1, 1, 1])
    assert len(trefoil.link_components) == 1
    assert abs(trefoil.writhe()) == 3


def test_random_link_uses_planarmap():
    # random_link is the entry point that uses the planarmap extension.  The
    # diagram it builds can simplify away entirely - upstream returns an empty
    # link for roughly one call in ten, on any platform - so this only checks
    # that the call succeeds and stays within the requested component count.
    import spherogram

    link = spherogram.random_link(20, num_components=1,
                                  initial_map_gives_link=True)
    assert isinstance(link, spherogram.Link)
    assert len(link.link_components) <= 1
