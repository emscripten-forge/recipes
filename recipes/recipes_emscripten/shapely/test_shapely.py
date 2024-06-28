import pytest


def test_import():
  import shapely

def test_basics():
  from shapely import Polygon
  c = Polygon([[0, 0], [1, 0], [1, 1], [0, 1], [0, 0]]).minimum_clearance
  c == pytest.approx(1.0)
  
