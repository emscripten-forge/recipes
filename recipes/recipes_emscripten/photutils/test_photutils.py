def test_import_photutils():
    """Test basic import of photutils package."""
    import photutils
    assert hasattr(photutils, '__version__')

def test_import_modules():
    # Modules that work (don't depend on astropy.nddata or scipy.sparse)
    import photutils.background
    import photutils.centroids
    import photutils.detection
    import photutils.geometry
    import photutils.isophote
    import photutils.morphology
    import photutils.profiles
    import photutils.psf
    import photutils.psf.matching
    import photutils.segmentation

    # Modules that fail: they import astropy.nddata which imports scipy.sparse
    # scipy.sparse triggers broken scipy._lib._ccallback_c.cpython-313-wasm32-emscripten.so
    # Error: bad export type for 'timing_': undefined
    #
    # import photutils.aperture  # Uses astropy.nddata via aperture.core
    # import photutils.datasets  # Uses astropy.nddata
    # import photutils.utils     # Uses astropy.nddata via utils.cutouts
