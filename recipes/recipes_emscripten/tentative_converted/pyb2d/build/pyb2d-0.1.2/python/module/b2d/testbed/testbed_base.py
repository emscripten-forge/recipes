import b2d
import numpy
import random
import time





# class TestbedConactListener(b2d.ContactListener):
#     def __init__(self):
#         super(TestbedConactListener, self).__init__()





class TestbedBase(
    b2d.DestructionListener,
    b2d.ContactListener
    
):
    @classmethod
    def run(cls, gui_factory, gui_settings=None, testbed_kwargs=None):
        if gui_settings is None:
            gui_settings = dict()
        if testbed_kwargs is None:
            testbed_kwargs = dict()        

        ui = gui_factory(testbed_cls=cls, testbed_kwargs=testbed_kwargs, settings=gui_settings)

        ui.start_ui()
        return ui._testworld,ui

    def __init__(self, gravity=b2d.vec2(0,-9.81)):
        b2d.ContactListener.__init__(self)
        b2d.DestructionListener.__init__(self)

        # Box2D-related
        self.points = []
        self.world = None
        self.bomb = None
        self.mouse_joint = None
        # self.framework_settings = FrameworkSettings
        self.step_count = 0
        self.is_paused = False
        self.__time_last_step = None
        self.current_fps = 0.0

        self.world = b2d.world(gravity)
        self.groundbody = self.world.create_body()
        
        self.world.set_contact_listener(self)
        self.world.set_destruction_listener(self)
        self.iter = 0
    def set_gui(self, gui):
        self._gui = gui

    def is_key_down(self, key):
        return self._gui.is_key_down(key)
    
    def step(self, dt):
        self.pre_step(dt)
        self.world.step(dt, 5, 5)
        if self.__time_last_step is None:
            self.__time_last_step  = time.time()
        else:
            t_now = time.time()
            dt = t_now - self.__time_last_step 
            self.__time_last_step = t_now
            try:
                self.current_fps = 1.0/dt
            except ZeroDivisionError:
                self.current_fps = float('inf')
                
        self.step_count += 1
        self.post_step(dt)
        self.iter += 1
    def say_goodbye_world(self):
        pass

    def auto_step(self):
        pass

    def pre_step(self, dt):
        pass

    def post_step(self, dt):
        pass
            

    def get_particle_parameter_value(self):
        return 0



    def on_mouse_move(self, p):
        """
        Mouse moved to point p, in world coordinates.
        """
        if self.mouse_joint is not None:
            self.mouse_joint.target = p
            return True
        else:
            return False

    def on_mouse_down(self, p):
        """
        Indicates that there was a left click at point p (world coordinates)
        """

       
        if self.mouse_joint is not None:
            self.world.destroy_joint(self.mouse_joint)
            self.mouse_joint = None
            return False


        body = self.world.find_body(pos=p)
        if body is not None:
            
            kwargs = dict(
                body_a=self.groundbody,
                body_b=body,
                target=p,
                max_force=50000.0 * body.mass
            )
            if not b2d.BuildConfiguration.OLD_BOX2D:
                kwargs["stiffness"] = 100.0
            self.mouse_joint = self.world.create_mouse_joint(**kwargs)
            body.awake = True

        return body is not None

    def on_mouse_up(self, p):
        """
        Left mouse button up.
        """

        if self.mouse_joint is not None:
            self.world.destroy_joint(self.mouse_joint)
            self.mouse_joint = None
            return True
        else:
            return False

    def on_key_down(self, key):
        return False

    def on_key_up(self, key):
        return False

    # # ContactListener
    # def begin_contact(self, contact):
    #     pass

    # def end_contact(self, contact):
    #     pass

    # def begin_contact_particle_body(self, particleSystem, particleBodyContact):
    #     pass

    # def begin_contact_particle(self, particleSystem, indexA, indexB):
    #     pass

    # def end_contact_particle(self, particleSystem, indexA, indexB):
    #     pass

    # def pre_solve(self, contact, oldManifold):
    #     pass

    # def post_solve(self, contact, impulse):
    #    pass

    # DestructionListener
    def say_goodbye_joint(self, joint):
        pass

    def say_goodbye_fixture(self, fixture):
        pass
    def say_goodbye_particle_group(self, particleGroup):
        pass
    def say_goodbye_particle_system(self, particleSystem,index):
        pass


