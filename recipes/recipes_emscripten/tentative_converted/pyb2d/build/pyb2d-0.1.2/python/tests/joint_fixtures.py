import b2d

import pytest
from pytest_lazyfixture import sorted_by_dependency, lazy_fixture, _sorted_argnames,LazyFixture

from . common import *



@pytest.fixture
def distance_joint_def(two_body_world):

    body_a, body_b, world =  two_body_world

    jdef = b2d.DistanceJointDef()
    jdef.body_a = body_a
    jdef.body_b = body_b
    jdef.local_anchor_a = (0,0)
    jdef.local_anchor_b = (0,0) 
    jdef.length = 10
    if not b2d.BuildConfiguration.OLD_BOX2D:
        jdef.min_length = 2
        jdef.max_length = 20
        jdef.stiffness = 1.0
        jdef.damping = 0.5
    else:
        jdef.damping_ratio = 0.1
        jdef.frequency_hz = 0.2
    return jdef




@pytest.fixture
def friction_joint_def(two_body_world):

    body_a, body_b, world =  two_body_world

    jdef = b2d.FrictionJointDef()
    jdef.body_a = body_a
    jdef.body_b = body_b
    jdef.max_force = 10
    jdef.max_torque = 10
    return jdef


# @pytest.fixture
# def gear_joint_def(two_body_world):
    
#     body_a, body_b, world =  two_body_world

#     jdef = b2d.GearJointDef()
#     jdef.body_a = body_a
#     jdef.body_b = body_b
#     jdef.max_force = 10
#     jdef.max_torque = 10
#     return jdef

@pytest.fixture
def prismatic_joint_def(two_body_world):

    body_a, body_b, world =  two_body_world

    jdef = b2d.PrismaticJointDef()

    jdef.body_a = body_a
    jdef.body_b = body_b
    jdef.local_anchor_a = (0,0)
    jdef.local_anchor_b = (0,0) 
    jdef.local_axis_a = (1,0)
    jdef.reference_angle = 0
    jdef.enable_limit  = False
    jdef.lower_translation = 0.0
    jdef.upper_translation = 0.0
    jdef.enable_motor = False;
    jdef.max_motor_force = 10.0
    jdef.motor_speed = 1.0

    return jdef


@pytest.fixture
def revolut_joint_def(two_body_world):

    body_a, body_b, world =  two_body_world

    jdef = b2d.RevoluteJointDef()

    jdef.body_a = body_a
    jdef.body_b = body_b

    return jdef


@pytest.fixture
def weld_joint_def(two_body_world):

    body_a, body_b, world =  two_body_world

    jdef = b2d.WeldJointDef()

    jdef.body_a = body_a
    jdef.body_b = body_b

    return jdef

@pytest.fixture
def wheel_joint_def(two_body_world):

    body_a, body_b, world =  two_body_world

    jdef = b2d.WheelJointDef()

    jdef.body_a = body_a
    jdef.body_b = body_b

    return jdef

@pytest.fixture
def mouse_joint_def(two_body_world):

    body_a, body_b, world =  two_body_world

    jdef = b2d.MouseJointDef()

    jdef.body_a = body_a
    jdef.body_b = body_b

    return jdef


@pytest.fixture(params=[
    lazy_fixture('distance_joint_def'),
    lazy_fixture('friction_joint_def'),
    #lazy_fixture('gear_joint_def'),
    lazy_fixture('prismatic_joint_def'),
    lazy_fixture('revolut_joint_def'),
    lazy_fixture('weld_joint_def'),
    lazy_fixture('wheel_joint_def'),
    lazy_fixture('mouse_joint_def'),
])
def joint_def(request):
    return request.param
