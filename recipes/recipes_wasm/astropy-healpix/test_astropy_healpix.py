def test_import_astropy_healpix():
    """Test basic import of astropy_healpix package."""
    import astropy_healpix
    assert hasattr(astropy_healpix, '__version__')

def test_healpix_basic():
    """Test basic HEALPix functionality."""
    from astropy_healpix import HEALPix
    from astropy import units as u

    hp = HEALPix(nside=16, order='nested')
    assert hp.npix == 3072
    assert hp.pixel_resolution.unit == u.arcmin
