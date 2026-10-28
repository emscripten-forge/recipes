
def test_import_pyerfa():
    import erfa


def test_pyerfa_version():
    import erfa
    assert erfa.__version__ != "0.0.0"


def test_pyerfa_ufunc():
    import numpy as np
    import erfa

    # J2000.0 epoch
    iy, im, id, fd = erfa.jd2cal(2451545.0, 0.0)
    assert (iy, im, id) == (2000, 1, 1)
    assert np.isclose(fd, 0.5)

    jd1, jd2 = erfa.cal2jd(np.array([2000, 2024]), 1, 1)
    assert np.allclose(jd1 + jd2, [2451544.5, 2460310.5])
