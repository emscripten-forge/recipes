from b2d.testbed import TestbedBase
import random
import numpy
import b2d as b2
class FunctionShape(TestbedBase):

    name = "Function Shape"
    
    def __init__(self): 
        super(FunctionShape, self).__init__()
 

        
        x = numpy.linspace(start=1,stop=100, num=500)
        y = numpy.sin(x) * numpy.log(x)
        verts = numpy.stack([x,y],-1)
        verts = numpy.require(verts, requirements=['C'])

        shape =  b2.chain_shape(
            vertices=numpy.flip(verts,axis=0)
        )

        box = self.world.create_static_body( position=(0, 0), shape = shape)

        for i in range(30):
            box = self.world.create_dynamic_body(
                position=(10+random.random()*10,random.random()*10 + 10),
                shape=b2.circle_shape(pos=(0,0), radius=0.7),
                density=1.0,
            )




if __name__ == "__main__":
    from b2d.testbed.backend.pygame import PygameGui
    gui_settings = {
        "fps" : 40,
        "resolution" : (1000,1000)
    }
    FunctionShape.run(PygameGui, gui_settings=gui_settings)