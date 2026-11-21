def test_constraint_equivalence():
    from ppl import Constraint, Variable

    x = Variable(0)
    y = Variable(1)
    c = x + 3 * y == 1
    cc = Constraint(c)
    assert c.is_equivalent_to(cc)


def test_polyhedron_is_bounded():
    from ppl import C_Polyhedron, Constraint_System, Variable

    x = Variable(0)
    y = Variable(1)
    cs = Constraint_System()
    cs.insert(x >= 0)
    cs.insert(x <= 3)
    cs.insert(y >= 0)
    cs.insert(y <= 3)
    poly = C_Polyhedron(cs)
    assert not poly.is_empty()
    assert poly.is_bounded()
