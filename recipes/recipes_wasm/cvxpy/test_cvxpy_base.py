"""Tests for cvxpy-base, including the QDLDL path in sparse_cholesky."""

from unittest.mock import patch

import numpy as np
import qdldl
import scipy.sparse as sp

from cvxpy.utilities import linalg as lau


def test_cvxpy_base():
    # public interface is defined (see #75) to be the content of
    # https://github.com/cvxpy/cvxpy/blob/master/cvxpy/__init__.py
    import cvxpy  # noqa: F401


def test_import_qdldl():
    assert hasattr(qdldl, "Solver")


def _assert_chol_reconstructs(L, p, A, places=5):
    G = (L[p, :] @ L[p, :].T).toarray()
    np.testing.assert_allclose(G, A.toarray(), atol=10 ** (-places), rtol=10 ** (-places))


def test_sparse_cholesky_diagonal_uses_qdldl():
    rng = np.random.default_rng(0)
    A = sp.csc_array(np.diag(rng.random(4) + 0.1))

    with (
        patch("cvxpy.utilities.linalg.qdldl.Solver", wraps=qdldl.Solver) as mock_solver,
        patch("cvxpy.utilities.linalg._dense_ldl_factor") as mock_dense,
    ):
        sign, L, p = lau.sparse_cholesky(A, 0.0)

    mock_solver.assert_called()
    mock_dense.assert_not_called()
    assert sign == 1.0
    assert np.all(L.diagonal() > 0)
    _assert_chol_reconstructs(L, p, A)


def test_sparse_cholesky_tridiagonal_uses_qdldl():
    rng = np.random.default_rng(0)
    n = 5
    diag = rng.random(n) + 0.1
    offdiag = np.min(np.abs(diag)) * np.ones(n - 1) / 2
    A = sp.diags_array([offdiag, diag, offdiag], offsets=[-1, 0, 1])

    with (
        patch("cvxpy.utilities.linalg.qdldl.Solver", wraps=qdldl.Solver) as mock_solver,
        patch("cvxpy.utilities.linalg._dense_ldl_factor") as mock_dense,
    ):
        sign, L, p = lau.sparse_cholesky(A, 0.0)

    mock_solver.assert_called()
    mock_dense.assert_not_called()
    assert sign == 1.0
    _assert_chol_reconstructs(L, p, A)


def test_sparse_cholesky_spd_uses_qdldl():
    rng = np.random.default_rng(0)
    B = rng.standard_normal((3, 3))
    A = sp.csc_array(B @ B.T + np.eye(3))

    with (
        patch("cvxpy.utilities.linalg.qdldl.Solver", wraps=qdldl.Solver) as mock_solver,
        patch("cvxpy.utilities.linalg._dense_ldl_factor") as mock_dense,
    ):
        sign, L, p = lau.sparse_cholesky(A)

    mock_solver.assert_called()
    mock_dense.assert_not_called()
    assert sign == 1.0
    _assert_chol_reconstructs(L, p, A)


def test_sparse_cholesky_nsd_uses_qdldl():
    rng = np.random.default_rng(0)
    B = rng.standard_normal((3, 3))
    A = sp.csc_array(-(B @ B.T + np.eye(3)))

    with (
        patch("cvxpy.utilities.linalg.qdldl.Solver", wraps=qdldl.Solver) as mock_solver,
        patch("cvxpy.utilities.linalg._dense_ldl_factor") as mock_dense,
    ):
        sign, L, p = lau.sparse_cholesky(A)

    mock_solver.assert_called()
    mock_dense.assert_not_called()
    assert sign == -1.0
    _assert_chol_reconstructs(L, p, -A)


def test_quad_form_sparse_psd_uses_qdldl():
    """Higher-level path: decomp_quad -> sparse_cholesky -> qdldl."""
    from cvxpy.atoms.quad_form import decomp_quad

    rng = np.random.default_rng(1)
    B = rng.standard_normal((4, 4))
    P = sp.csc_array(B @ B.T + np.eye(4))

    with (
        patch("cvxpy.utilities.linalg.qdldl.Solver", wraps=qdldl.Solver) as mock_solver,
        patch("cvxpy.utilities.linalg._dense_ldl_factor") as mock_dense,
    ):
        scale, M1, M2 = decomp_quad(P)

    mock_solver.assert_called()
    mock_dense.assert_not_called()
    assert scale == 1.0
    assert M2.size == 0
    reconstructed = (M1 @ M1.T).toarray() if sp.issparse(M1) else M1 @ M1.T
    np.testing.assert_allclose(reconstructed, P.toarray(), atol=1e-5, rtol=1e-5)
