import numpy as np
import xgboost as xgb


def _make_classification_data(n_per_class=60, n_classes=3, seed=0):
    rng = np.random.RandomState(seed)
    X, y = [], []
    for c in range(n_classes):
        X.append(rng.normal(loc=3.0 * c, scale=0.5, size=(n_per_class, 4)))
        y.append(np.full(n_per_class, c))
    return np.vstack(X), np.concatenate(y).astype(np.float32)


def test_import_version():
    assert isinstance(xgb.__version__, str)
    assert xgb.__version__.startswith("2.1")


def test_compat_lazy_isinstance():
    from xgboost.compat import lazy_isinstance

    a = np.array([1, 2, 3])
    assert lazy_isinstance(a, "numpy", "ndarray")
    assert not lazy_isinstance(a, "numpy", "dataframe")


def test_multiclass_classification():
    X, y = _make_classification_data()
    dtrain = xgb.DMatrix(X, label=y)
    params = {
        "objective": "multi:softmax",
        "num_class": 3,
        "eta": 0.3,
        "max_depth": 3,
        "nthread": 1,
    }
    bst = xgb.train(params, dtrain, num_boost_round=10)
    pred = bst.predict(dtrain)
    error_rate = np.sum(pred != y) / y.shape[0]
    assert error_rate < 0.05


def test_multiclass_probabilities():
    X, y = _make_classification_data()
    dtrain = xgb.DMatrix(X, label=y)
    params = {
        "objective": "multi:softprob",
        "num_class": 3,
        "eta": 0.3,
        "max_depth": 3,
        "nthread": 1,
    }
    bst = xgb.train(params, dtrain, num_boost_round=10)
    probs = bst.predict(dtrain).reshape(y.shape[0], 3)
    np.testing.assert_allclose(probs.sum(axis=1), 1.0, rtol=1e-5)
    assert np.mean(np.argmax(probs, axis=1) == y) > 0.95


def test_regression():
    rng = np.random.RandomState(1)
    X = rng.uniform(-1.0, 1.0, size=(200, 3))
    y = 2.0 * X[:, 0] - X[:, 1] + 0.5 * X[:, 2]
    dtrain = xgb.DMatrix(X, label=y)
    params = {"objective": "reg:squarederror", "eta": 0.3, "max_depth": 4, "nthread": 1}
    bst = xgb.train(params, dtrain, num_boost_round=50)
    pred = bst.predict(dtrain)
    rmse = np.sqrt(np.mean((pred - y) ** 2))
    assert rmse < 0.1


def test_model_roundtrip():
    X, y = _make_classification_data()
    dtrain = xgb.DMatrix(X, label=y)
    params = {"objective": "multi:softmax", "num_class": 3, "nthread": 1}
    bst = xgb.train(params, dtrain, num_boost_round=5)
    raw = bst.save_raw("json")

    loaded = xgb.Booster()
    loaded.load_model(bytearray(raw))
    np.testing.assert_array_equal(bst.predict(dtrain), loaded.predict(dtrain))
