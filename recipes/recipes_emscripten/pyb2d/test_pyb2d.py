
def test_pyb2d():

    import b2d
    assert b2d.BuildConfiguration.LIQUID_FUN
    import numpy as np

    world = b2d.world(gravity=(-9, 0))

    body = world.create_dynamic_body(
        position=(0, 0),
        fixtures=b2d.fixture_def(shape=b2d.circle_shape(radius=1), density=1),
    )

    t = 5
    fps = 40
    dt = 1.0 / fps
    n_steps = int(t / dt + 0.5)

    positions = np.zeros([n_steps, 2])
    velocites = np.zeros([n_steps, 2])
    timepoints = np.zeros([n_steps])

    t_elapsed = 0.0
    for i in range(n_steps):

        # get the bodies center of mass
        positions[i, :] = body.world_center

        # get the bodies velocity
        velocites[i, :] = body.linear_velocity

        timepoints[i] = t_elapsed

        world.step(time_step=dt, velocity_iterations=1, position_iterations=1)
        t_elapsed += dt
