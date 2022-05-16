import numpy
import b2d 
import pygame
import pygame.locals 
from skimage.morphology import disk, binary_dilation


class PyGameBatchDebugDraw(b2d.BatchDebugDrawNew):

    def __init__(self, surface, flags=None):
        super(PyGameBatchDebugDraw,self).__init__()

        # what is drawn
        if flags is None:
            flags = ['shape','joint']#,'aabb','pair','center_of_mass','particle']
        self.flags = flags
        self.clear_flags(['shape','joint','aabb','pair','center_of_mass','particle'])
        for flag in flags:
            self.append_flags(flag)

        # the surface to draw on
        self._surface = surface

    def draw_solid_polygons(self, points, sizes, colors):
        self._draw_polygons(points, sizes, colors, 0)

    def draw_polygons(self, points, sizes, colors):
        self._draw_polygons(points, sizes, colors, 1)

    def _draw_polygons(self, points, sizes, colors, lw):

        n_polygons = sizes.shape[0]
        start = 0
        for i in range(n_polygons):
            s = sizes[i]
            p = points[start:start+s,:]
            pygame.draw.polygon(self._surface, colors[i,:], p, lw)
            start += s


    def draw_solid_circles(self, centers, radii, axis, colors):
        self._draw_circles(centers, radii, colors, lw=0)
        
    def draw_circles(self, centers, radii, colors):
        self._draw_circles(centers, radii, colors, lw=1)

    def _draw_circles(self, centers, radii,  colors, lw):
        n = centers.shape[0]
        for i in range(n):
            pygame.draw.circle(self._surface, 
                colors[i,:], 
                centers[i,:],
                radii[i], 
                lw)

    def draw_points(self, centers, sizes, colors):
        pass

    def draw_segments(self, points, colors):
        n  = points.shape[0]
        for i in range(n):
            pygame.draw.line(
                self._surface,
                colors[i,:],
                points[i,0,:],
                points[i,1,:]
            )

    def draw_particles(self, centers, radius, colors=None):
        default_color = (255,255,255,255)

        n_particles = centers.shape[0]
        centers -= radius
        d = 2 * radius
        for i in range(n_particles):

            if colors is None:
                c = default_color
            else:
                c = colors[i,:]

            pygame.draw.rect(
                self._surface, c,
                (centers[i,0], centers[i,1], d, d)
            )

