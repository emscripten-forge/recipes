/*
 * Copyright (c) 2026 emscripten-forge contributors.
 * Licensed under the GNU General Public License version 2 with the
 * Classpath exception, like OpenJDK.
 */
package org.emscriptenforge.jvm.net;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.HttpURLConnection;
import java.net.ProtocolException;
import java.net.URL;
import java.security.AccessController;
import java.security.PrivilegedAction;
import java.util.ArrayList;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * HTTP(S) through the browser's {@code fetch()}.  There are no sockets in
 * the browser; the request is performed by the page, subject to the usual
 * browser rules (same-origin policy / CORS, cookies, caching).
 */
public class FetchURLConnection extends HttpURLConnection {

    static {
        AccessController.doPrivileged(new PrivilegedAction<Void>() {
            public Void run() {
                System.loadLibrary("wasmrt");
                return null;
            }
        });
    }

    // Header lines never sent by page scripts (the browser sets them).
    private static final String[] FORBIDDEN = {
        "host", "connection", "content-length", "keep-alive", "user-agent",
        "accept-encoding", "te", "trailer", "transfer-encoding", "upgrade",
        "referer", "cookie", "origin", "date", "expect", "via"
    };

    private final Map<String, List<String>> requestHeaders = new LinkedHashMap<String, List<String>>();
    private ByteArrayOutputStream output;
    private final List<String> responseKeys = new ArrayList<String>();
    private final List<String> responseValues = new ArrayList<String>();
    private byte[] body;
    private int reqId;
    private IOException failure;

    public FetchURLConnection(URL url) {
        super(url);
    }

    @Override
    public void setRequestProperty(String key, String value) {
        if (connected) throw new IllegalStateException("Already connected");
        if (key == null) throw new NullPointerException("key is null");
        List<String> l = new ArrayList<String>();
        l.add(value);
        requestHeaders.put(key, l);
    }

    @Override
    public void addRequestProperty(String key, String value) {
        if (connected) throw new IllegalStateException("Already connected");
        if (key == null) throw new NullPointerException("key is null");
        List<String> l = requestHeaders.get(key);
        if (l == null) {
            l = new ArrayList<String>();
            requestHeaders.put(key, l);
        }
        l.add(value);
    }

    @Override
    public String getRequestProperty(String key) {
        if (connected) throw new IllegalStateException("Already connected");
        for (Map.Entry<String, List<String>> e : requestHeaders.entrySet()) {
            if (e.getKey().equalsIgnoreCase(key) && !e.getValue().isEmpty()) {
                return e.getValue().get(0);
            }
        }
        return null;
    }

    @Override
    public Map<String, List<String>> getRequestProperties() {
        if (connected) throw new IllegalStateException("Already connected");
        return Collections.unmodifiableMap(requestHeaders);
    }

    @Override
    public synchronized OutputStream getOutputStream() throws IOException {
        if (connected) throw new ProtocolException("Cannot write output after reading input.");
        if (!doOutput) {
            throw new ProtocolException("cannot write to a URLConnection if doOutput=false"
                                        + " - call setDoOutput(true)");
        }
        if (method.equals("GET")) method = "POST";
        if (output == null) output = new ByteArrayOutputStream();
        return output;
    }

    private static boolean forbidden(String name) {
        String n = name.toLowerCase();
        if (n.startsWith("proxy-") || n.startsWith("sec-")) return true;
        for (String f : FORBIDDEN) if (f.equals(n)) return true;
        return false;
    }

    @Override
    public synchronized void connect() throws IOException {
        if (connected) {
            if (failure != null) throw failure;
            return;
        }
        StringBuilder h = new StringBuilder();
        for (Map.Entry<String, List<String>> e : requestHeaders.entrySet()) {
            if (forbidden(e.getKey())) continue;
            for (String v : e.getValue()) {
                if (v == null) continue;
                h.append(e.getKey()).append(": ").append(v).append('\n');
            }
        }
        if (!useCaches) h.append("Cache-Control: no-cache\n");
        if (ifModifiedSince != 0) {
            java.text.SimpleDateFormat f = new java.text.SimpleDateFormat(
                    "EEE, dd MMM yyyy HH:mm:ss 'GMT'", java.util.Locale.US);
            f.setTimeZone(java.util.TimeZone.getTimeZone("GMT"));
            h.append("If-Modified-Since: ").append(f.format(new java.util.Date(ifModifiedSince))).append('\n');
        }
        byte[] data = output != null ? output.toByteArray() : null;
        reqId = start0(url.toExternalForm(), method, h.toString(), data);
        await0(reqId);
        connected = true;
        try {
            responseCode = status0(reqId);
            String err = string0(reqId, 3);
            if (err != null && responseCode <= 0) {
                failure = new IOException("fetch " + url + " failed: " + err);
                throw failure;
            }
            responseMessage = string0(reqId, 0);
            String headers = string0(reqId, 1);
            responseKeys.clear();
            responseValues.clear();
            responseKeys.add(null);
            responseValues.add("HTTP/1.1 " + responseCode + " "
                               + (responseMessage == null ? "" : responseMessage));
            if (headers != null) {
                for (String line : headers.split("\n")) {
                    int i = line.indexOf(':');
                    if (i <= 0) continue;
                    responseKeys.add(line.substring(0, i).trim());
                    responseValues.add(line.substring(i + 1).trim());
                }
            }
            body = body0(reqId);
            if (body == null) body = new byte[0];
        } finally {
            free0(reqId);
        }
    }

    @Override
    public InputStream getInputStream() throws IOException {
        if (!doInput) {
            throw new ProtocolException("Cannot read from URLConnection if doInput=false"
                                        + " (call setDoInput(true))");
        }
        connect();
        if (responseCode == HTTP_NOT_FOUND || responseCode == HTTP_GONE) {
            throw new FileNotFoundException(url.toString());
        }
        if (responseCode >= 400) {
            throw new IOException("Server returned HTTP response code: " + responseCode
                                  + " for URL: " + url);
        }
        return new ByteArrayInputStream(body);
    }

    @Override
    public InputStream getErrorStream() {
        if (connected && responseCode >= 400 && body != null && body.length > 0) {
            return new ByteArrayInputStream(body);
        }
        return null;
    }

    @Override
    public int getResponseCode() throws IOException {
        connect();
        return responseCode;
    }

    @Override
    public String getResponseMessage() throws IOException {
        connect();
        return responseMessage;
    }

    private boolean ensureConnected() {
        try {
            connect();
            return true;
        } catch (IOException e) {
            return false;
        }
    }

    @Override
    public String getHeaderField(String name) {
        if (!ensureConnected()) return null;
        if (name == null) return responseValues.isEmpty() ? null : responseValues.get(0);
        String result = null;
        for (int i = 1; i < responseKeys.size(); i++) {
            if (name.equalsIgnoreCase(responseKeys.get(i))) result = responseValues.get(i);
        }
        return result;
    }

    @Override
    public String getHeaderFieldKey(int n) {
        if (!ensureConnected()) return null;
        return (n >= 0 && n < responseKeys.size()) ? responseKeys.get(n) : null;
    }

    @Override
    public String getHeaderField(int n) {
        if (!ensureConnected()) return null;
        return (n >= 0 && n < responseValues.size()) ? responseValues.get(n) : null;
    }

    @Override
    public Map<String, List<String>> getHeaderFields() {
        Map<String, List<String>> m = new LinkedHashMap<String, List<String>>();
        if (!ensureConnected()) return m;
        for (int i = 0; i < responseKeys.size(); i++) {
            String k = responseKeys.get(i);
            List<String> l = m.get(k);
            if (l == null) {
                l = new ArrayList<String>();
                m.put(k, l);
            }
            l.add(responseValues.get(i));
        }
        return Collections.unmodifiableMap(m);
    }

    @Override
    public int getContentLength() {
        if (!ensureConnected()) return -1;
        return body == null ? -1 : body.length;
    }

    @Override
    public long getContentLengthLong() {
        return getContentLength();
    }

    @Override
    public void disconnect() {
        body = null;
    }

    @Override
    public boolean usingProxy() {
        return false;
    }

    private static native int start0(String url, String method, String headers, byte[] body);
    private static native void await0(int id);
    private static native int status0(int id);
    private static native String string0(int id, int which);
    private static native byte[] body0(int id);
    private static native void free0(int id);
}
