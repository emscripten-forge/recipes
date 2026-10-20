import pytest


def test_import():
    import shapely
    import shapely.lib  # native extension load


def test_array_construction_with_numpy():
    import numpy as np
    from shapely import points, get_coordinates

    coords = np.array([[0.0, 0.0], [1.0, 1.0], [2.0, 2.0]])
    pts = points(coords)
    assert len(pts) == 3

    roundtrip = get_coordinates(pts)
    assert roundtrip.shape == (3, 2)
    assert roundtrip.dtype == np.float64
    np.testing.assert_allclose(roundtrip, coords)


def test_predicates_and_measures_with_geos():
    from shapely import Point, Polygon

    square = Polygon([[0, 0], [1, 0], [1, 1], [0, 1]])
    assert square.is_valid
    assert square.contains(Point(0.5, 0.5))
    assert not square.contains(Point(2.0, 2.0))
    assert square.area == pytest.approx(1.0)
    assert square.length == pytest.approx(4.0)
    assert Point(0, 0).distance(Point(3, 4)) == pytest.approx(5.0)


def test_boolean_ops_with_geos():
    from shapely import Polygon

    a = Polygon([[0, 0], [2, 0], [2, 2], [0, 2]])
    b = Polygon([[1, 1], [3, 1], [3, 3], [1, 3]])
    assert a.intersection(b).area == pytest.approx(1.0)
    assert a.union(b).area == pytest.approx(7.0)
    assert a.difference(b).area == pytest.approx(3.0)


def test_buffer_and_simplify_with_geos():
    from shapely import Point, LineString

    buf = Point(0, 0).buffer(1.0, quad_segs=64)
    assert buf.area == pytest.approx(3.14159, rel=1e-3)

    line = LineString([(0, 0), (0.01, 0.5), (0, 1)])
    simplified = line.simplify(tolerance=0.1)
    assert len(list(simplified.coords)) == 2


def test_wkt_roundtrip_with_geos():
    from shapely import from_wkt, to_wkt, Polygon

    original = Polygon([[0, 0], [1, 0], [1, 1], [0, 1]])
    wkt = to_wkt(original)
    assert "POLYGON" in wkt
    parsed = from_wkt(wkt)
    assert parsed.equals(original)
