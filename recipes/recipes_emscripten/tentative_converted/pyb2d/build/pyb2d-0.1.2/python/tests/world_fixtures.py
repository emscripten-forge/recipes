import b2d

import pytest
from pytest_lazyfixture import sorted_by_dependency, lazy_fixture, _sorted_argnames,LazyFixture

from .joint_fixtures import *
from . common import *

@pytest.fixture
def circle_fixture():
    return b2d.fixture_def(shape=b2d.circle_shape(radius=1), density=1, friction=0.5)

# Arrange
@pytest.fixture
def world():
    return b2d.world(gravity=b2d.vec2(0,-10))


@pytest.fixture
def two_body_world(world, circle_fixture):
    assert n_bodies(world) == 0
    body_a = world.create_dynamic_body(position=(0, 0),fixtures=circle_fixture, angular_damping=0.5, linear_damping=0.5)
    body_b = world.create_dynamic_body(position=(2, 0),fixtures=circle_fixture, angular_damping=0.5, linear_damping=0.5)
    assert n_bodies(world) == 2
    return body_a, body_b, world


@pytest.fixture
def two_body_joint_world(two_body_world, distance_joint_def):
    body_a, body_b, world =  two_body_world

    assert n_joints(world) == 0
    joint = world.create_joint(distance_joint_def)
    assert n_joints(world) == 1 
    return body_a, body_b, joint, world

