/*
 * Copyright (c) 2026 emscripten-forge contributors.
 * Licensed under the GNU General Public License version 2 with the
 * Classpath exception, like OpenJDK.
 */
package org.emscriptenforge.jvm;

import netscape.javascript.JSException;
import netscape.javascript.JSObject;

/** A JavaScript object of the hosting page (LiveConnect). */
public final class BrowserJSObject extends JSObject {

    public static final BrowserJSObject WINDOW = new BrowserJSObject(1);

    private final int handle;

    private BrowserJSObject(int handle) {
        this.handle = handle;
    }

    private static String encode(Object v) {
        if (v == null) return "n:";
        if (v instanceof Boolean) return "b:" + (((Boolean) v).booleanValue() ? "1" : "0");
        if (v instanceof Number) return "d:" + ((Number) v).doubleValue();
        if (v instanceof Character) return "s:" + v;
        if (v instanceof BrowserJSObject) return "o:" + ((BrowserJSObject) v).handle;
        return "s:" + v;
    }

    private static Object decode(String r) {
        if (r == null) return null;
        if (r.startsWith("!")) throw new JSException(r.substring(1));
        String v = r.substring(1);
        char t = v.charAt(0);
        String p = v.substring(2);
        switch (t) {
            case 'n': return null;
            case 'b': return Boolean.valueOf(p.equals("1"));
            case 'd': {
                double d = Double.parseDouble(p);
                if (d == Math.rint(d) && Math.abs(d) <= Integer.MAX_VALUE) {
                    return Integer.valueOf((int) d);
                }
                return Double.valueOf(d);
            }
            case 's': return p;
            case 'o': return new BrowserJSObject(Integer.parseInt(p));
            default: return null;
        }
    }

    private static String encodeArgs(Object[] args) {
        if (args == null || args.length == 0) return "";
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < args.length; i++) {
            if (i > 0) sb.append('\u001f');
            sb.append(encode(args[i]));
        }
        return sb.toString();
    }

    public Object call(String methodName, Object[] args) throws JSException {
        return decode(Browser.jsOp(Browser.OP_CALL, handle, methodName, encodeArgs(args)));
    }

    public Object eval(String s) throws JSException {
        return decode(Browser.jsOp(Browser.OP_EVAL, handle, s, ""));
    }

    public Object getMember(String name) throws JSException {
        return decode(Browser.jsOp(Browser.OP_GET, handle, name, ""));
    }

    public void setMember(String name, Object value) throws JSException {
        decode(Browser.jsOp(Browser.OP_SET, handle, name, encode(value)));
    }

    public void removeMember(String name) throws JSException {
        decode(Browser.jsOp(Browser.OP_REMOVE, handle, name, ""));
    }

    public Object getSlot(int index) throws JSException {
        return decode(Browser.jsOp(Browser.OP_GET_SLOT, handle, Integer.toString(index), ""));
    }

    public void setSlot(int index, Object value) throws JSException {
        decode(Browser.jsOp(Browser.OP_SET_SLOT, handle, Integer.toString(index), encode(value)));
    }

    public String toString() {
        Object o = decode(Browser.jsOp(Browser.OP_TO_STRING, handle, "", ""));
        return String.valueOf(o);
    }

    protected void finalize() {
        if (handle > 1) Browser.jsOp(Browser.OP_RELEASE, handle, "", "");
    }
}
