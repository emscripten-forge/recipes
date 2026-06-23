import pytest
import pyjs


def  test_numpy_testing():
    import numpy.testing as npt


def test_scikit_learn():
    print("1.1")
    import numpy as np
    import matplotlib
    # import scipy
    import scikitplot
    print("1.2")
    scikitplot.show_versions(mode="dict")

# def test_logistic_regression():
#     print("2.1")
#     from sklearn.datasets import load_iris
#     print("2.2")
#     from sklearn.linear_model import LogisticRegression
#     print("2.3")
#     X, y = load_iris(return_X_y=True)
#     print("2.4")
#     clf = LogisticRegression(random_state=0, max_iter=1000).fit(X, y)
#     print(clf.predict(X[:2, :]))
#     print("2.5")
#     print(clf.predict_proba(X[:2, :]))
#     print("2.6")
#     print(clf.score(X, y))



# skip_non_worker = pytest.mark.skipif(
#     not is_browser_worker,
#     reason="requires browser-worker, not node",
# )

# FIXME: downloading does not work, it is an issue from pyjs.
# Uncaught (in promise) TypeError: can't access property "buffer", handle is undefined
#    __emval_get_property http://localhost:9007/xeus/.../bin/xpython.js
# def test_dl():
#     from scikitplot.datasets import load_dataset
#     df = load_dataset("autoscout24")
#     df