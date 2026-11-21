import numpy as np


def test_import_sisl():
    import sisl

    assert isinstance(sisl.__version__, str)
    assert sisl.__version__


def test_graphene_geometry():
    import sisl

    geom = sisl.geom.graphene()
    assert geom.na == 2
    assert geom.xyz.shape == (2, 3)


def test_graphene_tight_binding_gamma():
    import sisl

    # Nearest-neighbour hopping t = -2.7 on graphene: at Gamma the three
    # neighbour phases add up to 3, so the bands are at +-3|t| = +-8.1.
    H = sisl.Hamiltonian(sisl.geom.graphene())
    H.construct([(0.1, 1.44), (0.0, -2.7)])
    eig = np.sort(H.eigh(k=[0.0, 0.0, 0.0]))
    np.testing.assert_allclose(eig, [-8.1, 8.1], atol=1e-8)


def test_geometry_construction():
    import sisl

    geom = sisl.Geometry(
        xyz=[[0.0, 0.0, 0.0], [0.0, 0.0, 1.0]],
        atoms=sisl.Atom(Z=1, R=1.5),
        lattice=sisl.Lattice([5.0, 5.0, 5.0]),
    )
    assert geom.na == 2
    np.testing.assert_allclose(geom.distance(0, 1), 1.0)
