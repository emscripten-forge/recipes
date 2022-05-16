import b2d

from . common import *
from . callbacks import *
import pytest


print(b2d.__file__)


class TestWorldCallbacks(object):
    
    def test_debug_draw(self, two_body_joint_world):
        body_a, body_b, joint, world =  two_body_joint_world
        debug_draw = RecDebugDraw()
        assert debug_draw.total_calls() == 0
        world.set_debug_draw(debug_draw)
        do_test_step(world, draw_debug_data=True)
        assert debug_draw.total_calls() > 0

    def test_destruction_listener(self, two_body_joint_world):
        body_a, body_b, joint, world =  two_body_joint_world
        destruction_listener = RecDestructionListener()
        world.set_destruction_listener(destruction_listener)
        world.destroy_body(body_a)
        world.destroy_body(body_b)
        assert len(destruction_listener.recordings["say_goodbye_joint"]) == 1
        assert len(destruction_listener.recordings["say_goodbye_fixture"]) == 2

    # contact filter shall only fire when gravity is non-zero
    @pytest.mark.parametrize("gravity", [(0,0), (0,-10)])
    def test_contact_listener(self, gravity):

        # world
        world = b2d.world(gravity=gravity)

        # add contact listener
        contact_listener = RecContactListener()
        world.set_contact_listener(contact_listener)

        # create box like thing to contain both balls
        s = 10 
        verts = [ 
            (-s, 0),
            ( 0,-s),
            ( s, 0),
            ( s, s),
            (-s, s)
        ] 
        shape = b2d.ChainShape()
        shape.create_loop(verts)

        fixture_def = b2d.FixtureDef()
        fixture_def.shape = shape

        body_def = b2d.BodyDef()
        body_def.type = b2d.BodyType.static
        body_def.position = (0, 0)

        body = world.create_body(body_def)
        body.create_fixture(fixture_def)

        #  Add 2 balls
        centers = [
            (0,0), (0,4)
        ]
        cirle_shape = b2d.CircleShape()
        cirle_shape.radius = 1

        fixture_def = b2d.FixtureDef()
        fixture_def.shape = cirle_shape
        fixture_def.density = 1.0
        balls = [None]*2
        for i,center in enumerate(centers):
            body_def = b2d.BodyDef()
            body_def.type = b2d.BodyType.dynamic
            body_def.position = center

            body = world.create_body(body_def)
            body.create_fixture(fixture_def)
            balls[i] = body
        assert contact_listener.total_calls() == 0
        # do 1000 steps
        n_steps = 100
        for  i in range(n_steps):
            print(balls[0].position)
            world.step(0.1, 5,5)
        if gravity[1] < -5:
            assert contact_listener.total_calls() > 0
        else:
            assert contact_listener.total_calls() == 0 


    def test_batch_debug_draw_new(self, two_body_joint_world):
        body_a, body_b, joint, world =  two_body_joint_world
        debug_draw = RecBatchDebugDrawNew()
        assert debug_draw.total_calls() == 0
        world.set_debug_draw(debug_draw)
        do_test_step(world, draw_debug_data=True)
        assert debug_draw.total_calls() > 0
        

class TestJoints(object):
    def test_joints_generic(self, two_body_world, joint_def):
        body_a, body_b, world =  two_body_world
        joint = world.create_joint(joint_def)
        assert n_joints(world) == 1
        do_test_step(world)



class TestEdgeShape(object):
    def test_set_two_sided(self):
        s = b2d.EdgeShape()
        if b2d.BuildConfiguration.OLD_BOX2D:
            s.set((0,0), (0,1))
        else:
            s.set_two_sided((0,0), (0,1))
    def test_set_one_sided(self):
        s = b2d.EdgeShape()

        if b2d.BuildConfiguration.OLD_BOX2D:
            s.set((0,0), (0,1))
        else:
            s.set_one_sided((0,0), (0,1), (0,2), (0,3))


class TestCircleShape(object):
    def test_circle_shape(self):
        s = b2d.CircleShape()
        s.radius = 2.0
        s.pos = b2d.Vec2(0,0)

        s = b2d.CircleShape()
        s.radius = 2.0
        s.pos = (0,0)

class TestPolyonShape(object):
    def test_polygon_shape_set(self):
        s = b2d.PolygonShape()
        s.set([
            (0,0),
            (0,1),
            (1,1),
            (0,1),
        ])

    def test_polygon_shape_set_from_numpy(self):
        s = b2d.PolygonShape()
        s.set([
            (0,0),
            (0,1),
            (1,1),
            (0,1),
        ])


class TestChainShape(object):
    def test_create_loop(self):
        s = b2d.ChainShape()
        s.create_loop([
            (0,0),
            (0,1),
            (1,1)
        ])

    def test_create_chain(self):
        s = b2d.ChainShape()
        s.create_chain([
            (0,0),
            (0,1),
            (1,1),
            (0,1),
        ], 
        [0,0],
        (0,0))

if __name__ == "__main__":
    import sys
    sys.exit(pytest.main())