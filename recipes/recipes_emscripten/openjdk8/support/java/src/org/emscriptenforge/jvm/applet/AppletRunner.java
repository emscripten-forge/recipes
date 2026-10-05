/*
 * Copyright (c) 2026 emscripten-forge contributors.
 * Licensed under the GNU General Public License version 2 with the
 * Classpath exception, like OpenJDK.
 */
package org.emscriptenforge.jvm.applet;

import java.applet.Applet;
import java.applet.AppletContext;
import java.applet.AppletStub;
import java.applet.AudioClip;
import java.awt.BorderLayout;
import java.awt.Color;
import java.awt.Dimension;
import java.awt.Frame;
import java.awt.Image;
import java.awt.Toolkit;
import java.awt.event.WindowAdapter;
import java.awt.event.WindowEvent;
import java.io.IOException;
import java.io.InputStream;
import java.net.MalformedURLException;
import java.net.URL;
import java.net.URLClassLoader;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Enumeration;
import java.util.HashMap;
import java.util.Iterator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import org.emscriptenforge.jvm.Browser;

/**
 * Runs Java applets embedded in the web page that hosts the WebAssembly
 * Java runtime.  Each applet gets an undecorated top-level window placed
 * over its {@code <applet>} element.
 *
 * <pre>
 * AppletRunner [--documentbase URL] --applet key=value ... [--applet ...]
 *   keys: code, codebase, archive, name, width, height, x, y,
 *         param:NAME=VALUE (applet parameters)
 * </pre>
 */
public final class AppletRunner {

    /** One applet on the page. */
    static final class Spec {
        String code, codebase, archive, name;
        int width = 300, height = 200, x, y;
        final Map<String, String> params = new LinkedHashMap<String, String>();
    }

    private static final List<Instance> instances = Collections.synchronizedList(new ArrayList<Instance>());
    private static final Map<String, InputStream> streams = Collections.synchronizedMap(new HashMap<String, InputStream>());
    private static final Map<URL, AudioClip> clips = Collections.synchronizedMap(new HashMap<URL, AudioClip>());

    public static void main(String[] args) throws Exception {
        URL documentBase = null;
        List<Spec> specs = new ArrayList<Spec>();
        Spec cur = null;
        for (int i = 0; i < args.length; i++) {
            String a = args[i];
            if (a.equals("--documentbase") && i + 1 < args.length) {
                documentBase = new URL(args[++i]);
            } else if (a.equals("--applet")) {
                cur = new Spec();
                specs.add(cur);
            } else if (cur != null) {
                int eq = a.indexOf('=');
                if (eq < 0) continue;
                String k = a.substring(0, eq), v = a.substring(eq + 1);
                if (k.startsWith("param:")) cur.params.put(k.substring(6).toLowerCase(), v);
                else if (k.equals("code")) cur.code = v;
                else if (k.equals("codebase")) cur.codebase = v;
                else if (k.equals("archive")) cur.archive = v;
                else if (k.equals("name")) cur.name = v;
                else if (k.equals("width")) cur.width = parseSize(v, 300);
                else if (k.equals("height")) cur.height = parseSize(v, 200);
                else if (k.equals("x")) cur.x = parseSize(v, 0);
                else if (k.equals("y")) cur.y = parseSize(v, 0);
            }
        }
        if (documentBase == null) documentBase = Browser.pageURL();
        if (documentBase == null) documentBase = new URL("file:///");
        if (specs.isEmpty()) {
            System.err.println("AppletRunner: no applets given");
            return;
        }
        for (Spec s : specs) {
            Instance inst = new Instance(s, documentBase);
            instances.add(inst);
            inst.launch();
        }
        startLayoutTracker();
    }

    /**
     * Keeps the applet windows over their boxes in the page when the page
     * layout changes (the page provides __openjdk8AppletLayout(), returning
     * "x,y;x,y;..." in document coordinates).
     */
    private static void startLayoutTracker() {
        Thread t = new Thread(new Runnable() {
            public void run() {
                String last = null;
                for (;;) {
                    try {
                        Thread.sleep(400);
                    } catch (InterruptedException e) {
                        return;
                    }
                    String s;
                    try {
                        Object r = org.emscriptenforge.jvm.BrowserJSObject.WINDOW.eval(
                            "typeof __openjdk8AppletLayout === 'function' ? __openjdk8AppletLayout() : ''");
                        s = r == null ? "" : r.toString();
                    } catch (RuntimeException e) {
                        continue;
                    }
                    if (s.isEmpty() || s.equals(last)) continue;
                    last = s;
                    String[] parts = s.split(";");
                    for (int i = 0; i < parts.length; i++) {
                        Instance inst;
                        synchronized (instances) {
                            if (i >= instances.size()) break;
                            inst = instances.get(i);
                        }
                        String[] xy = parts[i].split(",");
                        if (xy.length != 2 || inst.frame == null) continue;
                        try {
                            int x = Integer.parseInt(xy[0].trim()), y = Integer.parseInt(xy[1].trim());
                            java.awt.Point p = inst.frame.getLocation();
                            if (p.x != x || p.y != y) inst.frame.setLocation(x, y);
                        } catch (NumberFormatException e) {
                            // ignore
                        }
                    }
                }
            }
        }, "applet-layout");
        t.setDaemon(true);
        t.start();
    }

    private static int parseSize(String v, int def) {
        try {
            v = v.trim();
            if (v.endsWith("px")) v = v.substring(0, v.length() - 2);
            if (v.endsWith("%")) return def;
            return (int) Math.round(Double.parseDouble(v));
        } catch (NumberFormatException e) {
            return def;
        }
    }

    static String status(String s) {
        Browser.showStatus(s);
        return s;
    }

    /** A running applet with its stub and context. */
    static final class Instance implements AppletStub, AppletContext {
        final Spec spec;
        final URL documentBase;
        URL codeBase;
        Applet applet;
        Frame frame;
        volatile boolean active;

        Instance(Spec spec, URL documentBase) {
            this.spec = spec;
            this.documentBase = documentBase;
        }

        void launch() {
            Thread t = new Thread(new Runnable() {
                public void run() {
                    try {
                        start();
                    } catch (Throwable e) {
                        e.printStackTrace();
                        status("Applet " + spec.code + " failed: " + e);
                    }
                }
            }, "applet-" + (spec.name != null ? spec.name : spec.code));
            t.start();
        }

        void start() throws Exception {
            String cb = spec.codebase == null || spec.codebase.isEmpty() ? "." : spec.codebase;
            if (!cb.endsWith("/")) cb += "/";
            codeBase = new URL(documentBase, cb);
            List<URL> urls = new ArrayList<URL>();
            if (spec.archive != null) {
                for (String j : spec.archive.split("[,;]")) {
                    j = j.trim();
                    if (!j.isEmpty()) urls.add(new URL(codeBase, j));
                }
            }
            urls.add(codeBase);
            ClassLoader loader = new URLClassLoader(urls.toArray(new URL[urls.size()]),
                                                    AppletRunner.class.getClassLoader());
            Thread.currentThread().setContextClassLoader(loader);

            String code = spec.code;
            if (code == null) throw new IllegalArgumentException("applet has no code attribute");
            if (code.endsWith(".class")) code = code.substring(0, code.length() - 6);
            code = code.replace('/', '.');
            status("Loading Java applet " + code + " ...");
            Class<?> cls = Class.forName(code, true, loader);
            applet = (Applet) cls.newInstance();
            applet.setStub(this);

            frame = new Frame(spec.name != null ? spec.name : code);
            frame.setUndecorated(true);
            frame.setLayout(new BorderLayout());
            frame.setBackground(Color.white);
            frame.add(applet, BorderLayout.CENTER);
            frame.setBounds(spec.x, spec.y, spec.width, spec.height);
            applet.setSize(spec.width, spec.height);
            frame.addWindowListener(new WindowAdapter() {
                public void windowClosing(WindowEvent e) {
                    stop();
                }
            });
            frame.addNotify();
            applet.init();
            frame.setVisible(true);
            frame.validate();
            active = true;
            applet.start();
            applet.repaint();
            status("Applet " + code + " started");
        }

        void stop() {
            if (!active) return;
            active = false;
            try {
                applet.stop();
                applet.destroy();
            } finally {
                frame.dispose();
            }
        }

        // ---- AppletStub
        public boolean isActive() {
            return active;
        }

        public URL getDocumentBase() {
            return documentBase;
        }

        public URL getCodeBase() {
            return codeBase;
        }

        public String getParameter(String name) {
            if (name == null) return null;
            String v = spec.params.get(name.toLowerCase());
            if (v != null) return v;
            String n = name.toLowerCase();
            if (n.equals("width")) return Integer.toString(spec.width);
            if (n.equals("height")) return Integer.toString(spec.height);
            if (n.equals("code")) return spec.code;
            if (n.equals("codebase")) return spec.codebase;
            if (n.equals("archive")) return spec.archive;
            if (n.equals("name")) return spec.name;
            return null;
        }

        public AppletContext getAppletContext() {
            return this;
        }

        public void appletResize(int width, int height) {
            if (frame != null) {
                frame.setSize(width, height);
                frame.validate();
            }
        }

        // ---- AppletContext
        public AudioClip getAudioClip(URL url) {
            synchronized (clips) {
                AudioClip c = clips.get(url);
                if (c == null) {
                    c = new sun.applet.AppletAudioClip(url);
                    clips.put(url, c);
                }
                return c;
            }
        }

        public Image getImage(URL url) {
            return Toolkit.getDefaultToolkit().getImage(url);
        }

        public Applet getApplet(String name) {
            if (name == null) return null;
            synchronized (instances) {
                for (Instance i : instances) {
                    if (name.equalsIgnoreCase(i.spec.name)) return i.applet;
                }
            }
            return null;
        }

        public Enumeration<Applet> getApplets() {
            final List<Applet> l = new ArrayList<Applet>();
            synchronized (instances) {
                for (Instance i : instances) if (i.applet != null) l.add(i.applet);
            }
            return Collections.enumeration(l);
        }

        public void showDocument(URL url) {
            Browser.showDocument(url, "_self");
        }

        public void showDocument(URL url, String target) {
            Browser.showDocument(url, target);
        }

        public void showStatus(String s) {
            status(s);
        }

        public void setStream(String key, InputStream stream) throws IOException {
            if (stream == null) streams.remove(key);
            else streams.put(key, stream);
        }

        public InputStream getStream(String key) {
            return streams.get(key);
        }

        public Iterator<String> getStreamKeys() {
            synchronized (streams) {
                return new ArrayList<String>(streams.keySet()).iterator();
            }
        }
    }
}
