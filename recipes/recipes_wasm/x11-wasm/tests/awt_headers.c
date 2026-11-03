#include <X11/Xlib.h>
#include <X11/Xutil.h>
#include <X11/Xatom.h>
#include <X11/X.h>
#include <X11/Xmd.h>
#include <X11/Xos.h>
#include <X11/Xproto.h>
#include <X11/Xfuncproto.h>
#include <X11/keysym.h>
#include <X11/keysymdef.h>
#include <X11/Sunkeysym.h>
#include <X11/HPkeysym.h>
#include <X11/DECkeysym.h>
#include <X11/ap_keysym.h>
#include <X11/cursorfont.h>
#include <X11/XKBlib.h>
#include <X11/extensions/Xrender.h>
#include <X11/extensions/shape.h>
#include <X11/extensions/Xdbe.h>
#include <X11/extensions/XTest.h>
#include <X11/extensions/xtestext1.h>
#include <X11/extensions/XShm.h>
#include <X11/extensions/shmproto.h>
#include <X11/extensions/Xrandr.h>
#include <X11/extensions/XInput.h>
#include <X11/extensions/XI.h>
#include <X11/extensions/randr.h>
#include <X11/Intrinsic.h>
#include <X11/IntrinsicP.h>
#include <X11/StringDefs.h>
#include <X11/Shell.h>
#include <X11Wasm/Hooks.h>

/* Every extension entry point libawt_xawt references (OpenJDK 8), so the
 * link fails if a stub is missing. */
static void (*volatile const jdk_extension_refs[])(void) = {
    (void (*)(void)) XFreeDeviceList, (void (*)(void)) XListInputDevices,
    (void (*)(void)) XRenderAddGlyphs, (void (*)(void)) XRenderChangePicture,
    (void (*)(void)) XRenderComposite,
    (void (*)(void)) XRenderCompositeText32,
    (void (*)(void)) XRenderCompositeTrapezoids,
    (void (*)(void)) XRenderCreateGlyphSet,
    (void (*)(void)) XRenderCreateLinearGradient,
    (void (*)(void)) XRenderCreatePicture,
    (void (*)(void)) XRenderCreateRadialGradient,
    (void (*)(void)) XRenderFillRectangle,
    (void (*)(void)) XRenderFillRectangles,
    (void (*)(void)) XRenderFindStandardFormat,
    (void (*)(void)) XRenderFreeGlyphs, (void (*)(void)) XRenderFreePicture,
    (void (*)(void)) XRenderSetPictureClipRectangles,
    (void (*)(void)) XRenderSetPictureFilter,
    (void (*)(void)) XRenderSetPictureTransform,
    (void (*)(void)) XShapeCombineMask,
    (void (*)(void)) XShapeCombineRectangles,
    (void (*)(void)) XShapeQueryExtension,
    (void (*)(void)) XShapeQueryVersion, (void (*)(void)) XShmAttach,
    (void (*)(void)) XShmCreateImage, (void (*)(void)) XShmCreatePixmap,
    (void (*)(void)) XShmDetach, (void (*)(void)) XShmGetImage,
    (void (*)(void)) XShmPixmapFormat, (void (*)(void)) XShmPutImage,
    (void (*)(void)) XShmQueryExtension, (void (*)(void)) XShmQueryVersion,
    (void (*)(void)) XTestFakeButtonEvent, (void (*)(void)) XTestFakeKeyEvent,
    (void (*)(void)) XTestGrabControl, (void (*)(void)) XTestQueryExtension,
    (void (*)(void)) XdbeAllocateBackBufferName,
    (void (*)(void)) XdbeBeginIdiom,
    (void (*)(void)) XdbeDeallocateBackBufferName,
    (void (*)(void)) XdbeEndIdiom, (void (*)(void)) XdbeGetVisualInfo,
    (void (*)(void)) XdbeQueryExtension, (void (*)(void)) XdbeSwapBuffers,
    (void (*)(void)) XkbFreeKeyboard, (void (*)(void)) XkbGetMap,
    (void (*)(void)) XkbGetState, (void (*)(void)) XkbGetUpdatedMap,
    (void (*)(void)) XkbIgnoreExtension, (void (*)(void)) XkbKeycodeToKeysym,
    (void (*)(void)) XkbLibraryVersion, (void (*)(void)) XkbQueryExtension,
    (void (*)(void)) XkbSelectEventDetails, (void (*)(void)) XkbSelectEvents,
    (void (*)(void)) XkbSetDetectableAutoRepeat,
    (void (*)(void)) XkbTranslateKeyCode,
};

/* Every header OpenJDK's AWT includes, plus calls into core Xlib and each
 * stubbed extension, so the link has to resolve all of them. */
int main(void) {
    XRenderPictFormat *f = 0; XkbDescPtr k = 0; XShmSegmentInfo s; XdbeSwapInfo d;
    (void) f; (void) k; (void) s; (void) d;
    if (jdk_extension_refs[0] == NULL) return 2;
    int ev, er, maj, min;
    X11WasmHooks hooks = { 0, 0, -1 };
    X11WasmSetHooks(&hooks);
    Display *dpy = XOpenDisplay(NULL);
    if (dpy == NULL) return 1;
    Window w = XCreateSimpleWindow(dpy, DefaultRootWindow(dpy), 0, 0, 10, 10, 0, 0, 0);
    XMapWindow(dpy, w);
    XFlush(dpy);
    int ok = !XShmQueryExtension(dpy) && !XShapeQueryExtension(dpy, &ev, &er)
          && !XTestQueryExtension(dpy, &ev, &er, &maj, &min)
          && XRenderFindVisualFormat(dpy, DefaultVisual(dpy, 0)) == NULL
          && !XkbQueryExtension(dpy, &ev, &ev, &er, &maj, &min);
    XCloseDisplay(dpy);
    return ok ? 0 : 1;
}
