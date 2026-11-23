def test_import_reboundx():
    import reboundx

    assert reboundx.__version__ == "5.1.0"


def test_modifymass():
    import numpy
    import rebound
    import reboundx

    sim = rebound.Simulation()
    sim.add(m=1.0)
    sim.add(a=1.0)
    sim.integrator = "whfast"
    rebx = reboundx.Extras(sim)
    mm = rebx.load_operator("modify_mass")
    rebx.add_operator(mm)
    sim.particles[0].params["tau_mass"] = -1000
    sim.integrate(10.0)

    assert numpy.fabs(sim.particles[0].m - 0.9900498312740409) < 1e-10, (
        "Modify mass module in REBOUNDx is not working"
    )
