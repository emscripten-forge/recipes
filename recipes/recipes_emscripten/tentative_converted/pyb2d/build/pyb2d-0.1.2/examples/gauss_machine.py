from b2d.testbed import TestbedBase
import random
import numpy
import b2d


class GaussMachine(TestbedBase):

    name = "Gauss Machine"
    
    def __init__(self): 
        super(GaussMachine, self).__init__()
 
        self.box_shape= 30,20
        box_shape = self.box_shape
            
        # outer box
        verts =numpy.array([
            (0, box_shape[1]),(0,0),(box_shape[0],0), (box_shape[0], box_shape[1])
        ])
        shape =  b2d.chain_shape(
            vertices=numpy.flip(verts,axis=0)
        )
        box = self.world.create_static_body( position=(0, 0), shape = shape)

        # "bins"
        bin_height = box_shape[1] / 3
        bin_width = 1
        for x in range(0,box_shape[0], bin_width):
            box = self.world.create_static_body(position=(0, 0), 
                shape=b2d.two_sided_edge_shape((x, 0), (x,bin_height)))

        # reflectors
        ref_start_y = int(bin_height + box_shape[1]/10.0)
        ref_stop_y = int(box_shape[1]*0.9)
        for x in range(0, box_shape[0]+1):
            
            for y in range(ref_start_y, ref_stop_y):
                s = [0.5,0][y % 2 == 0]
                shape = b2d.circle_shape(radius=0.3)
                box = self.world.create_static_body( position=(x+s, y), shape =shape)


        # particle system
        pdef = b2d.particle_system_def(viscous_strength=0.9,spring_strength=0.0, 
            damping_strength=100.5,pressure_strength=1.0,
            color_mixing_strength=0.05,density=2)

        psystem = self.world.create_particle_system(pdef)
        psystem.radius = 0.1
        psystem.damping = 0.5

        # linear emitter
        emitter_pos = (self.box_shape[0]/2, self.box_shape[1] + 10)
        emitter_def = b2d.LinearEmitterDef()
        emitter_def.emite_rate = 200
        emitter_def.lifetime = 1000
        emitter_def.size = (10,1)
        emitter_def.transform = b2d.Transform(emitter_pos, b2d.Rot(0))


        self.emitter = b2d.LinearEmitter(psystem, emitter_def)

    def pre_step(self, dt):
        self.emitter.step(dt)



if __name__ == "__main__":

    # from b2d.testbed.backend.pygame import PygameGui as Gui
    # gui_settings = {
    #     "fps" : 40,
    #     "resolution" : (1000,1000)
    # }
    # GaussMachine.run(Gui, gui_settings=gui_settings)

    from b2d.testbed.backend.no_gui import NoGui as Gui
    gui_settings = {
    }

    GaussMachine.run(Gui, gui_settings=gui_settings)