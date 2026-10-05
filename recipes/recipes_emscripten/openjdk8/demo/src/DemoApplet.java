import java.applet.*;
import java.awt.*;
import java.awt.event.*;
import netscape.javascript.JSObject;

/** A classic AWT applet: double-buffered animation, image, parameters, mouse, sound, LiveConnect. */
public class DemoApplet extends Applet implements Runnable, MouseListener, MouseMotionListener {
    private Thread anim;
    private volatile boolean running;
    private Image offscreen, orb;
    private AudioClip chime;
    private int bx = 40, by = 40, dx = 3, dy = 2, frames, clicks;
    private Color ball = Color.red;
    private String message;
    private Point last;
    private java.util.List<int[]> strokes = new java.util.ArrayList<int[]>();

    public void init() {
        message = getParameter("message");
        if (message == null) message = "(no message parameter)";
        String bg = getParameter("bgcolor");
        setBackground(bg != null ? Color.decode(bg) : Color.white);
        orb = getImage(getCodeBase(), "orb.png");
        chime = getAudioClip(getCodeBase(), "click.wav");
        addMouseListener(this);
        addMouseMotionListener(this);
        System.out.println("APPLET INIT message=" + message + " codebase=" + getCodeBase());
    }

    public void start() {
        running = true;
        anim = new Thread(this, "demo-animation");
        anim.start();
        showStatus("DemoApplet running");
    }

    public void stop() { running = false; }

    public void run() {
        while (running) {
            Dimension d = getSize();
            bx += dx; by += dy;
            if (bx < 0 || bx > d.width - 30) dx = -dx;
            if (by < 40 || by > d.height - 30) dy = -dy;
            frames++;
            if (frames == 30) System.out.println("APPLET ANIMATING frames=" + frames);
            repaint();
            try { Thread.sleep(40); } catch (InterruptedException e) { return; }
        }
    }

    public void update(Graphics g) { paint(g); }

    public void paint(Graphics g) {
        Dimension d = getSize();
        if (offscreen == null || offscreen.getWidth(null) != d.width || offscreen.getHeight(null) != d.height)
            offscreen = createImage(d.width, d.height);
        Graphics o = offscreen.getGraphics();
        o.setColor(getBackground()); o.fillRect(0, 0, d.width, d.height);
        o.setColor(Color.darkGray); o.drawRect(0, 0, d.width - 1, d.height - 1);
        o.setFont(new Font("SansSerif", Font.BOLD, 14));
        o.drawString(message, 10, 20);
        o.setFont(new Font("Serif", Font.ITALIC, 12));
        o.drawString("frames " + frames + ", clicks " + clicks + " - click for sound, drag to draw", 10, 36);
        if (orb != null) o.drawImage(orb, d.width - 74, d.height - 74, 64, 64, this);
        o.setColor(Color.blue);
        synchronized (strokes) { for (int[] s : strokes) o.drawLine(s[0], s[1], s[2], s[3]); }
        o.setColor(ball); o.fillOval(bx, by, 30, 30);
        o.dispose();
        g.drawImage(offscreen, 0, 0, this);
    }

    public void mouseClicked(MouseEvent e) {
        clicks++;
        ball = new Color((int) (Math.random() * 0xffffff));
        System.out.println("APPLET CLICK " + clicks + " at " + e.getX() + "," + e.getY());
        if (chime != null) chime.play();
        try {
            JSObject win = JSObject.getWindow(this);
            Object r = win.call("appletClicked", new Object[] { Integer.valueOf(clicks), "from Java" });
            System.out.println("APPLET JS returned " + r + ", document.title=" + win.eval("document.title"));
        } catch (Exception ex) {
            System.out.println("APPLET JS failed: " + ex);
        }
    }
    public void mousePressed(MouseEvent e) { last = e.getPoint(); }
    public void mouseReleased(MouseEvent e) { last = null; }
    public void mouseEntered(MouseEvent e) {}
    public void mouseExited(MouseEvent e) {}
    public void mouseDragged(MouseEvent e) {
        if (last != null) synchronized (strokes) { strokes.add(new int[] { last.x, last.y, e.getX(), e.getY() }); }
        last = e.getPoint();
    }
    public void mouseMoved(MouseEvent e) {}
}
