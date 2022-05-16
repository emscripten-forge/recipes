from . _b2d import *
from . _b2d import _World
from . tools import _classExtender, GenericB2dIter

from . extend_body import BodyDef
from . extend_shapes import polygon_shape
from . extend_fixture import fixture_def
from . extend_math import vec2
from . extend_collision import aabb
from . extend_joints import *
from . query_callback import QueryCallback



  


class World(_World):
    def __init__(self, gravity):
        super(World, self).__init__(gravity)
        self._batch_debug_draw_collector = None

    

    def set_destruction_listener(self, listener):
        self._set_destruction_listener(listener)

    def set_batch_debug_draw(self, batch_debug_draw):

        self._batch_debug_draw = batch_debug_draw
        self._batch_debug_draw_options = batch_debug_draw.options
        self._batch_debug_draw_collector = BatchDebugDrawCollector(self._batch_debug_draw_options)

        self._inactive_body_color  = (0.5, 0.5, 0.3)
        self._static_body_color    = (0.5, 0.9, 0.5)
        self._kinematic_body_color = (0.5, 0.5, 0.9)
        self._sleeping_body_color  = (0.6, 0.6, 0.6)
        self._dynamic_body_color   = (0.9, 0.7, 0.7)

        self._joint_color = (0.5, 0.8, 0.8)
        self._axis_color = (0.2, 0.2, 0.2)
        self._aabb_color = (0.9, 0.3, 0.9)

    def batch_draw_debug_data(self):

        if self._batch_debug_draw_collector is not None:
            opts = self._batch_debug_draw_options
            pseudo_body_types = [
                "inactive_body",
                "static_body",
                "kinematic_body",
                "sleeping_body",
                "dynamic_body",
            ]




            batch_debug_draw = self._batch_debug_draw
            collector = self._batch_debug_draw_collector

            # collect the data
            collector.collect(self)

            # the bounding box of the overall drawin area
            aabb = collector.drawing_aabb
            batch_debug_draw.drawing_aabb(aabb)

            if opts.draw_shapes:

                for pseudo_body_type in pseudo_body_types:
                    verts,connect = getattr(collector,"%s_polygon_shapes"%pseudo_body_type)()
                    color = getattr(self,"_%s_color"%pseudo_body_type)
                    batch_debug_draw.draw_solid_polygons(verts, connect, color)

                verts = collector.circles_axis()
                color = self._axis_color
                batch_debug_draw.draw_segments(verts, 'pairs', color)

                for pseudo_body_type in pseudo_body_types:
                    verts,connect = getattr(collector,"%s_chain_shapes"%pseudo_body_type)()
                    color = getattr(self,"_%s_color"%pseudo_body_type)
                    batch_debug_draw.draw_segments(verts, connect, color)
            
            if opts.draw_joints:
                points = collector.joint_segments()
                color = self._joint_color
                batch_debug_draw.draw_segments(points, 'pairs', color)

            if opts.draw_aabbs:
                verts,connect = collector.aabbs()
                color = self._aabb_color
                batch_debug_draw.draw_polygons(verts, connect, color)




            collector.clear()

        else:
            pass

    # helper functions
    def find_fixture(self, pos, margin=0.001):
        pos = vec2(pos)
        class AABBCallback(QueryCallback):
            def __init__(self, test_point):
                super(AABBCallback,self).__init__()

                self.test_point = vec2(test_point)
                self.fixture  = None

            def report_fixture(self, fixture):
                if fixture.test_point(self.test_point):
                    self.fixture = fixture
                    return False
                else:
                    return True
        box =  aabb(lower_bound=pos - vec2(margin, margin),
                        upper_bound=pos + vec2(margin, margin))

        query = AABBCallback(pos)
        self.query_aabb(query, box)
        return query.fixture 

    def find_body(self, pos, margin=0.001):
        fixture = self.find_fixture(pos=pos, margin=margin)
        if fixture is not None:
            return fixture.body
        else:
            return None

    def query_aabb_callback(self, **kwargs):
        

        class AABBCallback(QueryCallback):
            def __init__(self, callback):
                super(AABBCallback,self).__init__()
                self.callback = callback
            def report_fixture(self, fixture):
                return self.callback(fixture)

        callback = kwargs.pop('f')
        box = aabb(**kwargs)
        
        query = AABBCallback(callback)
        self.query_aabb(query, box)


    def find_closest_n_bodies(self, pos, r,r_fixture=None, n=None, body_filter=None):
        if r_fixture is None:
            r_fixture = r * 1.5  

        bodies_and_dists = []
        def f(fixture):
            body = fixture.body
            if body_filter is None or body_filter(body):
                center = body.world_center
                d = (pos-body.world_center).length
                if d < r: 
                    bodies_and_dists.append((body, d))
            return True

        self.query_aabb_callback(p=pos, r=r_fixture, f=f)
        sorted_bodies_and_dists = sorted(bodies_and_dists, key=lambda v :v[1])
        if n is not None and len(sorted_bodies_and_dists) >=n:
            return sorted_bodies_and_dists[0:n]
        else:
            return sorted_bodies_and_dists

    @property
    def bodies(self):
        blist = None
        if self.body_count > 0:
            blist = self._get_body_list()
        return GenericB2dIter(blist)

    @property
    def joints(self):
        blist = None
        if self.joint_count > 0:
            blist = self._get_joint_list()
        return GenericB2dIter(blist)

    @property
    def body_list(self):
        blist = None
        if self.body_count > 0:
            blist = self._get_body_list()
        return GenericB2dIter(blist)

    @property
    def joint_list(self):
        blist = None
        if self.joint_count > 0:
            blist = self._get_joint_list()
        return GenericB2dIter(blist)

    # functions
    def _create_body(self, type=None, body_def=None,shape=None, shapes=None, fixtures=None, shape_fixture=None, density = None,
                    **kwargs):

        if body_def is None:
            body_def = BodyDef()

        if type  is not None:
            body_def.type = type

        for attr_name,val in kwargs.items():
            setattr(body_def, attr_name, val)
      
        body = self._create_body_cpp(body_def)

    
        _shapes = []
        if shape is not None:
            _shapes.append(shape)
        if shapes is not None:
            if isinstance(shapes, Shape):
                shapes = [shapes]
            _shapes = _shapes + shapes


        for shape in _shapes:
            if shape_fixture is None:
                shape_fixture =fixture_def()
                if density is not None:
                    shape_fixture.density = density
            shape_fixture.shape = shape
            body.create_fixture(shape_fixture)


        if fixtures is not None:
            if isinstance(fixtures,FixtureDef):
                fixtures = [fixtures]
            for fixture in fixtures:
                body.create_fixture(fixture)

        return body

    def create_static_body(self, **kwargs):
        return self._create_body(type= BodyType.static, **kwargs)
    def create_dynamic_body(self, **kwargs):
        return self._create_body(type= BodyType.dynamic, **kwargs)
    def create_kinematic_body(self, **kwargs):
        return self._create_body(type= BodyType.kinematic, **kwargs)
    def create_body(self, *args, **kwargs):

        if(len(kwargs) == 0 and len(args) == 1 and isinstance(args[0], BodyDef)):
            return self._create_body_cpp(args[0])
        return self._create_body(*args, **kwargs)


    def create_box_body(self, box, density=None, **kwargs):
        fixture = fixture_def(density=density, shape=polygon_shape(box=box))
        return self._create_body(fixtures=fixture, **kwargs)



    def create_mouse_joint(self, *args,**kwargs):
        d = mouse_joint_def(*args, **kwargs)
        return self.create_joint(d)

    def create_prismatic_joint(self,*args,**kwargs):
        d = prismatic_joint_def(*args,**kwargs)
        return self.create_joint(d)

    def create_distance_joint(self,*args,**kwargs):
        d = distance_joint_def(*args,**kwargs)
        return self.create_joint(d)

    def create_revolute_joint(self,*args,**kwargs):
        d = revolute_joint_def(*args,**kwargs)
        return self.create_joint(d)
    def create_wheel_joint(self,*args,**kwargs):
        d = wheel_joint_def(*args,**kwargs)
        return self.create_joint(d)






def world(gravity = (0,-9.81)):
    return World(vec2(gravity))

