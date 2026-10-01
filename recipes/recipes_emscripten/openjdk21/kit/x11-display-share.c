/* x11.wasm has one display: XOpenDisplay always returns the same Display.
 * AWT's Motif drag-and-drop code opens a "second connection" and closes it
 * (MotifDnDConstants.createMotifWindow), which here would close AWT's own.
 * Only really close on the last close. Linked into GUI builds with
 * -Wl,--wrap=XOpenDisplay -Wl,--wrap=XCloseDisplay. */
#include <X11/Xlib.h>

Display *__real_XOpenDisplay(const char *name);
int __real_XCloseDisplay(Display *dpy);

static int open_count;   /* AWT calls these with its lock held */

Display *__wrap_XOpenDisplay(const char *name) {
    Display *d = __real_XOpenDisplay(name);
    if (d != NULL) open_count++;
    return d;
}

int __wrap_XCloseDisplay(Display *dpy) {
    if (open_count > 1) {
        open_count--;
        return XSync(dpy, False);
    }
    open_count = 0;
    return __real_XCloseDisplay(dpy);
}
