def test_import_regions():
    """Test basic import of regions package."""
    import regions
    assert hasattr(regions, '__version__')

def test_import_modules():
    """Test importing key regions modules."""
    import regions.core
    import regions.io
    import regions.shapes

def test_regions_basic():
    """Test basic regions functionality."""
    from regions import CirclePixelRegion, PixCoord

    center = PixCoord(x=10, y=20)
    region = CirclePixelRegion(center=center, radius=5)

    assert region.center.x == 10
    assert region.center.y == 20
    assert region.radius == 5
