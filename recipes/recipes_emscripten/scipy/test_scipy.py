import numpy as np
from numpy.testing import assert_allclose


def test_import():
    import scipy
    print("scipy.__version__:", scipy.__version__)


def test_config():
    import scipy
    c = scipy.show_config(mode="dicts")

    assert c["Compilers"]["c"]["name"] == "emscripten"
    assert c["Compilers"]["c"]["commands"] == "emcc"

    assert c["Compilers"]["c++"]["name"] == "emscripten"
    assert c["Compilers"]["c++"]["commands"] == "em++"

    assert c["Compilers"]["fortran"]["name"] == "llvm-flang"
    assert c["Compilers"]["fortran"]["version"] == "20.1.7"


def test_cholesky():
    from scipy.linalg import cholesky
    a = np.array([[1, -2j], [2j, 5]])
    L = cholesky(a, lower=True)
    assert_allclose(L, [[1.+0.j, 0.+0.j], [0.+2.j, 1.+0.j]])
    assert_allclose(L @ L.conj(), [[1, 0], [0, 1]])


def test_delaunay():
    from scipy.spatial import Delaunay
    points = np.array([[0, 0], [0, 1.1], [1, 0], [1, 1]])
    tri = Delaunay(points)
    assert_allclose(tri.simplices, [[2, 3, 0],[3, 1, 0]])
    assert_allclose(tri.neighbors, [[1, -1, -1], [-1, 0, -1]])


def test_differentiate():
    from scipy.differentiate import derivative
    f = np.exp
    df = np.exp  # true derivative
    x = np.linspace(1, 2, 5)
    res = derivative(f, x)
    # Approximation of the derivative
    assert_allclose(res.df, [2.718281828, 3.490342957, 4.48168907 , 5.754602676, 7.389056099])
    # Estimate of the error
    assert all(res.error < 2e-11)


def test_eigh():
    from scipy.linalg import eigh
    rng = np.random.default_rng(seed=42)
    x = rng.random((5, 5)) - 0.5
    x = np.dot(x, x.T)  # Symmetric matrix
    evals, evecs = eigh(x)
    assert_allclose(evals, [0.038501249, 0.207864672, 0.302143167, 0.591284592, 1.048814273])


def test_integrate():
    import scipy.integrate as integrate
    def integrand(x, a, b):
        return a*x**2 + b
    res = integrate.quad(integrand, 0, 1, args=(2, 1))
    assert_allclose(res, [1.666666667, 1.850371708e-14])


def test_linalg():
    from scipy.linalg import inv
    Ainv = inv([[1,2],[3,4]])
    assert_allclose(Ainv, [[-2, 1], [1.5, -0.5]])


def test_lsoda():
    import scipy.integrate as integrate
    def exponential_decay(t, y):
        return -0.5 * y
    sol = integrate.solve_ivp(exponential_decay, [0, 10], [2, 4, 8], method="LSODA")
    assert_allclose(
        sol.t,
        [0, 0.062024821, 0.124049643, 0.458285574, 0.792521505, 1.126757437, 1.678003145, 2.229248854, 2.780494563, 3.331740272, 3.998992409, 4.666244546, 5.333496683, 6.00074882, 6.668000957, 7.335253093, 8.00250523, 8.669757367, 9.337009504, 10]
    )
    assert_allclose(
        sol.y,
        [
            [2, 1.939839064, 1.881487796, 1.591314435, 1.345925516, 1.138391324, 0.865131475, 0.656826895, 0.498564326, 0.378523424, 0.271259492, 0.194332522, 0.139215382, 0.099736933, 0.071452735, 0.051188968, 0.036672158, 0.026272231, 0.018821608, 0.013512558],
            [4, 3.879678129, 3.762975592, 3.182628871, 2.691851033, 2.276782647, 1.73026295 , 1.313653791, 0.997128652, 0.757046848, 0.542518984, 0.388665044, 0.278430763, 0.199473866, 0.142905471, 0.102377937, 0.073344316, 0.052544462, 0.037643216, 0.027025115],
            [8, 7.759356258, 7.525951184, 6.365257742, 5.383702066, 4.553565295, 3.4605259  , 2.627307582, 1.994257305, 1.514093696, 1.085037968, 0.777330087, 0.556861527, 0.398947731, 0.285810941, 0.204755873, 0.146688631, 0.105088924, 0.075286431, 0.05405023 ]
        ]
    )


def test_sparse():
    import scipy
    A = scipy.sparse.csc_array([[1, 0, 0.1], [0, 0.2, 0], [1, 0, 2]])
    Ainv = scipy.sparse.linalg.inv(A)
    assert_allclose(A.todense(), [[1, 0, 0.1], [0, 0.2, 0], [1, 0, 2]])
    assert_allclose(Ainv.todense(), [
        [1.052631579, 0, -0.052631579],
        [0, 5, 0],
        [-0.526315789, 0, 0.526315789]
    ])
    soln = scipy.sparse.linalg.spsolve(A, [1.1, 0.2, -0.3])
    assert_allclose(soln, [1.173684211, 1, -0.736842105])


def test_special():
    import scipy.special as special
    val = special.jv(2.5, 2.0)
    assert_allclose(val, 0.223924531)
