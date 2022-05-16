import sys
import glob

from pybind11 import get_cmake_dir
# Available at setup time due to pyproject.toml
from pybind11.setup_helpers import Pybind11Extension, build_ext
from setuptools import setup, find_packages

__version__ = "0.1.1"

# The main interface is through Pybind11Extension.
# * You can add cxx_std=11/14/17, and then build_ext can be removed.
# * You can set include_pybind11=false to add the include directory yourself,
#   say from a submodule.
#
# Note:
#   Sort input source files if you glob sources to ensure bit-for-bit
#   reproducible builds (https://github.com/pybind/python_example/pull/53)

liquidfun = True

binding_sources = [
    "python/src/main.cpp",
    "python/src/def_build_config.cpp",
    "python/src/b2Body.cxx",
    "python/src/b2Collision.cxx",
    "python/src/b2Contact.cxx",
    "python/src/b2Draw.cxx",
    "python/src/b2Fixture.cxx",
    "python/src/b2Joint.cxx",
    "python/src/b2JointDef.cxx",
    "python/src/b2Math.cxx",
    "python/src/b2Shape.cxx",
    "python/src/b2WorldCallbacks.cxx",
    "python/src/b2World.cxx"
]

include_dirs = []

if liquidfun:
    binding_sources += [
        "python/src/b2Particle.cxx",
        "python/src/b2ParticleGroup.cxx",
        "python/src/b2ParticleSystem.cxx",
        "python/src/pyEmitter.cxx",
        "python/src/extensions/b2Emitter.cpp"
    ]
    box2d_include_dirs = [
        "external/liquidfun-1.1.0/liquidfun/Box2D"
    ]
    box2d_sources = [
        "external/liquidfun-1.1.0/liquidfun/Box2D/Box2D/Collision/b2BroadPhase.cpp",
        "external/liquidfun-1.1.0/liquidfun/Box2D/Box2D/Collision/b2CollideCircle.cpp",
        "external/liquidfun-1.1.0/liquidfun/Box2D/Box2D/Collision/b2CollideEdge.cpp",
        "external/liquidfun-1.1.0/liquidfun/Box2D/Box2D/Collision/b2CollidePolygon.cpp",
        "external/liquidfun-1.1.0/liquidfun/Box2D/Box2D/Collision/b2Collision.cpp",
        "external/liquidfun-1.1.0/liquidfun/Box2D/Box2D/Collision/b2Distance.cpp",
        "external/liquidfun-1.1.0/liquidfun/Box2D/Box2D/Collision/b2DynamicTree.cpp",
        "external/liquidfun-1.1.0/liquidfun/Box2D/Box2D/Collision/b2TimeOfImpact.cpp",
        "external/liquidfun-1.1.0/liquidfun/Box2D/Box2D/Collision/Shapes/b2CircleShape.cpp",
        "external/liquidfun-1.1.0/liquidfun/Box2D/Box2D/Collision/Shapes/b2EdgeShape.cpp",
        "external/liquidfun-1.1.0/liquidfun/Box2D/Box2D/Collision/Shapes/b2ChainShape.cpp",
        "external/liquidfun-1.1.0/liquidfun/Box2D/Box2D/Collision/Shapes/b2PolygonShape.cpp",
        "external/liquidfun-1.1.0/liquidfun/Box2D/Box2D/Common/b2BlockAllocator.cpp",
        "external/liquidfun-1.1.0/liquidfun/Box2D/Box2D/Common/b2Draw.cpp",
        "external/liquidfun-1.1.0/liquidfun/Box2D/Box2D/Common/b2FreeList.cpp",
        "external/liquidfun-1.1.0/liquidfun/Box2D/Box2D/Common/b2Math.cpp",
        "external/liquidfun-1.1.0/liquidfun/Box2D/Box2D/Common/b2Settings.cpp",
        "external/liquidfun-1.1.0/liquidfun/Box2D/Box2D/Common/b2StackAllocator.cpp",
        "external/liquidfun-1.1.0/liquidfun/Box2D/Box2D/Common/b2Stat.cpp",
        "external/liquidfun-1.1.0/liquidfun/Box2D/Box2D/Common/b2Timer.cpp",
        "external/liquidfun-1.1.0/liquidfun/Box2D/Box2D/Common/b2TrackedBlock.cpp",
        "external/liquidfun-1.1.0/liquidfun/Box2D/Box2D/Dynamics/b2Body.cpp",
        "external/liquidfun-1.1.0/liquidfun/Box2D/Box2D/Dynamics/b2ContactManager.cpp",
        "external/liquidfun-1.1.0/liquidfun/Box2D/Box2D/Dynamics/b2Fixture.cpp",
        "external/liquidfun-1.1.0/liquidfun/Box2D/Box2D/Dynamics/b2Island.cpp",
        "external/liquidfun-1.1.0/liquidfun/Box2D/Box2D/Dynamics/b2World.cpp",
        "external/liquidfun-1.1.0/liquidfun/Box2D/Box2D/Dynamics/b2WorldCallbacks.cpp",
        "external/liquidfun-1.1.0/liquidfun/Box2D/Box2D/Dynamics/Contacts/b2CircleContact.cpp",
        "external/liquidfun-1.1.0/liquidfun/Box2D/Box2D/Dynamics/Contacts/b2Contact.cpp",
        "external/liquidfun-1.1.0/liquidfun/Box2D/Box2D/Dynamics/Contacts/b2ContactSolver.cpp",
        "external/liquidfun-1.1.0/liquidfun/Box2D/Box2D/Dynamics/Contacts/b2PolygonAndCircleContact.cpp",
        "external/liquidfun-1.1.0/liquidfun/Box2D/Box2D/Dynamics/Contacts/b2EdgeAndCircleContact.cpp",
        "external/liquidfun-1.1.0/liquidfun/Box2D/Box2D/Dynamics/Contacts/b2EdgeAndPolygonContact.cpp",
        "external/liquidfun-1.1.0/liquidfun/Box2D/Box2D/Dynamics/Contacts/b2ChainAndCircleContact.cpp",
        "external/liquidfun-1.1.0/liquidfun/Box2D/Box2D/Dynamics/Contacts/b2ChainAndPolygonContact.cpp",
        "external/liquidfun-1.1.0/liquidfun/Box2D/Box2D/Dynamics/Contacts/b2PolygonContact.cpp",
        "external/liquidfun-1.1.0/liquidfun/Box2D/Box2D/Dynamics/Joints/b2DistanceJoint.cpp",
        "external/liquidfun-1.1.0/liquidfun/Box2D/Box2D/Dynamics/Joints/b2FrictionJoint.cpp",
        "external/liquidfun-1.1.0/liquidfun/Box2D/Box2D/Dynamics/Joints/b2GearJoint.cpp",
        "external/liquidfun-1.1.0/liquidfun/Box2D/Box2D/Dynamics/Joints/b2Joint.cpp",
        "external/liquidfun-1.1.0/liquidfun/Box2D/Box2D/Dynamics/Joints/b2MotorJoint.cpp",
        "external/liquidfun-1.1.0/liquidfun/Box2D/Box2D/Dynamics/Joints/b2MouseJoint.cpp",
        # "external/liquidfun-1.1.0/liquidfun/Box2D/Box2D/Dynamics/Joints/b2MotorJoint.cpp",
        "external/liquidfun-1.1.0/liquidfun/Box2D/Box2D/Dynamics/Joints/b2PrismaticJoint.cpp",
        "external/liquidfun-1.1.0/liquidfun/Box2D/Box2D/Dynamics/Joints/b2PulleyJoint.cpp",
        "external/liquidfun-1.1.0/liquidfun/Box2D/Box2D/Dynamics/Joints/b2RevoluteJoint.cpp",
        "external/liquidfun-1.1.0/liquidfun/Box2D/Box2D/Dynamics/Joints/b2RopeJoint.cpp",
        "external/liquidfun-1.1.0/liquidfun/Box2D/Box2D/Dynamics/Joints/b2WeldJoint.cpp",
        "external/liquidfun-1.1.0/liquidfun/Box2D/Box2D/Dynamics/Joints/b2WheelJoint.cpp",
        "external/liquidfun-1.1.0/liquidfun/Box2D/Box2D/Particle/b2Particle.cpp",
        "external/liquidfun-1.1.0/liquidfun/Box2D/Box2D/Particle/b2ParticleGroup.cpp",
        "external/liquidfun-1.1.0/liquidfun/Box2D/Box2D/Particle/b2ParticleSystem.cpp",
        "external/liquidfun-1.1.0/liquidfun/Box2D/Box2D/Particle/b2VoronoiDiagram.cpp",
        "external/liquidfun-1.1.0/liquidfun/Box2D/Box2D/Rope/b2Rope.cpp",

    ]
    macros = [
        ('PYBOX2D_LIQUID_FUN',1),
        ('PYBOX2D_OLD_BOX2D', 1)
    ]
else:
    box2d_include_dirs = [
        "external/box2d-2.4.1/include",
        "external/box2d-2.4.1/src"
    ]
    box2d_sources = [
        "external/box2d-2.4.1/src/collision/b2_broad_phase.cpp",
        "external/box2d-2.4.1/src/collision/b2_chain_shape.cpp",
        "external/box2d-2.4.1/src/collision/b2_circle_shape.cpp",
        "external/box2d-2.4.1/src/collision/b2_collide_circle.cpp",
        "external/box2d-2.4.1/src/collision/b2_collide_edge.cpp",
        "external/box2d-2.4.1/src/collision/b2_collide_polygon.cpp",
        "external/box2d-2.4.1/src/collision/b2_collision.cpp",
        "external/box2d-2.4.1/src/collision/b2_distance.cpp",
        "external/box2d-2.4.1/src/collision/b2_dynamic_tree.cpp",
        "external/box2d-2.4.1/src/collision/b2_edge_shape.cpp",
        "external/box2d-2.4.1/src/collision/b2_polygon_shape.cpp",
        "external/box2d-2.4.1/src/collision/b2_time_of_impact.cpp",
        "external/box2d-2.4.1/src/common/b2_block_allocator.cpp",
        "external/box2d-2.4.1/src/common/b2_draw.cpp",
        "external/box2d-2.4.1/src/common/b2_math.cpp",
        "external/box2d-2.4.1/src/common/b2_settings.cpp",
        "external/box2d-2.4.1/src/common/b2_stack_allocator.cpp",
        "external/box2d-2.4.1/src/common/b2_timer.cpp",
        "external/box2d-2.4.1/src/dynamics/b2_body.cpp",
        "external/box2d-2.4.1/src/dynamics/b2_chain_circle_contact.cpp",
        # "external/box2d-2.4.1/src/dynamics/b2_chain_circle_contact.h",
        "external/box2d-2.4.1/src/dynamics/b2_chain_polygon_contact.cpp",
        # "external/box2d-2.4.1/src/dynamics/b2_chain_polygon_contact.h",
        "external/box2d-2.4.1/src/dynamics/b2_circle_contact.cpp",
        # "external/box2d-2.4.1/src/dynamics/b2_circle_contact.h",
        "external/box2d-2.4.1/src/dynamics/b2_contact.cpp",
        "external/box2d-2.4.1/src/dynamics/b2_contact_manager.cpp",
        "external/box2d-2.4.1/src/dynamics/b2_contact_solver.cpp",
        # "external/box2d-2.4.1/src/dynamics/b2_contact_solver.h",
        "external/box2d-2.4.1/src/dynamics/b2_distance_joint.cpp",
        "external/box2d-2.4.1/src/dynamics/b2_edge_circle_contact.cpp",
        # "external/box2d-2.4.1/src/dynamics/b2_edge_circle_contact.h",
        "external/box2d-2.4.1/src/dynamics/b2_edge_polygon_contact.cpp",
        # "external/box2d-2.4.1/src/dynamics/b2_edge_polygon_contact.h",
        "external/box2d-2.4.1/src/dynamics/b2_fixture.cpp",
        "external/box2d-2.4.1/src/dynamics/b2_friction_joint.cpp",
        "external/box2d-2.4.1/src/dynamics/b2_gear_joint.cpp",
        "external/box2d-2.4.1/src/dynamics/b2_island.cpp",
        # "external/box2d-2.4.1/src/dynamics/b2_island.h",
        "external/box2d-2.4.1/src/dynamics/b2_joint.cpp",
        "external/box2d-2.4.1/src/dynamics/b2_motor_joint.cpp",
        "external/box2d-2.4.1/src/dynamics/b2_mouse_joint.cpp",
        "external/box2d-2.4.1/src/dynamics/b2_polygon_circle_contact.cpp",
        # "external/box2d-2.4.1/src/dynamics/b2_polygon_circle_contact.h",
        "external/box2d-2.4.1/src/dynamics/b2_polygon_contact.cpp",
        # "external/box2d-2.4.1/src/dynamics/b2_polygon_contact.h",
        "external/box2d-2.4.1/src/dynamics/b2_prismatic_joint.cpp",
        "external/box2d-2.4.1/src/dynamics/b2_pulley_joint.cpp",
        "external/box2d-2.4.1/src/dynamics/b2_revolute_joint.cpp",
        "external/box2d-2.4.1/src/dynamics/b2_weld_joint.cpp",
        "external/box2d-2.4.1/src/dynamics/b2_wheel_joint.cpp",
        "external/box2d-2.4.1/src/dynamics/b2_world.cpp",
        "external/box2d-2.4.1/src/dynamics/b2_world_callbacks.cpp",
        "external/box2d-2.4.1/src/rope/b2_rope.cpp",
    ]
    macros = []


ext_modules = [
    Pybind11Extension("b2d._b2d",

        binding_sources + box2d_sources,
        include_dirs=box2d_include_dirs+include_dirs,
        # Example: passing in the version to the compiled code
        define_macros = [('VERSION_INFO', __version__)] + macros,
        ),
]


install_requires = [
    "numpy"
]
setup(
    name="b2d",
    version=__version__,
    author="Thorsten Beier",
    author_email="derthorstenbeier@gmail.com",
    url="https://github.com/pybind/python_example",
    description="A test project using pybind11",
    long_description="",
    ext_modules=ext_modules,
    packages=find_packages(where='./python/module', exclude="test"),
    install_requires=install_requires,
    extras_require={"test": "pytest"},
    package_dir = {'': 'python/module'},
    # Currently, build_ext only provides an optional "highest supported C++
    # level" feature, but in the future it may provide more features.
    cmdclass={"build_ext": build_ext},
    zip_safe=False,
    python_requires=">=3.6",
)