import b2d

def n_bodies(world):
    return len(list(world.bodies))

def n_joints(world):
    return len(list(world.joints))

# check that the world does not crash when doing steps
def do_test_step(world, draw_debug_data=False):
    for i in range(10):
        world.step(0.1, velocity_iterations=2, position_iterations=2)
        if draw_debug_data:
            world.draw_debug_data()