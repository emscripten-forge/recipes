import pytest


def test_import_spiceypy():
    import spiceypy
    import spiceypy.cyice


def test_toolkit_version():
    import spiceypy as spice

    assert spice.tkvrsn("TOOLKIT") == "CSPICE_N0067"


def test_ctypes_basics():
    import numpy as np
    import spiceypy as spice

    assert spice.pi() == pytest.approx(np.pi)
    assert spice.spd() == 86400.0
    np.testing.assert_allclose(spice.vadd([1.0, 2.0, 3.0], [4.0, 5.0, 6.0]), [5.0, 7.0, 9.0])
    assert spice.convrt(1.0, "KM", "M") == pytest.approx(1000.0)


def test_cyice_basics():
    from spiceypy import cyice

    assert cyice.b1900() == pytest.approx(2415020.31352)
    assert cyice.dpr() == pytest.approx(57.29577951308232)
    assert cyice.convrt(1.0, "KM", "M") == pytest.approx(1000.0)


def test_spice_error():
    import spiceypy as spice
    from spiceypy.utils.exceptions import SpiceyError

    with pytest.raises(SpiceyError):
        spice.furnsh("/does/not/exist.bsp")
    spice.reset()
