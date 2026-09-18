def test_fxrays():
    import FXrays

    # Intersect the positive orthant of R^3 with the plane x - y = 0. The
    # resulting cone has two extremal rays, spanned by (1, 1, 0) and
    # (0, 0, 1). Arguments are (rows, columns, matrix as a flat list).
    rays = FXrays.find_Xrays(1, 3, [1, -1, 0],
                             filtering=False, print_progress=False)
    assert sorted(rays) == [(0, 0, 1), (1, 1, 0)]
