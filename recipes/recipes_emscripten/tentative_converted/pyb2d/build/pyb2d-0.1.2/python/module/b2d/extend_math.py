
from ._b2d import *
import numpy 







def vec2(*args):
    l = len(args)
    if l == 1:
        a = args[0]
        if isinstance(a,Vec2):
            return a
        else:
            return Vec2(float(a[0]),float(a[1]))
    elif l == 2:
        return Vec2(float(args[0]),float(args[1]))

def transform(position = (0,0), rotation = 0.0):
    rot = b2Rot(float(rotation))
    return b2Transform(vec2(position), rot)

class Vec2Iter(object):
    def __init__(self,vector, currentIndex=0):
        self.vector = vector
        self.currentIndex = currentIndex
    def __next__(self):
        return self.next()
    def __iter__(self):
        return self
    def next(self):
        if self.currentIndex==2:
            raise StopIteration
        else:
            c = self.vector[self.currentIndex]
            self.currentIndex +=1
            return c



def extendB2Vec2():
    

    def __setitem__(self, key, val):

        if int(key) == 0:
            self.x = val
        elif int(key) == 1:
            self.y = val
        else:
            raise RuntimeError("wrong index %s"%str(key))
    Vec2.__setitem__ = __setitem__


    def __getitem__(self, key):

        if int(key) == 0:
            return self.x
        elif int(key) == 1:
            return self.y
        else:
            raise RuntimeError("wrong index %s"%str(key))
    Vec2.__getitem__ = __getitem__

    def isfinite(self):
        return numpy.isfinite(self.x) and numpy.isfinite(self.y)
    Vec2.isfinite = isfinite
  

    def __iter__(self):
        return Vec2Iter(self)
    Vec2.__iter__ = __iter__

  
    def as_tuple(self):
        return (self.x,self.y)
    Vec2.as_tuple = as_tuple

    def __repr__(self):
        return "(%f,%f)"%(self.x,self.y)
    Vec2.__repr__ = __repr__

    def __str__(self):
        return "(%f,%f)"%(self.x,self.y)
    Vec2.__str__ = __str__
extendB2Vec2()
del extendB2Vec2
