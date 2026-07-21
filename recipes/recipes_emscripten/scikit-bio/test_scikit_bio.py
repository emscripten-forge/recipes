def test_import():
    import skbio

    assert skbio.__version__


def test_distance_matrix():
    from skbio.stats.distance import DistanceMatrix

    dm = DistanceMatrix([[0.0, 0.3], [0.3, 0.0]], ids=["a", "b"])
    assert dm.shape == (2, 2)
    assert dm["a", "b"] == 0.3
