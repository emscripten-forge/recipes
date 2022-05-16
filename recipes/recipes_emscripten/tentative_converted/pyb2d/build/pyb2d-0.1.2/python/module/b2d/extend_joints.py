from ._b2d import *
from .extend_math import vec2
from .tools import _classExtender, GenericB2dIter
from . extend_user_data import add_user_data_api
from enum import Enum


add_user_data_api(JointDef)
add_user_data_api(Joint)



def _factory(cls, **kwargs):
    obj = cls()
    for k,v in kwargs.items():
        setattr(obj, k, v)
    return obj



def distance_joint_def(body_a, body_b, **kwargs):
    return _factory(DistanceJointDef,
        body_a=body_a, body_b=body_b, **kwargs)
    
def mouse_joint_def(body_a, body_b, **kwargs):
    return _factory(MouseJointDef,
        body_a=body_a, body_b=body_b, **kwargs)

def wheel_joint_def(body_a, body_b, **kwargs):
    return _factory(WheelJointDef,
        body_a=body_a, body_b=body_b, **kwargs)

def rope_joint_def(body_a, body_b, **kwargs):
    return _factory(RevoluteJointDef,
        body_a=body_a, body_b=body_b, **kwargs)

def prismatic_joint_def(body_a, body_b, **kwargs):
    return _factory(PrismaticJointDef,
        body_a=body_a, body_b=body_b, **kwargs)

def revolute_joint_def(body_a, body_b, **kwargs):
    return _factory(RevoluteJointDef,
        body_a=body_a, body_b=body_b, **kwargs)



class _Joint(Joint):
    @property
    def next(self):
        if self._has_next():
            return self._get_next()
        else:
            return None


_classExtender(_Joint,['next'])


