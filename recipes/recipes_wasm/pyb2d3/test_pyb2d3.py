import math

import numpy as np
import pytest
from pytest import approx

import pyb2d3 as b2d


joint_names = ["distance", "filter", "motor", "mover", "pogo", "prismatic", "revolute", "weld", "wheel"]


def test_import():
    assert b2d.get_version().major == 3
    assert b2d.get_version().minor >= 2


def test_world_cls():
    world = b2d.World(gravity=(0, -10), user_data=42)
    assert world.gravity.x == approx(0)
    assert world.gravity.y == approx(-10)
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
    assert body.user_data == 100

    material = b2d.surface_material(friction=0.5, restitution=0.3)
    shape_def = b2d.shape_def(density=1, material=material, user_data=400)

    shapes = [b2d.box(1, 1), b2d.circle(radius=0.5)]

    for i in range(10):
        body = world.create_body(body_def)
        for shape in shapes:
            shape_id = body.create_shape(shape_def, shape)
            assert shape_id.user_data == 400


def test_falling_body():
    world = b2d.World(gravity=(0, -10))
    ground = world.create_static_body(position=(0, -1))
    ground.create_shape(b2d.shape_def(), b2d.box(50, 1))

    body = world.create_dynamic_body(position=(0, 4))
    body.create_shape(b2d.shape_def(density=1), b2d.box(0.5, 0.5))

    for _ in range(240):
        world.step(1 / 60, 4)

    # resting on the ground (top at y=0, half extent 0.5)
    assert body.position.y == approx(0.5, abs=0.05)


@pytest.mark.parametrize("joint_name", joint_names)
def test_joints(joint_name):
    cls_name = f"{joint_name.capitalize()}Joint"
    joint_cls = getattr(b2d, cls_name)
    world_func = getattr(b2d.World, f"create_{joint_name}_joint")

    world = b2d.World(gravity=(0, -10))
    factory = world.body_factory()
    factory.dynamic().shape(density=1).add_box(1, 1)
    body_a = factory.position((0, 0)).create()
    body_b = factory.position((2, 0)).create()

    joint = world_func(world, body_a, body_b)

    assert isinstance(joint, joint_cls)
    assert joint.body_a == body_a
    assert joint.body_b == body_b

    world.step(1 / 60, 4)
    assert joint.is_valid


def test_joint_local_frame():
    # box2d 3.2: joints are defined by local frames
    world = b2d.World(gravity=(0, 0))
    body_a = world.create_static_body(position=(0, 0))
    body_b = world.create_dynamic_body(position=(0, 0))
    body_b.create_shape(b2d.shape_def(density=1), b2d.box(0.5, 0.5))

    frame = b2d.transform(p=(1, 2), q=0.25 * math.pi)
    joint = world.create_revolute_joint(body_a=body_a, body_b=body_b, local_frame_a=frame)
    assert joint.local_frame_a.p.x == approx(1)
    assert joint.local_frame_a.p.y == approx(2)


def test_batch_api():
    world = b2d.World(gravity=(0, -10))
    bodies = b2d.Bodies()
    for i in range(10):
        body = world.create_dynamic_body(position=(i, 0))
        body.create_shape(b2d.shape_def(density=1), b2d.circle(radius=0.5))
        bodies.append(body)

    positions = bodies.position
    assert positions.shape == (10, 2)
    assert positions[:, 0] == approx(np.arange(10))

    world.step(1 / 60, 4)
    assert np.all(bodies.position[:, 1] < 0)


def test_snapshot():
    world = b2d.World(gravity=(0, -10))
    body = world.create_dynamic_body(position=(0, 4))
    body.create_shape(b2d.shape_def(density=1), b2d.box(0.5, 0.5))
    world.step(1 / 60, 4)

    image = world.get_snapshot()
    assert isinstance(image, bytes) and len(image) > 0
    saved = tuple(body.position)

    for _ in range(30):
        world.step(1 / 60, 4)
    assert tuple(body.position) != approx(saved)

    assert world.restore_from_snapshot(image)
    assert tuple(body.position) == approx(saved)
