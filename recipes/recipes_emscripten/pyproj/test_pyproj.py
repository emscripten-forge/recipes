import math


def test_version():
    import pyproj
    assert pyproj.__proj_version__.startswith("9.")


def test_crs_from_epsg():
    from pyproj import CRS
    crs = CRS.from_epsg(4326)
    assert crs.is_geographic
    assert "WGS 84" in crs.name


def test_crs_from_wkt_roundtrip():
    from pyproj import CRS
    wkt = CRS.from_epsg(3857).to_wkt()
    assert CRS.from_wkt(wkt).to_epsg() == 3857


def test_transformer_wgs84_to_webmercator():
    from pyproj import Transformer
    t = Transformer.from_crs(4326, 3857, always_xy=True)
    x, y = t.transform(0.0, 0.0)
    assert abs(x) < 1e-6 and abs(y) < 1e-6
    x, y = t.transform(2.3522, 48.8566)
    assert math.isclose(x, 261848.15, rel_tol=1e-4)
    assert math.isclose(y, 6250566.72, rel_tol=1e-4)


def test_transformer_roundtrip():
    from pyproj import Transformer
    fwd = Transformer.from_crs(4326, 3857, always_xy=True)
    back = Transformer.from_crs(3857, 4326, always_xy=True)
    lon, lat = -122.4194, 37.7749
    x, y = fwd.transform(lon, lat)
    lon2, lat2 = back.transform(x, y)
    assert math.isclose(lon, lon2, abs_tol=1e-9)
    assert math.isclose(lat, lat2, abs_tol=1e-9)


def test_geod_wgs84_distance():
    from pyproj import Geod
    g = Geod(ellps="WGS84")
    _, _, dist = g.inv(-73.9857, 40.7484, 2.2945, 48.8584)
    assert math.isclose(dist, 5845209.47, rel_tol=1e-6)


def test_database_query():
    from pyproj.database import query_crs_info
    infos = query_crs_info(auth_name="EPSG", pj_types=["GEOGRAPHIC_2D_CRS"])
    codes = {info.code for info in infos}
    assert "4326" in codes


def test_list_enums():
    from pyproj.enums import ProjVersion, WktVersion
    assert ProjVersion.PROJ_5.value
    assert WktVersion.WKT2_2019.value
