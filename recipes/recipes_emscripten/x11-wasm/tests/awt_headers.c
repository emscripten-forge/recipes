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

/* Every header OpenJDK's AWT includes, plus calls into core Xlib and each
 * stubbed extension, so the link has to resolve all of them. */
int main(void) {
    XRenderPictFormat *f = 0; XkbDescPtr k = 0; XShmSegmentInfo s; XdbeSwapInfo d;
    (void) f; (void) k; (void) s; (void) d;
    int ev, er, maj, min;
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
