/*
 * Copyright (c) 2026 emscripten-forge contributors.
 * Licensed under the GNU General Public License version 2 with the
 * Classpath exception, like OpenJDK.
 */
package org.emscriptenforge.jvm.net.https;

import java.io.IOException;
import java.net.Proxy;
import java.net.URL;
import java.net.URLConnection;
import java.net.URLStreamHandler;

import org.emscriptenforge.jvm.net.FetchURLConnection;

/** https: URLs through the browser's fetch(). */
public class Handler extends URLStreamHandler {
    protected URLConnection openConnection(URL u) throws IOException {
        return new FetchURLConnection(u);
    }

    protected URLConnection openConnection(URL u, Proxy p) throws IOException {
        return new FetchURLConnection(u);
    }

    protected int getDefaultPort() {
        return 443;
    }
}
