import cairo

def test_version():
    assert cairo.version is not None
    assert cairo.cairo_version() > 0

def test_surface():
    surface = cairo.ImageSurface(cairo.FORMAT_ARGB32, 100, 100)
    assert surface.get_width() == 100
    assert surface.get_height() == 100

def test_context():
    surface = cairo.ImageSurface(cairo.FORMAT_ARGB32, 100, 100)
    ctx = cairo.Context(surface)
    ctx.set_source_rgb(1, 0, 0)
    ctx.rectangle(10, 10, 50, 50)
    ctx.fill()
