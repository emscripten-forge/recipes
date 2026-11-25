def test_import_reproject():
    """Test basic import of reproject package."""
    import reproject
    assert hasattr(reproject, '__version__')

def test_import_modules():
    """Test importing reproject submodules."""
    import reproject.healpix
    import reproject.interpolation
    import reproject.spherical_intersect
