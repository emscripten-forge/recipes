# def test_scipy_linalg():
#     import scipy.linalg


#     N = 10
#     X = np.random.RandomState(42).rand(N, N)

#     X_inv = scipy.linalg.inv(X)

#     res = X.dot(X_inv)

#     assert_allclose(res, np.identity(N), rtol=1e-07, atol=1e-9)


def test_brentq():
    from scipy.optimize import brentq

    brentq(lambda x: x, -1, 1)

def test_dlamch():
    from scipy.linalg import lapack
    print(lapack.dlamch("Epsilon-Machine"))

def test_binom_ppf():
    from scipy.stats import binom

    assert binom.ppf(0.9, 1000, 0.1) == 112.0