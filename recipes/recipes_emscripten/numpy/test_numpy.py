import numpy as np
from numpy.testing import assert_allclose


def test_numpy():
    ones = np.ones(shape=[2, 3])
    assert ones.shape == (2, 3)


def test_openblas_build_config():
    cfg = np.show_config(mode="dicts")
    blas = cfg["Build Dependencies"]["blas"]
    lapack = cfg["Build Dependencies"]["lapack"]
    assert blas["found"] is True
    assert lapack["found"] is True
    # scipy-openblas.pc alias is used to bypass Meson's OpenBLAS factory.
    assert "openblas" in blas["name"]
    assert "openblas configuration" in blas
    assert blas["openblas configuration"] != "unknown"


# Large enough that OpenBLAS blocked kernels are exercised (not tiny fallbacks).
N = 300


def test_blas_matmul():
    rng = np.random.default_rng(0)
    a = rng.standard_normal((N, N))
    b = rng.standard_normal((N, N))
    c = a @ b
    assert c.shape == (N, N)
    assert_allclose(c, np.dot(a, b))
    assert_allclose(c.T, b.T @ a.T)


def test_lapack_cholesky():
    rng = np.random.default_rng(1)
    x = rng.standard_normal((N, N))
    a = x @ x.T + N * np.eye(N)
    l = np.linalg.cholesky(a)
    assert_allclose(l @ l.T, a)


def test_lapack_solve():
    rng = np.random.default_rng(2)
    a = rng.standard_normal((N, N))
    b = rng.standard_normal(N)
    x = np.linalg.solve(a, b)
    assert_allclose(a @ x, b)


def test_lapack_eigh():
    rng = np.random.default_rng(3)
    x = rng.standard_normal((N, N))
    a = x @ x.T
    evals, evecs = np.linalg.eigh(a)
    assert evals.shape == (N,)
    assert evecs.shape == (N, N)
    assert_allclose(evecs.T @ evecs, np.eye(N), atol=1e-8)
    assert_allclose(evecs @ np.diag(evals) @ evecs.T, a)


def test_c_test_extensions():
    # Built with meson install_tag=tests: NumPy's C test helpers.
    from numpy._core import _multiarray_tests, _umath_tests

    assert hasattr(_multiarray_tests, "test_neighborhood_iterator")
    assert hasattr(_umath_tests, "test_dispatch")


def test_numpy_c_and_linalg_suite():
    # numpy._core.tests is the C-extension suite (_multiarray_tests, _umath_tests).
    # numpy.linalg.tests exercises the OpenBLAS/LAPACK symbols NumPy links.
    assert np.test(
        label="fast",
        extra_argv=["--tb=short"],
        tests=["numpy._core", "numpy.linalg"],
    ), "NumPy _core / linalg tests failed"
