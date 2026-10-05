/*
 * Copyright (c) 2026 emscripten-forge contributors.
 * Licensed under the GNU General Public License version 2 with the
 * Classpath exception, like OpenJDK.
 */
package netscape.javascript;

import java.applet.Applet;

/**
 * LiveConnect access to JavaScript objects of the page hosting an applet.
 */
public abstract class JSObject {

    protected JSObject() {}

    public abstract Object call(String methodName, Object[] args) throws JSException;

    public abstract Object eval(String s) throws JSException;

    public abstract Object getMember(String name) throws JSException;

    public abstract void setMember(String name, Object value) throws JSException;

    public abstract void removeMember(String name) throws JSException;

    public abstract Object getSlot(int index) throws JSException;

    public abstract void setSlot(int index, Object value) throws JSException;

    /** Returns the JavaScript {@code window} object of the applet's page. */
    public static JSObject getWindow(Applet applet) throws JSException {
        return org.emscriptenforge.jvm.BrowserJSObject.WINDOW;
    }
}
