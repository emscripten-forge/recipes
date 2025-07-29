import pytest
from pytest import approx

import numpy as np
import pyb2d3 as b2d


joint_names = ["distance", "filter", "motor", "mouse", "prismatic", "revolute", "wheel"]


def test_world_cls():
    world = b2d.World(gravity=(0, -10), user_data=42)
    assert world.gravity == approx((0, -10))
    assert world.user_data == 42

    body = world.create_dynamic_body(position=(0, 0), user_data=100)
    assert body.user_data == 100
    body = world.create_static_body(position=(0, -10), user_data=200)
    assert body.user_data == 200
    body = world.create_kinematic_body(position=(0, 10), user_data=300)
    assert body.user_data == 300

    body_def = b2d.body_def(position=(0, 0))
    body_def.user_data = 100

    body = world.create_body(body_def)
    a = body.angle
    assert body.user_data == 100

    material = b2d.surface_material(friction=0.5, restitution=0.3)
    shape_def = b2d.shape_def(density=1, material=material, user_data=400)

    shapes = [b2d.make_box(1, 1), b2d.make_circle(radius=0.5)]

    for i in range(10):
        body = world.create_body(body_def)
        for shape in shapes:
            shape_id = body.create_shape(shape_def, shape)
            # assert shape_id.user_data == 400

    hl_shapes = body.create_shapes(shape_def, shapes)
