import highspy


def test_import_highspy():
    assert highspy.__name__ == "highspy"
    assert hasattr(highspy, "Highs")


def test_version():
    h = highspy.Highs()
    assert h.version() == "1.16.0"


def test_minimize_free_variables():
    # minimize x2 s.t. x2 - x1 >= 2, x1 + x2 >= 0  ->  optimum x1 = -1, x2 = 1
    h = highspy.Highs()
    h.silent()
    x1 = h.addVariable(lb=-h.inf)
    x2 = h.addVariable(lb=-h.inf)
    h.addConstrs(x2 - x1 >= 2, x1 + x2 >= 0)
    h.minimize(x2)
    assert abs(h.val(x1) - (-1.0)) < 1e-6
    assert abs(h.val(x2) - 1.0) < 1e-6


def test_maximize_bounded_lp():
    # maximize x + y s.t. x + 2y <= 4, x <= 3, x, y >= 0  ->  optimum 3.5 at (3, 0.5)
    h = highspy.Highs()
    h.silent()
    x = h.addVariable(lb=0, ub=3)
    y = h.addVariable(lb=0)
    h.addConstr(x + 2 * y <= 4)
    h.maximize(x + y)
    assert abs(h.val(x) - 3.0) < 1e-6
    assert abs(h.val(y) - 0.5) < 1e-6
    assert abs(h.getInfo().objective_function_value - 3.5) < 1e-6


def test_binary_knapsack():
    # maximize 3a + 4b + 5c s.t. 2a + 3b + 4c <= 5  ->  optimum 7 at a = b = 1, c = 0
    h = highspy.Highs()
    h.silent()
    a, b, c = h.addBinaries(3, obj=0)
    h.addConstr(2 * a + 3 * b + 4 * c <= 5)
    h.maximize(3 * a + 4 * b + 5 * c)
    assert round(h.val(a)) == 1
    assert round(h.val(b)) == 1
    assert round(h.val(c)) == 0
    assert abs(h.getInfo().objective_function_value - 7.0) < 1e-6
