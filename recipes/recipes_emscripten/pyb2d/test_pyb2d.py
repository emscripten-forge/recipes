import pytest
import numpy as np
import pyb2d as b2d


@pytest.fixture
def world_id():
    world_def = b2d.world_def(gravity=(0, -10))
    world_id = b2d.create_world(world_def)
    yield world_id
    b2d.destroy_world(world_id)



def test_world():
    world_def = b2d.world_def(gravity=(0, -10), user_data=42)
    world_id = b2d.create_world(world_def)
    world_user_data = b2d.world_get_user_data(world_id)
    assert world_user_data == 42
    b2d.destroy_world(world_id)


def test_hello_world(world_id):

    # create static ground body
    body_def = b2d.body_def(position=(0, -10), type=b2d.BodyType.STATIC, user_data=10)
    assert body_def.user_data == 10
    groud_body_id = b2d.create_body(world_id, body_def)
    body_user_data = b2d.body_get_user_data(groud_body_id)
    assert body_user_data == 10
    box = b2d.make_box(1, 1)

    # surface material
    surface_material = b2d.surface_material(
        friction=0.3, restitution=0.5, rolling_resistance=0.3
    )

    # shape definition
    shape_def = b2d.shape_def(density=0, material=surface_material, user_data=100)
    shape_id = b2d.create_polygon_shape(groud_body_id, shape_def, box)
    shape_user_data = b2d.shape_get_user_data(shape_id)
    assert shape_user_data == 100

    # create dynamic body
    body_def = b2d.body_def(
        position=(0, 4),
        type=b2d.BodyType.DYNAMIC,
        angular_damping=0.1,
        linear_damping=0.1,
        fixed_rotation=False,
    )
    dynamic_body_id = b2d.create_body(world_id, body_def)
    circle = b2d.circle(radius=0.5)
    surface_material = b2d.surface_material(friction=0.3, restitution=0.5)
    shape_def = b2d.shape_def(density=1, material=surface_material, user_data=0)
    shape_id = b2d.create_circle_shape(dynamic_body_id, shape_def, circle)

    body_user_data = b2d.body_get_user_data(dynamic_body_id)
    assert body_user_data == 0

    # create debug draw
    debug_draw = DebugDrawTest()
    debug_draw.draw_shapes = True
    debug_draw.draw_joints = True
    debug_draw.draw_joint_extras = True

    # simulate
    pos_inital = b2d.body_get_position(dynamic_body_id)
    for i in range(60):
        b2d.world_step(world_id, 1 / 60, 6)
        pos = b2d.body_get_position(dynamic_body_id)
        b2d.world_draw(world_id, debug_draw)

    assert pos[1] < pos_inital[1]
