import pytest
import pyjs


def  test_numpy_testing():
    import numpy.testing as npt


# @pytest.mark.skip(reason="failing since scipy build is broken atm")
def test_scikit_learn():
    print("1.1")
    import numpy as np
    import sklearn
    from sklearn.linear_model import LogisticRegression
    print("1.2")
    rng = np.random.RandomState(42)
    X = rng.rand(100, 20)
    y = rng.randint(5, size=100)
    print("1.3")
    estimator = LogisticRegression(solver='liblinear')
    print("1.4")
    estimator.fit(X, y)
    print(estimator.predict(X))
    estimator.score(X, y)
    print("1.5")

# @pytest.mark.skip(reason="failing since scipy build is broken atm")
def test_logistic_regression():
    print("2.1")
    from sklearn.datasets import load_iris
    print("2.2")
    from sklearn.linear_model import LogisticRegression
    print("2.3")
    X, y = load_iris(return_X_y=True)
    print("2.4")
    # clf = LogisticRegression(random_state=0).fit(X, y)
    # print(clf.predict(X[:2, :]))
    # print("2.5")
    # print(clf.predict_proba(X[:2, :]))
    # print("2.6")
    # print(clf.score(X, y))



# is_browser_worker = pyjs.js.Function('return typeof importScripts === "function"')()
# skip_non_worker = pytest.mark.skipif(
#     not is_browser_worker,
#     reason="requires browser-worker, not node",
# )

# @pytest.mark.skip(reason="failing since scipy build is broken atm")
def test_dl():
    from sklearn import datasets
    iris = datasets.fetch_california_housing()