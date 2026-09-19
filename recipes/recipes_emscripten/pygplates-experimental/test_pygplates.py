"""Functional smoke tests for pygplates under emscripten/wasm.

Exercises key primitives without needing external data files:
  - version + import
  - PointOnSphere geometry + lat/lon roundtrip
  - MultiPointOnSphere
  - Feature / FeatureCollection model
  - Great-circle distance math

Kept small enough to be a fast browser-side smoke test; more thorough
coverage lives in pygplates' own upstream test suite.
"""

import math

import pytest


def test_import_and_version():
    import pygplates
    assert hasattr(pygplates, "__version__")
    assert pygplates.__version__


def test_point_on_sphere_lat_lon_roundtrip():
    import pygplates
    p = pygplates.PointOnSphere(45.0, 100.0)
    lat, lon = p.to_lat_lon()
    assert math.isclose(lat, 45.0, abs_tol=1e-9)
    assert math.isclose(lon, 100.0, abs_tol=1e-9)


def test_point_on_sphere_pole_and_equator():
    import pygplates
    north = pygplates.PointOnSphere(90.0, 0.0)
    equator = pygplates.PointOnSphere(0.0, 0.0)
    lat_n, _ = north.to_lat_lon()
    lat_e, lon_e = equator.to_lat_lon()
    assert math.isclose(lat_n, 90.0, abs_tol=1e-9)
    assert math.isclose(lat_e, 0.0, abs_tol=1e-9)
    assert math.isclose(lon_e, 0.0, abs_tol=1e-9)


def test_multi_point_on_sphere():
    import pygplates
    pts = [
        pygplates.PointOnSphere(0.0, 0.0),
        pygplates.PointOnSphere(10.0, 20.0),
        pygplates.PointOnSphere(-30.0, 45.0),
    ]
    mp = pygplates.MultiPointOnSphere(pts)
    assert len(list(mp)) == 3


def test_feature_geometry_roundtrip():
    import pygplates
    p = pygplates.PointOnSphere(10.0, 20.0)
    feature = pygplates.Feature()
    feature.set_geometry(p)
    got = feature.get_geometry()
    assert got is not None
    lat, lon = got.to_lat_lon()
    assert math.isclose(lat, 10.0, abs_tol=1e-9)
    assert math.isclose(lon, 20.0, abs_tol=1e-9)


def test_feature_collection_iteration():
    import pygplates
    features = [pygplates.Feature() for _ in range(3)]
    for i, f in enumerate(features):
        f.set_geometry(pygplates.PointOnSphere(float(i * 10), 0.0))
    fc = pygplates.FeatureCollection(features)
    collected = list(fc)
    assert len(collected) == 3


def test_great_circle_arc_length():
    import pygplates
    # Quarter-arc: equator (0, 0) to (0, 90) - should span pi/2 radians.
    start = pygplates.PointOnSphere(0.0, 0.0)
    end = pygplates.PointOnSphere(0.0, 90.0)
    arc = pygplates.GreatCircleArc(start, end)
    assert math.isclose(arc.get_arc_length(), math.pi / 2, rel_tol=1e-6)
