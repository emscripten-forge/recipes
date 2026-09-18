import pytest


def test_import_snappy():
    import snappy
    import snappy.SnapPy
    import snappy.SnapPyHP


def test_figure_eight_knot_complement():
    import snappy

    M = snappy.Manifold("m004")
    assert M.num_tetrahedra() == 2
    assert M.num_cusps() == 1
    assert float(M.volume()) == pytest.approx(2.029883212819307, abs=1e-9)
