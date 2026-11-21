import numpy as np


def test_lightgbm_regression():
    import lightgbm as lgb

    rng = np.random.default_rng(0)
    X = rng.random((500, 4))
    y = 3.0 * X[:, 0] + np.sin(5 * X[:, 1])

    model = lgb.LGBMRegressor(n_estimators=50, learning_rate=0.1, num_leaves=15, verbose=-1)
    model.fit(X, y)
    pred = model.predict(X)

    assert pred.shape == y.shape
    assert np.mean((pred - y) ** 2) < 0.1


def test_lightgbm_version():
    import lightgbm as lgb

    assert lgb.__version__ == "4.7.0"
