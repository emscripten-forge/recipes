from .opencv_debug_draw import *
import matplotlib.pyplot as plt
import imageio


class GifGui(object):
    def __init__(self, testbed_cls, settings, testbed_kwargs=None):
        
        self.settings = settings
        self.testbed_cls = testbed_cls
        self.testbed_kwargs = testbed_kwargs
        self._testworld = None

        self._fps = settings.get('fps', 40.0)
        self._dt = 1.0 / self._fps
        self._t = settings.get('t',10)
        self._n = int(0.5 + self._t / self._dt)

        # settings
        resolution = settings.get("resolution", (640,480))
        self.resolution = resolution
        print("resolution",resolution)


        self.image = numpy.zeros(list(self.resolution) + [3], dtype='uint8')
        self._image_list = []
        self.debug_draw = OpenCvBatchDebugDraw(image=self.image)
        self._filename = settings['filename']

        self.debug_draw.flip_y = True
        self.debug_draw.scale =  settings.get("scale", 50.0)
        self.debug_draw.translate =settings.get("translate", (0, self.resolution[1]/2.0))





    # run the world for a limited amount of steps
    def start_ui(self):
        
        self._testworld = self.testbed_cls(**self.testbed_kwargs)
        self._testworld.world.set_debug_draw(self.debug_draw)
        
        self._image_list = []

        for i in range(self._n):
            self._testworld.step(self._dt)
            self._testworld.world.draw_debug_data()


            self._image_list.append(self.image.copy())
            self.image[...] = 0

        imageio.mimsave(self._filename, self._image_list, fps=self._fps)