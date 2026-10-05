/*
 * Copyright (c) 2026 emscripten-forge contributors.
 * Licensed under the GNU General Public License version 2 with the
 * Classpath exception, like OpenJDK.
 */
package netscape.javascript;

/** Thrown when a JavaScript operation fails (LiveConnect API). */
public class JSException extends RuntimeException {
    private static final long serialVersionUID = 2778103758223661489L;

    public JSException() {
        super();
    }

    public JSException(String s) {
        super(s);
    }
}
