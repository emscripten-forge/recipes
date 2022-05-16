from b2d.testbed import TestbedBase
import random
import numpy
import b2d

class ColorMixing(TestbedBase):

    name = "ColorMixing"
    
    def __init__(self): 
        super(ColorMixing, self).__init__()
        dimensions = [10,10]
        
        # the outer box
        box_shape = b2d.ChainShape()
        box_shape.create_loop([
                (0,0),
                (0,dimensions[1]),
                (dimensions[0],dimensions[1]),
                (dimensions[0],0)
            ]
        )
        box = self.world.create_static_body( position=(0, 0), shape = box_shape)


        fixtureA = b2d.fixture_def(shape=b2d.circle_shape(0.5),density=2.2, friction=0.2, restitution=0.5)
        body = self.world.create_dynamic_body(
            position=(1,2.5),
            fixtures=fixtureA
        ) 

        pdef = b2d.particle_system_def(viscous_strength=0.9,spring_strength=0.0, damping_strength=100.5,pressure_strength=1.0,
                                     color_mixing_strength=0.008,density=2)
        psystem = self.world.create_particle_system(pdef)
        psystem.radius = 0.1
        psystem.damping = 0.0


        colors = [
            (255,0,0,255),
            (0,255,0,255),
            (0,0,255,255),
            (255,255,0,255)
        ]
        posiitons = [
            (3,3),
            (7,3),
            (7,7),
            (3,7)
        ]
        for color,pos in zip(colors, posiitons):

            shape = b2d.polygon_shape(box=(10/5,10/5),center=pos,angle=0)
            pgDef = b2d.particle_group_def(
                                     flags=b2d.ParticleFlag.waterParticle | b2d.ParticleFlag.colorMixingParticle, 
                                     # group_flags=b2d.ParticleGroupFlag.solidParticleGroup,
                                     shape=shape,strength=1.0,
                                      color=color
                                     )
            group = psystem.create_particle_group(pgDef)
            
if __name__ == "__main__":
    from b2d.testbed.backend.pygame import PygameGui
    gui_settings = {
        "fps" : 30,
        "resolution" : (1000,1000)
    }
    ColorMixing.run(PygameGui, gui_settings=gui_settings)