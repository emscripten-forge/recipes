import numpy as np


def test_import():
    import dtks


def test_ant_simulation():
    import dtks

    p = dtks.Parameters()
    p.n_ants = 50
    p.seed = 42
    assert p.n_ants == 50

    sim = dtks.AntSimulation(p)
    for _ in range(10):
        sim.step()

    food = sim.food_map()
    nest = sim.nest_map()
    land = sim.is_land()
    assert food.ndim == 2 and food.dtype == np.uint8
    assert nest.shape == food.shape
    assert land.shape == food.shape

    img = np.zeros(food.shape + (4,), dtype=np.uint8)
    sim.draw(img)
    assert img.any()
