import ctypes

import pytest


class _WebGLContextAttributes(ctypes.Structure):
    """`EmscriptenWebGLContextAttributes` (emscripten/html5_webgl.h)."""

    _fields_ = [
        ("alpha", ctypes.c_bool),
        ("depth", ctypes.c_bool),
        ("stencil", ctypes.c_bool),
        ("antialias", ctypes.c_bool),
        ("premultipliedAlpha", ctypes.c_bool),
        ("preserveDrawingBuffer", ctypes.c_bool),
        ("powerPreference", ctypes.c_int),
        ("failIfMajorPerformanceCaveat", ctypes.c_bool),
        ("majorVersion", ctypes.c_int),
        ("minorVersion", ctypes.c_int),
        ("enableExtensionsByDefault", ctypes.c_bool),
        ("explicitSwapControl", ctypes.c_bool),
        ("proxyContextToMainThread", ctypes.c_int),
        ("renderViaOffscreenBackBuffer", ctypes.c_bool),
        ("desynchronized", ctypes.c_bool),
    ]


@pytest.fixture
def webgl2_context():
    """A current WebGL2 context on a new canvas (main thread: DOM canvas,
    worker: OffscreenCanvas); skips without WebGL2."""
    import pyjs

    if pyjs.js.Reflect.has(pyjs.js.globalThis, "document"):
        canvas = pyjs.js.document.createElement("canvas")
    elif pyjs.js.Reflect.has(pyjs.js.globalThis, "OffscreenCanvas"):
        canvas = pyjs.new(pyjs.js.OffscreenCanvas, 64, 64)
    else:
        pytest.skip("no canvas")
    canvas.width = 64
    canvas.height = 64
    pyjs.set_canvas(canvas)

    lib = ctypes.CDLL(None)
    attrs = _WebGLContextAttributes()
    lib.emscripten_webgl_init_context_attributes(ctypes.byref(attrs))
    attrs.majorVersion = 2
    create = lib.emscripten_webgl_create_context
    create.restype = ctypes.c_size_t
    create.argtypes = [ctypes.c_char_p, ctypes.POINTER(_WebGLContextAttributes)]
    ctx = create(b"#canvas", ctypes.byref(attrs))
    if ctx == 0:
        pytest.skip("no WebGL2 context")
    lib.emscripten_webgl_make_context_current.argtypes = [ctypes.c_size_t]
    assert lib.emscripten_webgl_make_context_current(ctx) == 0
    yield ctx
    lib.emscripten_webgl_destroy_context.argtypes = [ctypes.c_size_t]
    lib.emscripten_webgl_destroy_context(ctx)


def test_import():
    import OpenGL
    from OpenGL import GL  # noqa: F401
    from OpenGL import platform

    assert type(platform.PLATFORM).__name__ == "EmscriptenPlatform"


def test_gl_calls(webgl2_context):
    from OpenGL import GL

    version = GL.glGetString(GL.GL_VERSION)
    assert version.startswith(b"OpenGL ES 3.0"), version
    GL.glClearColor(0.0, 0.5, 1.0, 1.0)
    GL.glClear(GL.GL_COLOR_BUFFER_BIT)
    assert GL.glGetError() == GL.GL_NO_ERROR


def test_buffers_and_shaders(webgl2_context):
    """The modern GL used by e.g. pyb2d3's OpenGL frontend: VAO, VBO from a
    numpy array, GLSL ES 3.00 shaders, instanced draw."""
    import numpy as np
    from OpenGL import GL

    vao = GL.glGenVertexArrays(1)
    GL.glBindVertexArray(vao)
    vbo = GL.glGenBuffers(1)
    GL.glBindBuffer(GL.GL_ARRAY_BUFFER, vbo)
    data = np.array([0, 0, 1, 0, 0, 1], dtype=np.float32)
    GL.glBufferData(GL.GL_ARRAY_BUFFER, data.nbytes, data, GL.GL_STATIC_DRAW)
    GL.glVertexAttribPointer(0, 2, GL.GL_FLOAT, GL.GL_FALSE, 0, ctypes.c_void_p(0))
    GL.glEnableVertexAttribArray(0)

    vs = GL.glCreateShader(GL.GL_VERTEX_SHADER)
    GL.glShaderSource(vs, "#version 300 es\nlayout(location=0) in vec2 p;\n"
                          "void main(){ gl_Position = vec4(p, 0.0, 1.0); }\n")
    GL.glCompileShader(vs)
    assert GL.glGetShaderiv(vs, GL.GL_COMPILE_STATUS), GL.glGetShaderInfoLog(vs)
    fs = GL.glCreateShader(GL.GL_FRAGMENT_SHADER)
    GL.glShaderSource(fs, "#version 300 es\nprecision highp float;\nout vec4 c;\n"
                          "void main(){ c = vec4(1.0); }\n")
    GL.glCompileShader(fs)
    assert GL.glGetShaderiv(fs, GL.GL_COMPILE_STATUS), GL.glGetShaderInfoLog(fs)
    prog = GL.glCreateProgram()
    GL.glAttachShader(prog, vs)
    GL.glAttachShader(prog, fs)
    GL.glLinkProgram(prog)
    assert GL.glGetProgramiv(prog, GL.GL_LINK_STATUS), GL.glGetProgramInfoLog(prog)

    GL.glUseProgram(prog)
    GL.glDrawArraysInstanced(GL.GL_TRIANGLES, 0, 3, 2)
    assert GL.glGetError() == GL.GL_NO_ERROR

    GL.glDeleteProgram(prog)
    GL.glDeleteShader(vs)
    GL.glDeleteShader(fs)
    GL.glDeleteBuffers(1, [vbo])
    GL.glDeleteVertexArrays(1, [vao])
