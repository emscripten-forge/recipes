def test_import_fxrays():
    import FXrays

    assert FXrays.version()


def test_find_xrays():
    import FXrays

    # The cone {x >= 0 : x0 - x1 = 0, x1 - x2 = 0} in R^3 is spanned by
    # the single ray (1, 1, 1).
    matrix = [1, -1, 0,
              0, 1, -1]
    rays = FXrays.find_Xrays(2, 3, matrix, filtering=False,
                             print_progress=False)
    assert [tuple(ray) for ray in rays] == [(1, 1, 1)]
