
def test_import_rebound():
    import rebound


def test_rebound_simulation():
    import rebound

    sim = rebound.Simulation()
    sim.add(m=1.0)
    sim.add(m=1.0e-3, a=1.0)
    sim.integrate(100.0)

    assert sim.N == 2
    orbit = sim.particles[1].orbit(primary=sim.particles[0])
    assert abs(orbit.a - 1.0) < 0.01
