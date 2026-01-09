import pytest


def test_logistic_regression():
    import numpy as np
    from numpy.testing import assert_allclose
    import sklearn
    from sklearn.linear_model import LogisticRegression
    rng = np.random.RandomState(42)
    X = rng.rand(100, 20)
    y = rng.randint(5, size=100)
    estimator = LogisticRegression(solver='newton-cholesky')
    estimator.fit(X, y)
    p = estimator.predict(X)
    assert_allclose(p, [
        0, 2, 1, 1, 1, 1, 4, 3, 4, 4, 0, 1, 3, 1, 1, 0, 0, 4, 4, 1, 0, 3, 4, 1, 0, 4, 1, 3, 3,
        0, 1, 1, 4, 1, 0, 1, 1, 1, 4, 1, 2, 0, 4, 0, 0, 4, 0, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 3,
        1, 1, 2, 3, 0, 0, 0, 1, 0, 1, 1, 4, 1, 0, 1, 1, 1, 4, 0, 1, 4, 1, 1, 3, 1, 0, 4, 3, 1,
        0, 1, 1, 3, 3, 0, 0, 1, 1, 3, 1, 0, 1
    ])
    s = estimator.score(X, y)
    assert_allclose(s, 0.57)


def test_fetch():
    from sklearn import datasets
    ds = datasets.fetch_california_housing()
    assert ds['data'].shape == (20640, 8)
    assert ds['target'].shape == (20640,)


def test_pairwise_distance():
    from numpy.testing import assert_allclose
    from sklearn.metrics.pairwise import pairwise_distances
    x = [[0, 0, 0], [1, 1, 1]]
    y = [[1, 0, 0], [1, 1, 0]]
    d = pairwise_distances(x, y, metric='sqeuclidean')
    assert_allclose(d, [[1.0, 2.0], [2.0, 1.0]])


def test_factor_analysis():
    from numpy.testing import assert_allclose
    from sklearn.datasets import load_iris
    from sklearn.decomposition import PCA, FactorAnalysis
    from sklearn.preprocessing import StandardScaler

    data = load_iris()
    X = StandardScaler().fit_transform(data["data"])
    feature_names = data["feature_names"]

    n_components = 2
    pca = PCA(n_components).fit(X)
    fa_unrotated = FactorAnalysis(n_components).fit(X)
    fa_rotated = FactorAnalysis(n_components, rotation="varimax").fit(X)

    assert_allclose(pca.components_, [
        [0.52106591, -0.26934744, 0.580413096, 0.564856546],
        [0.3774176, 0.92329566, 0.024491609, 0.066941987]
    ])
    assert_allclose(fa_unrotated.components_, [
        [0.880960087, -0.416916045, 0.99918858, 0.96228895],
        [-0.447286896, -0.55390036, 0.019152833, 0.058402058]
    ])
    assert_allclose(fa_rotated.components_, [
        [0.98633022, -0.16052385, 0.90809432, 0.85857475],
        [-0.057523335, -0.67443065, 0.41726413, 0.43847489]
    ])
