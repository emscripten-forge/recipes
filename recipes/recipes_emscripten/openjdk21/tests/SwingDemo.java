import java.awt.*;
import java.awt.event.*;
import java.awt.geom.*;
import java.awt.image.BufferedImage;
import java.io.*;
import javax.imageio.ImageIO;
import javax.swing.*;
import javax.swing.table.DefaultTableModel;

public class SwingDemo {
    static int clicks = 0;

    static String rect(Component c) {
        Point p = c.getLocationOnScreen();
        return p.x + "," + p.y + "," + c.getWidth() + "," + c.getHeight();
    }

    /** Custom Java2D painting: gradients, antialiased shapes and text. */
    static class Canvas2D extends JComponent {
        Canvas2D() { setPreferredSize(new Dimension(220, 150)); }
        @Override protected void paintComponent(Graphics g0) {
            Graphics2D g = (Graphics2D) g0.create();
            g.setRenderingHint(RenderingHints.KEY_ANTIALIASING, RenderingHints.VALUE_ANTIALIAS_ON);
            g.setRenderingHint(RenderingHints.KEY_TEXT_ANTIALIASING, RenderingHints.VALUE_TEXT_ANTIALIAS_ON);
            g.setPaint(new GradientPaint(0, 0, new Color(0x2E86DE), getWidth(), getHeight(), new Color(0x10AC84)));
            g.fillRoundRect(0, 0, getWidth() - 1, getHeight() - 1, 24, 24);
            g.setColor(new Color(255, 255, 255, 200));
            g.setStroke(new BasicStroke(4f, BasicStroke.CAP_ROUND, BasicStroke.JOIN_ROUND));
            g.draw(new Ellipse2D.Double(20, 20, 70, 70));
            g.fill(new Arc2D.Double(110, 20, 70, 70, 30, 300, Arc2D.PIE));
            g.setFont(new Font(Font.SERIF, Font.BOLD | Font.ITALIC, 22));
            g.drawString("Java2D ✓", 20, 130);
            g.dispose();
        }
    }

    static String imageIoCheck() throws IOException {
        BufferedImage img = new BufferedImage(40, 30, BufferedImage.TYPE_INT_ARGB);
        Graphics2D g = img.createGraphics();
        g.setColor(Color.ORANGE); g.fillRect(0, 0, 40, 30);
        g.setColor(Color.BLUE); g.fillOval(5, 5, 20, 20);
        g.dispose();
        StringBuilder sb = new StringBuilder();
        for (String fmt : new String[] {"png", "jpg", "gif", "bmp"}) {
            BufferedImage src = img;
            if (!fmt.equals("png") && !fmt.equals("gif")) {
                src = new BufferedImage(40, 30, BufferedImage.TYPE_INT_RGB);
                src.getGraphics().drawImage(img, 0, 0, null);
            }
            ByteArrayOutputStream out = new ByteArrayOutputStream();
            boolean ok = ImageIO.write(src, fmt, out);
            BufferedImage back = ImageIO.read(new ByteArrayInputStream(out.toByteArray()));
            boolean same = back != null && back.getWidth() == 40 && Math.abs((back.getRGB(1, 1) & 0xff) - (Color.ORANGE.getRGB() & 0xff)) < 24;
            sb.append(fmt).append(ok && same ? "=ok " : "=FAIL ");
        }
        return sb.toString().trim();
    }

    public static void main(String[] args) throws Exception {
        System.out.println("headless=" + GraphicsEnvironment.isHeadless()
            + " toolkit=" + Toolkit.getDefaultToolkit().getClass().getName());
        GraphicsEnvironment ge = GraphicsEnvironment.getLocalGraphicsEnvironment();
        System.out.println("screen=" + ge.getDefaultScreenDevice().getDefaultConfiguration().getBounds()
            + " fonts=" + ge.getAvailableFontFamilyNames().length);
        System.out.println("imageio " + imageIoCheck());

        SwingUtilities.invokeLater(() -> {
            JFrame f = new JFrame("Swing on WebAssembly");
            f.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);

            JLabel title = new JLabel("Hello, Swing!");
            title.setFont(new Font(Font.SANS_SERIF, Font.BOLD, 20));
            JButton button = new JButton("Click me");
            JTextField field = new JTextField("type here", 14);
            JCheckBox check = new JCheckBox("Checked", true);
            JComboBox<String> combo = new JComboBox<>(new String[] {"Metal", "Nimbus", "Motif"});
            JSlider slider = new JSlider(0, 100, 40);
            JProgressBar progress = new JProgressBar(0, 100);
            progress.setValue(65);
            progress.setStringPainted(true);
            JTable table = new JTable(new DefaultTableModel(
                new Object[][] {{"Zero", "interpreter"}, {"x11.wasm", "display"}, {"DejaVu", "fonts"}},
                new Object[] {"Part", "Role"}));

            button.addActionListener(e -> {
                clicks++;
                title.setText("Clicked " + clicks + (clicks == 1 ? " time" : " times"));
                System.out.println("EVENT button-click " + clicks);
            });
            field.addActionListener(e -> System.out.println("EVENT text-enter " + field.getText()));
            check.addItemListener(e -> System.out.println("EVENT checkbox " + check.isSelected()));

            JPanel controls = new JPanel(new GridBagLayout());
            GridBagConstraints c = new GridBagConstraints();
            c.insets = new Insets(4, 6, 4, 6); c.anchor = GridBagConstraints.WEST; c.gridx = 0; c.gridy = 0;
            c.gridwidth = 2; controls.add(title, c);
            c.gridwidth = 1; c.gridy++; controls.add(button, c); c.gridx = 1; controls.add(check, c);
            c.gridx = 0; c.gridy++; c.gridwidth = 2; c.fill = GridBagConstraints.HORIZONTAL; controls.add(field, c);
            c.gridy++; controls.add(combo, c);
            c.gridy++; controls.add(slider, c);
            c.gridy++; controls.add(progress, c);

            JPanel right = new JPanel(new BorderLayout(6, 6));
            right.add(new Canvas2D(), BorderLayout.NORTH);
            right.add(new JScrollPane(table), BorderLayout.CENTER);
            right.setBorder(BorderFactory.createEmptyBorder(6, 0, 6, 6));

            JMenuBar bar = new JMenuBar();
            JMenu file = new JMenu("File");
            file.add(new JMenuItem("Open…"));
            file.add(new JMenuItem("Quit"));
            bar.add(file);
            bar.add(new JMenu("Help"));
            f.setJMenuBar(bar);

            f.getContentPane().add(controls, BorderLayout.WEST);
            f.getContentPane().add(right, BorderLayout.CENTER);
            f.pack();
            f.setLocation(20, 20);
            f.addWindowListener(new WindowAdapter() {
                @Override public void windowOpened(WindowEvent e) {
                    // report once layout has settled
                    new Timer(300, ev -> {
                        ((Timer) ev.getSource()).stop();
                        System.out.println("SWING READY laf=" + UIManager.getLookAndFeel().getName()
                            + " frame=" + rect(f) + " button=" + rect(button) + " field=" + rect(field)
                            + " check=" + rect(check));
                    }).start();
                }
            });
            f.setVisible(true);
        });
    }
}
