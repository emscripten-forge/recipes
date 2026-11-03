def test_import():
    import pyscipopt
    import pyscipopt.scip  # noqa: F401


def test_solve_lp():
    from pyscipopt import Model

    model = Model()
    x = model.addVar("x")
    y = model.addVar("y")
    model.setObjective(x + y, sense="maximize")
    model.addCons(2 * x + y <= 10)
    model.addCons(x + 3 * y <= 15)
    model.optimize()

    assert model.getStatus() == "optimal"
    assert abs(model.getObjVal() - 7.0) < 1e-6
