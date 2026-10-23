/*
 * x11ext_stubs.c -- link-time stand-ins for the X11 extension libraries that
 * OpenJDK's AWT (libawt_xawt, libsplashscreen) references but that x11.wasm
 * does not implement: libXext (SHAPE, MIT-SHM, DOUBLE-BUFFER), libXrender,
 * libXtst, libXi, and the XKB entry points normally found in libX11.
 *
 * x11.wasm's XQueryExtension() reports none of these extensions as present,
 * and every stub below that answers a "query" says "not available", so AWT
 * takes its core-X11 fallback paths:
 *   - no MIT-SHM      -> plain XPutImage/XGetImage
 *   - no RENDER       -> X11 (core) Java2D pipeline, not the XRender one
 *   - no XKB          -> core keyboard mapping (XKeycodeToKeysym etc.)
 *   - no SHAPE / DBE  -> no shaped windows, no DBE page flipping
 *   - no XTEST        -> java.awt.Robot unavailable
 * The remaining stubs exist only so the final link resolves; AWT does not
 * call them once the corresponding query has returned False.
 *
 * Xrandr and Xinerama are not stubbed: AWT reaches them through dlopen/dlsym,
 * which simply fails in a static wasm build.
 */

#include <stddef.h>
#include <string.h>

#include <X11/Xlib.h>
#include <X11/XKBlib.h>
#include <X11/extensions/Xrender.h>
#include <X11/extensions/shape.h>
#include <X11/extensions/Xdbe.h>
#include <X11/extensions/XTest.h>
#include <X11/extensions/XShm.h>
#include <X11/extensions/XInput.h>

#define UNUSED(x) (void)(x)

/* ------------------------------------------------------- SysV shared memory
 * Emscripten's libc has no shmget/shmat. AWT only calls them after
 * XShmQueryExtension() succeeds, which it never does here; these weak
 * definitions satisfy the link and fail cleanly if reached anyway. */

#include <errno.h>
#include <sys/types.h>

struct shmid_ds;

__attribute__((weak)) int shmget(key_t key, size_t size, int flags)
{
    UNUSED(key); UNUSED(size); UNUSED(flags);
    errno = ENOSYS;
    return -1;
}

__attribute__((weak)) void *shmat(int id, const void *addr, int flags)
{
    UNUSED(id); UNUSED(addr); UNUSED(flags);
    errno = ENOSYS;
    return (void *) -1;
}

__attribute__((weak)) int shmdt(const void *addr)
{
    UNUSED(addr);
    errno = ENOSYS;
    return -1;
}

__attribute__((weak)) int shmctl(int id, int cmd, struct shmid_ds *buf)
{
    UNUSED(id); UNUSED(cmd); UNUSED(buf);
    errno = ENOSYS;
    return -1;
}

/* ------------------------------------------------------------------ SHAPE */

Bool XShapeQueryExtension(Display *d, int *event_base, int *error_base)
{
    UNUSED(d);
    if (event_base) *event_base = 0;
    if (error_base) *error_base = 0;
    return False;
}

Status XShapeQueryVersion(Display *d, int *major, int *minor)
{
    UNUSED(d);
    if (major) *major = 0;
    if (minor) *minor = 0;
    return 0;
}

void XShapeCombineMask(Display *d, Window w, int dest_kind, int x_off,
                       int y_off, Pixmap src, int op)
{
    UNUSED(d); UNUSED(w); UNUSED(dest_kind); UNUSED(x_off); UNUSED(y_off);
    UNUSED(src); UNUSED(op);
}

void XShapeCombineRectangles(Display *d, Window w, int dest_kind, int x_off,
                             int y_off, XRectangle *rects, int n_rects,
                             int op, int ordering)
{
    UNUSED(d); UNUSED(w); UNUSED(dest_kind); UNUSED(x_off); UNUSED(y_off);
    UNUSED(rects); UNUSED(n_rects); UNUSED(op); UNUSED(ordering);
}

/* ---------------------------------------------------------------- MIT-SHM */

Bool XShmQueryExtension(Display *d)
{
    UNUSED(d);
    return False;
}

Bool XShmQueryVersion(Display *d, int *major, int *minor, Bool *pixmaps)
{
    UNUSED(d);
    if (major) *major = 0;
    if (minor) *minor = 0;
    if (pixmaps) *pixmaps = False;
    return False;
}

int XShmPixmapFormat(Display *d)
{
    UNUSED(d);
    return 0;
}

Bool XShmAttach(Display *d, XShmSegmentInfo *info)
{
    UNUSED(d); UNUSED(info);
    return False;
}

Bool XShmDetach(Display *d, XShmSegmentInfo *info)
{
    UNUSED(d); UNUSED(info);
    return False;
}

XImage *XShmCreateImage(Display *d, Visual *v, unsigned int depth, int format,
                        char *data, XShmSegmentInfo *info, unsigned int width,
                        unsigned int height)
{
    UNUSED(d); UNUSED(v); UNUSED(depth); UNUSED(format); UNUSED(data);
    UNUSED(info); UNUSED(width); UNUSED(height);
    return NULL;
}

Pixmap XShmCreatePixmap(Display *d, Drawable dr, char *data,
                        XShmSegmentInfo *info, unsigned int width,
                        unsigned int height, unsigned int depth)
{
    UNUSED(d); UNUSED(dr); UNUSED(data); UNUSED(info); UNUSED(width);
    UNUSED(height); UNUSED(depth);
    return None;
}

Bool XShmGetImage(Display *d, Drawable dr, XImage *img, int x, int y,
                  unsigned long plane_mask)
{
    UNUSED(d); UNUSED(dr); UNUSED(img); UNUSED(x); UNUSED(y);
    UNUSED(plane_mask);
    return False;
}

Bool XShmPutImage(Display *d, Drawable dr, GC gc, XImage *img, int src_x,
                  int src_y, int dst_x, int dst_y, unsigned int width,
                  unsigned int height, Bool send_event)
{
    UNUSED(d); UNUSED(dr); UNUSED(gc); UNUSED(img); UNUSED(src_x);
    UNUSED(src_y); UNUSED(dst_x); UNUSED(dst_y); UNUSED(width); UNUSED(height);
    UNUSED(send_event);
    return False;
}

/* ---------------------------------------------------------- DOUBLE-BUFFER */

Status XdbeQueryExtension(Display *d, int *major, int *minor)
{
    UNUSED(d);
    if (major) *major = 0;
    if (minor) *minor = 0;
    return 0;
}

XdbeScreenVisualInfo *XdbeGetVisualInfo(Display *d, Drawable *screens,
                                        int *num_screens)
{
    UNUSED(d); UNUSED(screens);
    if (num_screens) *num_screens = 0;
    return NULL;
}

void XdbeFreeVisualInfo(XdbeScreenVisualInfo *info)
{
    UNUSED(info);
}

XdbeBackBuffer XdbeAllocateBackBufferName(Display *d, Window w,
                                          XdbeSwapAction action)
{
    UNUSED(d); UNUSED(w); UNUSED(action);
    return None;
}

Status XdbeDeallocateBackBufferName(Display *d, XdbeBackBuffer buf)
{
    UNUSED(d); UNUSED(buf);
    return 0;
}

Status XdbeSwapBuffers(Display *d, XdbeSwapInfo *info, int num_windows)
{
    UNUSED(d); UNUSED(info); UNUSED(num_windows);
    return 0;
}

Status XdbeBeginIdiom(Display *d)
{
    UNUSED(d);
    return 0;
}

Status XdbeEndIdiom(Display *d)
{
    UNUSED(d);
    return 0;
}

/* ----------------------------------------------------------------- RENDER */

XRenderPictFormat *XRenderFindVisualFormat(Display *d, _Xconst Visual *v)
{
    UNUSED(d); UNUSED(v);
    return NULL;
}

XRenderPictFormat *XRenderFindStandardFormat(Display *d, int format)
{
    UNUSED(d); UNUSED(format);
    return NULL;
}

Picture XRenderCreatePicture(Display *d, Drawable dr,
                             _Xconst XRenderPictFormat *format,
                             unsigned long valuemask,
                             _Xconst XRenderPictureAttributes *attributes)
{
    UNUSED(d); UNUSED(dr); UNUSED(format); UNUSED(valuemask);
    UNUSED(attributes);
    return None;
}

Picture XRenderCreateLinearGradient(Display *d,
                                    _Xconst XLinearGradient *gradient,
                                    _Xconst XFixed *stops,
                                    _Xconst XRenderColor *colors, int nstops)
{
    UNUSED(d); UNUSED(gradient); UNUSED(stops); UNUSED(colors); UNUSED(nstops);
    return None;
}

Picture XRenderCreateRadialGradient(Display *d,
                                    _Xconst XRadialGradient *gradient,
                                    _Xconst XFixed *stops,
                                    _Xconst XRenderColor *colors, int nstops)
{
    UNUSED(d); UNUSED(gradient); UNUSED(stops); UNUSED(colors); UNUSED(nstops);
    return None;
}

void XRenderChangePicture(Display *d, Picture p, unsigned long valuemask,
                          _Xconst XRenderPictureAttributes *attributes)
{
    UNUSED(d); UNUSED(p); UNUSED(valuemask); UNUSED(attributes);
}

void XRenderFreePicture(Display *d, Picture p)
{
    UNUSED(d); UNUSED(p);
}

void XRenderSetPictureClipRectangles(Display *d, Picture p, int x_origin,
                                     int y_origin, _Xconst XRectangle *rects,
                                     int n)
{
    UNUSED(d); UNUSED(p); UNUSED(x_origin); UNUSED(y_origin); UNUSED(rects);
    UNUSED(n);
}

void XRenderSetPictureFilter(Display *d, Picture p, _Xconst char *filter,
                             XFixed *params, int nparams)
{
    UNUSED(d); UNUSED(p); UNUSED(filter); UNUSED(params); UNUSED(nparams);
}

void XRenderSetPictureTransform(Display *d, Picture p, XTransform *transform)
{
    UNUSED(d); UNUSED(p); UNUSED(transform);
}

void XRenderComposite(Display *d, int op, Picture src, Picture mask,
                      Picture dst, int src_x, int src_y, int mask_x,
                      int mask_y, int dst_x, int dst_y, unsigned int width,
                      unsigned int height)
{
    UNUSED(d); UNUSED(op); UNUSED(src); UNUSED(mask); UNUSED(dst);
    UNUSED(src_x); UNUSED(src_y); UNUSED(mask_x); UNUSED(mask_y);
    UNUSED(dst_x); UNUSED(dst_y); UNUSED(width); UNUSED(height);
}

void XRenderFillRectangle(Display *d, int op, Picture dst,
                          _Xconst XRenderColor *color, int x, int y,
                          unsigned int width, unsigned int height)
{
    UNUSED(d); UNUSED(op); UNUSED(dst); UNUSED(color); UNUSED(x); UNUSED(y);
    UNUSED(width); UNUSED(height);
}

void XRenderFillRectangles(Display *d, int op, Picture dst,
                           _Xconst XRenderColor *color,
                           _Xconst XRectangle *rectangles, int n_rects)
{
    UNUSED(d); UNUSED(op); UNUSED(dst); UNUSED(color); UNUSED(rectangles);
    UNUSED(n_rects);
}

GlyphSet XRenderCreateGlyphSet(Display *d, _Xconst XRenderPictFormat *format)
{
    UNUSED(d); UNUSED(format);
    return None;
}

void XRenderAddGlyphs(Display *d, GlyphSet glyphset, _Xconst Glyph *gids,
                      _Xconst XGlyphInfo *glyphs, int nglyphs,
                      _Xconst char *images, int nbyte_images)
{
    UNUSED(d); UNUSED(glyphset); UNUSED(gids); UNUSED(glyphs);
    UNUSED(nglyphs); UNUSED(images); UNUSED(nbyte_images);
}

void XRenderFreeGlyphs(Display *d, GlyphSet glyphset, _Xconst Glyph *gids,
                       int nglyphs)
{
    UNUSED(d); UNUSED(glyphset); UNUSED(gids); UNUSED(nglyphs);
}

void XRenderCompositeText32(Display *d, int op, Picture src, Picture dst,
                            _Xconst XRenderPictFormat *mask_format, int x_src,
                            int y_src, int x_dst, int y_dst,
                            _Xconst XGlyphElt32 *elts, int nelt)
{
    UNUSED(d); UNUSED(op); UNUSED(src); UNUSED(dst); UNUSED(mask_format);
    UNUSED(x_src); UNUSED(y_src); UNUSED(x_dst); UNUSED(y_dst); UNUSED(elts);
    UNUSED(nelt);
}

void XRenderCompositeTrapezoids(Display *d, int op, Picture src, Picture dst,
                                _Xconst XRenderPictFormat *mask_format,
                                int x_src, int y_src,
                                _Xconst XTrapezoid *traps, int ntrap)
{
    UNUSED(d); UNUSED(op); UNUSED(src); UNUSED(dst); UNUSED(mask_format);
    UNUSED(x_src); UNUSED(y_src); UNUSED(traps); UNUSED(ntrap);
}

/* ------------------------------------------------------------------ XTEST */

Bool XTestQueryExtension(Display *d, int *event_base, int *error_base,
                         int *major, int *minor)
{
    UNUSED(d);
    if (event_base) *event_base = 0;
    if (error_base) *error_base = 0;
    if (major) *major = 0;
    if (minor) *minor = 0;
    return False;
}

int XTestFakeKeyEvent(Display *d, unsigned int keycode, Bool is_press,
                      unsigned long delay)
{
    UNUSED(d); UNUSED(keycode); UNUSED(is_press); UNUSED(delay);
    return 0;
}

int XTestFakeButtonEvent(Display *d, unsigned int button, Bool is_press,
                         unsigned long delay)
{
    UNUSED(d); UNUSED(button); UNUSED(is_press); UNUSED(delay);
    return 0;
}

int XTestGrabControl(Display *d, Bool impervious)
{
    UNUSED(d); UNUSED(impervious);
    return 0;
}

/* ----------------------------------------------------------------- XInput */

XDeviceInfo *XListInputDevices(Display *d, int *ndevices)
{
    UNUSED(d);
    if (ndevices) *ndevices = 0;
    return NULL;
}

void XFreeDeviceList(XDeviceInfo *list)
{
    UNUSED(list);
}

/* -------------------------------------------------------------------- XKB */

Bool XkbIgnoreExtension(Bool ignore)
{
    UNUSED(ignore);
    return True;
}

Bool XkbLibraryVersion(int *major, int *minor)
{
    /* Report the version the caller asked about so AWT goes on to call
     * XkbQueryExtension, which is what actually says "no XKB here". */
    UNUSED(major); UNUSED(minor);
    return True;
}

Bool XkbQueryExtension(Display *d, int *opcode, int *event_base,
                       int *error_base, int *major, int *minor)
{
    UNUSED(d); UNUSED(major); UNUSED(minor);
    if (opcode) *opcode = 0;
    if (event_base) *event_base = 0;
    if (error_base) *error_base = 0;
    return False;
}

Bool XkbSelectEvents(Display *d, unsigned int device, unsigned int affect,
                     unsigned int values)
{
    UNUSED(d); UNUSED(device); UNUSED(affect); UNUSED(values);
    return False;
}

Bool XkbSelectEventDetails(Display *d, unsigned int device,
                           unsigned int event_type, unsigned long affect,
                           unsigned long details)
{
    UNUSED(d); UNUSED(device); UNUSED(event_type); UNUSED(affect);
    UNUSED(details);
    return False;
}

XkbDescPtr XkbGetMap(Display *d, unsigned int which, unsigned int device)
{
    UNUSED(d); UNUSED(which); UNUSED(device);
    return NULL;
}

Status XkbGetUpdatedMap(Display *d, unsigned int which, XkbDescPtr desc)
{
    UNUSED(d); UNUSED(which); UNUSED(desc);
    return BadImplementation;
}

void XkbFreeKeyboard(XkbDescPtr desc, unsigned int which, Bool free_all)
{
    UNUSED(desc); UNUSED(which); UNUSED(free_all);
}

Bool XkbTranslateKeyCode(XkbDescPtr desc, KeyCode keycode,
                         unsigned int modifiers,
                         unsigned int *modifiers_return,
                         KeySym *keysym_return)
{
    UNUSED(desc); UNUSED(keycode); UNUSED(modifiers);
    if (modifiers_return) *modifiers_return = 0;
    if (keysym_return) *keysym_return = NoSymbol;
    return False;
}

Bool XkbSetDetectableAutoRepeat(Display *d, Bool detectable,
                                Bool *supported_return)
{
    UNUSED(d); UNUSED(detectable);
    if (supported_return) *supported_return = False;
    return False;
}

Status XkbGetState(Display *d, unsigned int device, XkbStatePtr state)
{
    UNUSED(d); UNUSED(device);
    if (state) memset(state, 0, sizeof(*state));
    return BadImplementation;
}
