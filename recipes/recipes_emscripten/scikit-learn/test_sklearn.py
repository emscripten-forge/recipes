import pytest
import pyjs






def test_scikit_learn():
    import numpy as np
    import sklearn
    from sklearn.linear_model import LogisticRegression
    rng = np.random.RandomState(42)
    X = rng.rand(100, 20)
    y = rng.randint(5, size=100)
    estimator = LogisticRegression(solver='liblinear')
    estimator.fit(X, y)
    print(estimator.predict(X))
    estimator.score(X, y)


def test_logistic_regression():
    from sklearn.datasets import load_iris
    from sklearn.linear_model import LogisticRegression
    X, y = load_iris(return_X_y=True)
    clf = LogisticRegression(random_state=0).fit(X, y)
    print(clf.predict(X[:2, :]))
    print(clf.predict_proba(X[:2, :]))
    print(clf.score(X, y))



is_browser_worker = pyjs.js.Function('return typeof importScripts === "function"')()
skip_non_worker = pytest.mark.skipif(
    not is_browser_worker,
    reason="requires browser-worker, not node",
)


@skip_non_worker
def test_dl():
    from sklearn import datasets
    iris = datasets.fetch_california_housing()