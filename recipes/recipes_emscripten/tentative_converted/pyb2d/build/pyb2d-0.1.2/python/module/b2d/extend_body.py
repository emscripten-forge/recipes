from types import MethodType

from . _b2d import *
from . tools import _classExtender, GenericB2dIter
from . extend_math import vec2
from . extend_shapes import *
from . extend_user_data import add_user_data_api


def body_def(btype=None,position=None,angle=None,linear_velocity=None,
            angular_velocity=None,linear_damping=None,angular_damping=None,
            allow_sleep=None, awake=None, fixed_rotation=None, bullet=None,
            user_data=None, int_user_data=None):
    d = BodyDef()
    if btype is not None:
        d.btype = btype
    if position is not None:
        d.position = vec2(position)
    if angle is not None:
        d.angle = angle
    if linear_velocity is not None:
        d.linear_velocity = vec2(linear_velocity)
    if angular_velocity is not None:
        d.angular_velocity = float(angular_velocity)
    if linear_damping is not None:
        d.linear_damping = linear_damping
    if angular_damping is not None:
        d.angular_damping = angular_damping
    if allow_sleep is not None:
        d.allow_sleep = allow_sleep
    if awake is not None:
        d.awake = awake
    if fixed_rotation is not None:
        d.fixed_rotation = fixed_rotation
    if bullet is not None:
        d.bullet = bullet
    if user_data is not None:
        d.user_data = user_data
    if int_user_data is not None:
        d.int_user_data = int_user_data
    return d


class _BodyDef(BodyDef):


    @property
    def user_data(self):
        if self._has_object_user_data():
            return self._get_object_user_data()
        else:
            return None

    @user_data.setter
    def user_data(self, ud):
        self._set_object_user_data(ud)



_classExtender(_BodyDef,['user_data'])








add_user_data_api(Body)
add_user_data_api(BodyDef)


class _Body( Body):






    @property
    def world(self):
        return self._get_world()

    def create_polygon_fixture(self, box=None,**kwargs):

        fixtureDef = b2FixtureDef()

        assert box is not None
        shape = b2PolygonShape()
        shape.setAsBox(box[0],box[1])

        fixtureDef.shape = shape 

        for kw in kwargs:
            setattr(fixtureDef,kw, kwargs[kw])

        return self.create_fixture(fixtureDef)

    def create_circle_fixture(self, radius, density=1, friction=0.2):
        fixtureDef = b2FixtureDef()

        shape = b2CircleShape()
        shape.radius = radius
        fixtureDef.friction = friction
        fixtureDef.density = density
        fixtureDef.shape = shape 
        return self.create_fixture(fixtureDef)

    def create_chain_fixture(self, vertices, prev_vertex, next_vertex, density=1, friction=0.2):
        fixtureDef = b2FixtureDef()
        shape = chain_shape(vertices=vertices,prev_vertex=prev_vertex, next_vertex=next_vertex)
        fixtureDef.shape = shape 
        return self.create_fixture(fixtureDef)



    def create_fixtures_from_shapes(self, shapes, density=1.0):
        if isinstance(shapes, b2Shape):
            shapes = [shapes]
        fixtures = []
        for shape in shapes:
            fixtureDef = b2FixtureDef()
            fixtureDef.density = density
            fixtureDef.shape = shape 
            fixtures.append( self.create_fixture(fixtureDef))
        return fixtures

    @property
    def type(self):
        return self.btype

    @property
    def next(self):
        if self._has_next():
            return self._get_next()
        else:
            return None

    @property
    def fixtures(self):
        flist = None
        if self._has_fixture_list():
            flist = self._get_fixture_list()
        return GenericB2dIter(flist)

    @property
    def joints(self):
        jlist = None
        if self._hasJointList():
            jlist = self._getJointList()
        return GenericB2dIter(jlist)

    @property
    def joint_list(self):
        return list(self.joints)
        
    @property
    def joint_list(self):
        return list(self.joints)





_classExtender(_Body,[ 'type','world','create_polygon_fixture','create_circle_fixture',
                      'create_chain_fixture',
                    'create_fixtures_from_shapes',
                     'next','fixtures','joints'], baseCls=Body)


