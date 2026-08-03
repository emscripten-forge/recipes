import numpy as np
import qdldl
import scipy.sparse as spa
import scipy.sparse.linalg as sla


def test_import():
    assert qdldl is not None


def test_basic_solve():
    rng = np.random.default_rng(2)
    n = 5
    A = spa.random(n, n, density=0.8, random_state=rng, format="csc")
    M = (A @ A.T + spa.eye(n)).tocsc()
    b = rng.standard_normal(n)

    x_qdldl = qdldl.Solver(M).solve(b)
    x_scipy = sla.spsolve(M, b)

    np.testing.assert_allclose(x_qdldl, x_scipy, rtol=1e-5, atol=1e-5)


def test_scalar_solve():
    rng = np.random.default_rng(0)
    M = spa.csc_matrix([[float(rng.standard_normal())]])
    b = rng.standard_normal(1)

    x_qdldl = qdldl.Solver(M).solve(b)
    x_scipy = sla.spsolve(M, b)

    np.testing.assert_allclose(x_qdldl, x_scipy, rtol=1e-5, atol=1e-5)
