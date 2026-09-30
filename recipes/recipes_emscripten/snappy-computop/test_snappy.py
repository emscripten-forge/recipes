"""Fast smoke tests for SnapPy.

SnapPy ships a large test suite (``python -m snappy.test``); this only checks
that the two compiled kernels load, that the censuses from snappy_manifolds are
readable and that the pieces SnapPy gets from cypari, FXrays, low_index and
spherogram work together.
"""

import pytest


def test_import_snappy():
    import snappy
    import snappy.SnapPy
    import snappy.SnapPyHP

    assert snappy.version() == '3.3.2'


def test_figure_eight_knot_complement():
    import snappy

    manifold = snappy.Manifold('m004')
    assert manifold.num_tetrahedra() == 2
    assert manifold.num_cusps() == 1
    assert manifold.solution_type() == 'all tetrahedra positively oriented'
    assert float(manifold.volume()) == pytest.approx(2.029883212819307,
                                                     abs=1e-9)


def test_high_precision_kernel():
    import snappy

    manifold = snappy.ManifoldHP('m004')
    assert float(manifold.volume()) == pytest.approx(2.029883212819307,
                                                     abs=1e-9)


def test_fundamental_group_and_homology():
    import snappy

    manifold = snappy.Manifold('m004')
    group = manifold.fundamental_group()
    assert group.num_generators() == 2
    assert str(manifold.homology()) == 'Z'


def test_census_lookup():
    # The censuses come from snappy_manifolds, read through sqlite3.
    import snappy

    names = [str(manifold) for manifold in snappy.OrientableCuspedCensus[:3]]
    assert names == ['m003(0,0)', 'm004(0,0)', 'm006(0,0)']

    assert 'm004(0,0)' in [str(m) for m in snappy.Manifold('m004').identify()]


def test_isometry_signature():
    # isometry_signature exercises the canonical retriangulation code, which
    # uses cypari for its interval arithmetic.
    import snappy

    assert snappy.Manifold('m004').isometry_signature() == 'cPcbbbiht'


def test_covers_uses_low_index():
    import snappy

    covers = snappy.Manifold('m004').covers(2)
    assert len(covers) == 1


def test_link_exterior_uses_spherogram():
    import spherogram

    exterior = spherogram.Link('4_1').exterior()
    assert exterior.num_tetrahedra() == 2
    assert float(exterior.volume()) == pytest.approx(2.029883212819307,
                                                     abs=1e-9)
