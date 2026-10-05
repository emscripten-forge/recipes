import javax.swing.*;
import java.awt.*;

/** A Swing applet using a JSlider, a JButton and a JProgressBar. */
public class SwingApplet extends JApplet {
    public void init() {
        try {
            SwingUtilities.invokeAndWait(new Runnable() { public void run() { build(); } });
        } catch (Exception e) { e.printStackTrace(); }
        System.out.println("SWING APPLET INIT");
    }
    private void build() {
        JPanel p = new JPanel(new GridLayout(4, 1, 4, 4));
        p.setBorder(BorderFactory.createTitledBorder("Swing applet"));
        final JLabel label = new JLabel("value: 50", SwingConstants.CENTER);
        final JProgressBar bar = new JProgressBar(0, 100); bar.setValue(50); bar.setStringPainted(true);
        final JSlider slider = new JSlider(0, 100, 50);
        slider.addChangeListener(e -> { label.setText("value: " + slider.getValue()); bar.setValue(slider.getValue()); });
        JButton b = new JButton("Reset");
        b.addActionListener(e -> { slider.setValue(0); System.out.println("SWING APPLET RESET"); });
        p.add(label); p.add(slider); p.add(bar); p.add(b);
        setContentPane(p);
    }
}
