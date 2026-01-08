def test_matplotlib_base():
    # This tests both the _tri and _qhull shared libraries.
    import matplotlib.tri as mtri
    from numpy.testing import assert_allclose

    x = [0, 1, 0.5, 1.5]
    y = [0, 0, 1, 1]
    tri = mtri.Triangulation(x, y)

    assert tri.is_delaunay
    assert_allclose(tri.x, x)
    assert_allclose(tri.y, y)
    assert_allclose(tri.triangles, [[1, 2, 0], [3, 2, 1]])
    assert_allclose(tri.neighbors, [[1, -1, -1], [-1, 0, -1]])
