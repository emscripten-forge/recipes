

def test_import():
    import pyomo



def test_simple_model():
    import pyomo.environ as pyo

    model = pyo.ConcreteModel()

    model.x = pyo.Var([1,2], domain=pyo.NonNegativeReals)

    model.OBJ = pyo.Objective(expr = 2*model.x[1] + 3*model.x[2])

    model.Constraint1 = pyo.Constraint(expr = 3*model.x[1] + 4*model.x[2] >= 1)