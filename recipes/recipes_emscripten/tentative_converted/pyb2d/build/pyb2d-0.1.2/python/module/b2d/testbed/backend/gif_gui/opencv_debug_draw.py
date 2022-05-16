import numpy
import b2d 
import cv2 as cv

import pygame
import pygame.locals 
from skimage.morphology import disk, binary_dilation


class OpenCvBatchDebugDraw(b2d.BatchDebugDrawNew):

    def __init__(self, image, flags=None):
        super(OpenCvBatchDebugDraw,self).__init__()

        # what is drawn
        if flags is None:
            flags = ['shape','joint','particle']#,'aabb','pair','center_of_mass','particle']
        self.flags = flags
        self.clear_flags(['shape','joint','aabb','pair','center_of_mass','particle'])
        for flag in flags:
            self.append_flags(flag)

        # the image to draw on
        self._image = image


    def draw_solid_polygons(self, points, sizes, colors):
        self._draw_polygons(points, sizes, colors, True)

    def draw_polygons(self, points, sizes, colors):
        self._draw_polygons(points, sizes, colors, False)

    def _draw_polygons(self, points, sizes, colors, fill):
        line_type = 8
        n_polygons = sizes.shape[0]
        start = 0
        for i in range(n_polygons):
            s = sizes[i]
            p = points[start:start+s,:].astype('int32')
            color = tuple(map(int, colors[i,:]))
            if fill:
                cv.fillPoly(self._image, [p], color, line_type)
            else:
                cv.polylines(self._image, [p], True, color, line_type)
            start += s



    def draw_solid_circles(self, centers, radii, axis, colors):
        self._draw_circles(centers, radii, colors, lw=-1)
        
    def draw_circles(self, centers, radii, colors):
        self._draw_circles(centers, radii, colors, lw=1)

    def _draw_circles(self, centers, radii,  colors, lw):
        line_type = 8
        thickness = 1
        n = centers.shape[0]
        for i in range(n):
            color = tuple(map(int, colors[i,:]))
            cv.circle(self._image,
                       centers[i,:].astype('int32'),
                       radii[i].astype('int32'),
                       color,
                       lw,
                       line_type)


    def draw_points(self, centers, sizes, colors):
        pass

    def draw_segments(self, points, colors):
        line_type = 8
        thickness = 1

        n  = points.shape[0]
        for i in range(n):
            color = tuple(map(int, colors[i,:]))
            cv.line(self._image,
                points[i,0,:].astype('int32'),
                points[i,1,:].astype('int32'),  
                color)


    def draw_particles(self, centers, radius, colors=None):
    
        default_color = (255,255,255,255)

        n_particles = centers.shape[0]
        centers -= radius
        d = 2 * radius
        for i in range(n_particles):

            if colors is None:
                c = default_color
            else:
                color = tuple(map(int, colors[i,:]))

            p0 = (centers[i,:] - radius).astype('int32')
            p1 = (p0 + 2*radius).astype('int32')
            cv.rectangle(self._image, p0, p1, color,-1)
