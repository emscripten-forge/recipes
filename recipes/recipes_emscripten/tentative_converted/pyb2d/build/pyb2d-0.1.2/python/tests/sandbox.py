import b2d
import numpy


import time

class Timer:    
    def __enter__(self):
        self.start = time.time()
        return self

    def __exit__(self, *args):
        self.end = time.time()
        self.interval = self.end - self.start



n_verts = 100
repeats = 1000
as_list = [b2d.b2Vec2(x,0) for x in range(n_verts)]
as_numpy = numpy.zeros(shape=[n_verts*2, 2], dtype='float32')
as_numpy[:,0] = numpy.arange(n_verts*2)
as_numpy = as_numpy[::2,:]
as_numpy_d = numpy.require(as_numpy, requirements=['C'])





with Timer() as t:
    for i in range(repeats):
        s = b2d.PolygonShape()
        s.set(as_list)
print('list took             %.03f sec.' % t.interval)

with Timer() as t:
    for i in range(repeats):
        s = b2d.PolygonShape()
        s.set(as_numpy_d)
print('array took            %.03f sec.' % t.interval)

with Timer() as t:
    for i in range(repeats):
        s = b2d.PolygonShape()
        s.set(as_numpy)
print('strided array took    %.03f sec.' % t.interval)

