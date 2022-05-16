import b2d



class JupyterBatchDebugDraw(b2d.BatchDebugDrawNew):

    def __init__(self, canvas, flags=None):
        super(JupyterBatchDebugDraw,self).__init__()

        # what is drawn
        if flags is None:
            flags = ['shape','joint','aabb','pair','center_of_mass','particle']
        self.flags = flags
        self.clear_flags(['shape','joint','aabb','pair','center_of_mass','particle'])
        for flag in flags:
            self.append_flags(flag)

        # the canvas to draw on
        self._canvas = canvas

    def draw_solid_polygons(self, points, sizes, colors):
        self._canvas.fill_styled_polygons(
            points=points.ravel(),
            sizes=sizes,
            color=colors.ravel(),
            alpha=1.0
        )

    def draw_polygons(self, points, sizes, colors):
        self._canvas.stroke_styled_polygons(
            points=points.ravel(),
            sizes=sizes,
            color=colors.ravel(),
            alpha=1.0
        )

    def draw_solid_circles(self, centers, radii, axis, colors):
        
        # ignore axis atm
        self._canvas.fill_styled_circles(
            centers[:,0],
            centers[:,1],
            radii,
            colors.ravel(),
            1.0
        )
        
    def draw_circles(self, centers, radii, colors):
        self._canvas.stroke_styled_circles(
            centers[:,0],
            centers[:,1],
            radii,
            color=colors.ravel(),
            alpha=1.0
        )

    def draw_points(self, centers, sizes, colors):
        self._canvas.stroke_styled_circles(
            centers,
            sizes,
            color=colors.ravel(),
            alpha=1.0
        )

    def draw_segments(self, points, colors):
        self._canvas.stroke_styled_line_segments(
            points=points,
            color=colors.ravel(),
            alpha=1.0
        )


    def draw_particles(self, centers, radius, colors=None):



        if colors is None:

            # print("draw_particles",centers.shape, radius)
            r = radius
            self._canvas.save()
            self._canvas.translate(x=-r, y=-r)
            self._canvas.fill_style = "rgba(0,100,255,1)" 
            self._canvas.fill_rects(centers[:,0], centers[:,1], r*2)
            self._canvas.restore()

            # for r_mult,a in zip([2], [0.5]):
            #     r = radius * r_mult
            #     self._canvas.save()
            #     self._canvas.translate(x=-r, y=-r)
            #     self._canvas.fill_style = f"rgba(0,255,0,{a*0.7})" 
            #     self._canvas.fill_rects(centers[:,0], centers[:,1], r*2)
            #     self._canvas.restore()

        else:
            alpha = (colors[:,3])/255.0
            colors = colors[:,0:3]

            r = radius
            self._canvas.save()
            self._canvas.translate(x=-r, y=-r)
            self._canvas.fill_styled_rects(centers[:,0], centers[:,1], r*2, r*2, colors, alpha)
            self._canvas.restore()


     
        # self._canvas.fill_style = "rgba(0,255,0,0.3)" 
        # self._canvas.fill_rects(centers[:,0], centers[:,1], radius*2 * 1.2)

        # centers += radius 
        # centers -= radius * 8
        # self._canvas.fill_style = "rgba(0,255,0,0.01)" 
        # self._canvas.fill_rects(centers[:,0], centers[:,1], radius*16)

