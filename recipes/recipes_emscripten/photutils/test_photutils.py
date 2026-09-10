def test_import_photutils():
    """Test basic import of photutils package."""
    import photutils
    assert hasattr(photutils, '__version__')

def test_import_modules():
    import photutils.aperture
    import photutils.background
    import photutils.centroids
    import photutils.datasets
    import photutils.detection
    import photutils.geometry
    import photutils.isophote
    import photutils.morphology
    import photutils.profiles
    import photutils.psf
    import photutils.psf.matching
    import photutils.segmentation
    import photutils.utils
