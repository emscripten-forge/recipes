import inspect
import math

class GenericB2dIter(object):
    def __init__(self, currentItem):
        self.currentItem = currentItem
    def __next__(self):
        return self.next()
    def __iter__(self):
        return self
    def next(self):
        if self.currentItem is None:
            raise StopIteration
        else:
            c = self.currentItem
            self.currentItem = c.next
            return c

def _classExtender(moreCls, methods,baseCls=None):
    if baseCls is None:
        baseCls = inspect.getmro(moreCls)[1]
    for m in methods:
        setattr(baseCls, m, moreCls.__dict__[m])

# https://martin-thoma.com/how-to-check-if-a-point-is-inside-a-rectangle/
class Triangle:
    """Represents a triangle in R^2."""

    epsilon = 0.001

    def __init__(self, a, b, c):
        self.a = a
        self.b = b
        self.c = c

    def angles(self):
        # https://www.geeksforgeeks.org/find-angles-given-triangle/
        # Square of lengths be a2, b2, c2 

        def length_square(a,b):
            return (a[0] - b[0])**2 + (a[1] - b[1])**2

        a2 = length_square(self.b, self.c)
        b2 = length_square(self.a, self.c)
        c2 = length_square(self.a, self.b)
      
        # lenght of sides be a, b, c 
        a = math.sqrt(a2)
        b = math.sqrt(b2)
        c = math.sqrt(c2)
      
        # From Cosine law 
        alpha = math.acos((b2 + c2 - a2)/(2*b*c))
        betta = math.acos((a2 + c2 - b2)/(2*a*c))
        gamma = math.acos((a2 + b2 - c2)/(2*a*b))
      
        # Converting to degree 
        #alpha = alpha * 180.0 / math.pi; 
        #betta = betta * 180.0 / math.pi; 
        #gamma = gamma * 180.0 / math.pi; 
        
        return alpha, betta, gamma


    def get_area(self):
        """Get area of this triangle.
           >>> Triangle(Point(0.,0.), Point(10.,0.), Point(10.,10.)).get_area()
           50.0
           >>> Triangle(Point(-10.,0.), Point(10.,0.), Point(10.,10.)).get_area()
           100.0
        """
        a, b, c = self.a, self.b, self.c
        return abs(a[0]*(b[1]-c[1])+b[0]*(c[1]-a[1])+c[0]*(a[1]-b[1]))/2

    def is_inside(self, p):
        """Check if p is inside this triangle."""
        
        currentArea = self.get_area()
        pab = Triangle(p,self.a, self.b)
        pac = Triangle(p,self.a, self.c)
        pbc = Triangle(p,self.b, self.c)
        newArea = pab.get_area()+pac.get_area()+pbc.get_area()
        return (abs(currentArea - newArea) < Triangle.epsilon)

def in_triangle(p, verts):
    return Triangle(*verts).is_inside(p)

def triangel_angles(a,b,c):
    return Triangle(a,b,c).angles()