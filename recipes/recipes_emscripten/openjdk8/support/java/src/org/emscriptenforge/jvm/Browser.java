/*
 * Copyright (c) 2026 emscripten-forge contributors.
 * Licensed under the GNU General Public License version 2 with the
 * Classpath exception, like OpenJDK.
 */
package org.emscriptenforge.jvm;

import java.net.MalformedURLException;
import java.net.URL;
import java.security.AccessController;
import java.security.PrivilegedAction;

/**
 * Services of the web page that hosts the WebAssembly Java runtime.
 */
public final class Browser {

    static {
        AccessController.doPrivileged(new PrivilegedAction<Void>() {
            public Void run() {
                System.loadLibrary("wasmrt");
                return null;
            }
        });
    }

    private Browser() {}

    /** Opens {@code url} in the browser window/frame {@code target}. */
    public static void showDocument(URL url, String target) {
        if (url != null) showDocument0(url.toExternalForm(), target == null ? "_self" : target);
    }

    /** Shows a status message (forwarded to the page's status handler). */
    public static void showStatus(String text) {
        showStatus0(text == null ? "" : text);
    }

    /** The URL of the hosting page. */
    public static URL pageURL() {
        try {
            return new URL(pageURL0());
        } catch (MalformedURLException e) {
            return null;
        }
    }

    // LiveConnect operations, see netscape.javascript.JSObject
    static final int OP_GET = 0, OP_SET = 1, OP_REMOVE = 2, OP_CALL = 3, OP_EVAL = 4,
                     OP_GET_SLOT = 5, OP_SET_SLOT = 6, OP_TO_STRING = 7, OP_RELEASE = 8;

    static String jsOp(int op, int handle, String name, String args) {
        return jsOp0(op, handle, name, args);
    }

    private static native void showDocument0(String url, String target);
    private static native void showStatus0(String text);
    private static native String pageURL0();
    private static native String jsOp0(int op, int handle, String name, String args);
}
