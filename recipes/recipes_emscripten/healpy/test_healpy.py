import os
import tempfile

import numpy as np


def test_nside2npix():
    import healpy

    assert healpy.nside2npix(32) == 12288


def test_ang2pix_pix2ang_roundtrip():
    import healpy

    nside = 8
    pixels = np.arange(healpy.nside2npix(nside))
    theta, phi = healpy.pix2ang(nside, pixels)
    assert np.array_equal(healpy.ang2pix(nside, theta, phi), pixels)


def test_query_disc():
    import healpy

    nside = 64
    vec = healpy.ang2vec(np.pi / 2, 0.0)
    pixels = healpy.query_disc(nside, vec, np.radians(5.0))
    assert len(pixels) > 0
    theta, phi = healpy.pix2ang(nside, pixels)
    centers = healpy.ang2vec(theta, phi)
    assert np.all(np.dot(centers, vec) > np.cos(np.radians(10.0)))


def test_map2alm_alm2map_roundtrip():
    import healpy

    nside = 16
    lmax = 3 * nside - 1
    npix = healpy.nside2npix(nside)
    m = np.ones(npix)
    alm = healpy.map2alm(m, lmax=lmax, iter=10)
    # A constant map has all power in the l=0 harmonic: a00 = sqrt(4*pi).
    assert np.isclose(alm[0].real, np.sqrt(4 * np.pi), rtol=1e-6)
    back = healpy.alm2map(alm, nside=nside)
    dev = np.abs(back - 1.0).max()
    assert dev < 1e-3, f"max deviation {dev}"


def test_write_read_map():
    import healpy

    nside = 16
    m = np.arange(healpy.nside2npix(nside), dtype=np.float64)
    with tempfile.TemporaryDirectory() as tmpdir:
        fname = os.path.join(tmpdir, "map.fits")
        healpy.write_map(fname, m, overwrite=True)
        read = healpy.read_map(fname)
    assert np.array_equal(read, m)
