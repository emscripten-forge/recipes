def test_import_cvxpy():
    import cvxpy as cp

    assert isinstance(cp.__version__, str)
    assert cp.__version__.startswith("1.8.2")


def test_cvxcore_extension_loaded():
    # The C++ canonicalization backend is built by setup.py (not skipped as under PYODIDE).
    import _cvxcore  # noqa: F401


def test_cvxpy_clarabel():
    import cvxpy as cp

    P = [[3.0, 1.0, -1.0], [1.0, 4.0, 2.0], [-1.0, 2.0, 5.0]]
    q = [1.0, 2.0, -3.0]

    x = cp.Variable(3)
    constraints = [x[0] + x[1] - x[2] == 1, x[1] <= 2, x[2] <= 2, cp.SOC(x[0], x[1:])]
    obj = cp.Minimize(0.5 * cp.quad_form(x, P) + q @ x)

    prob = cp.Problem(obj, constraints)
    prob.solve(solver=cp.CLARABEL)
    assert prob.status == cp.OPTIMAL


def test_cvxpy_scipy():
    import cvxpy as cp

    q = [1.0, 2.0, -3.0]

    x = cp.Variable(3)
    constraints = [
        x[0] + x[1] - x[2] == 1,
        x[1] >= 2,
        x[2] <= 2,
    ]
    obj = cp.Minimize(q @ x)

    prob = cp.Problem(obj, constraints)
    prob.solve(solver=cp.SCIPY)
    assert prob.status == cp.OPTIMAL
