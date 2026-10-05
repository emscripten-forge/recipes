import javax.swing.*;
import javax.swing.table.DefaultTableModel;
import java.awt.*;

/** A small Swing application: menus, text field, table, slider, dialog. */
public class SwingDemo {
    public static void main(String[] args) throws Exception {
        SwingUtilities.invokeAndWait(SwingDemo::build);
        System.out.println("SWING DEMO VISIBLE");
    }

    static void build() {
        JFrame f = new JFrame("Swing on WebAssembly");
        f.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);

        JMenuBar bar = new JMenuBar();
        JMenu file = new JMenu("File");
        JMenuItem about = new JMenuItem("About...");
        about.addActionListener(e -> JOptionPane.showMessageDialog(f,
                "OpenJDK " + System.getProperty("java.version") + " (" + System.getProperty("java.vm.name")
                        + ")\nrunning as WebAssembly in your browser.", "About", JOptionPane.INFORMATION_MESSAGE));
        JMenuItem quit = new JMenuItem("Quit");
        quit.addActionListener(e -> System.exit(0));
        file.add(about);
        file.addSeparator();
        file.add(quit);
        bar.add(file);
        f.setJMenuBar(bar);

        final DefaultTableModel model = new DefaultTableModel(new Object[] { "#", "Text", "Length" }, 0);
        final JTextField input = new JTextField("type here", 18);
        final JLabel status = new JLabel(" ");
        JButton add = new JButton("Add");
        Runnable addRow = () -> {
            String t = input.getText();
            model.addRow(new Object[] { model.getRowCount() + 1, t, t.length() });
            status.setText("added \"" + t + "\"");
            System.out.println("SWING DEMO ADD " + t);
            input.selectAll();
        };
        add.addActionListener(e -> addRow.run());
        input.addActionListener(e -> addRow.run());

        JSlider slider = new JSlider(8, 32, 13);
        slider.setToolTipText("table font size");
        JTable table = new JTable(model);
        slider.addChangeListener(e -> {
            table.setFont(table.getFont().deriveFont((float) slider.getValue()));
            table.setRowHeight(slider.getValue() + 6);
        });

        JPanel top = new JPanel(new FlowLayout(FlowLayout.LEFT));
        top.add(new JLabel("Text:"));
        top.add(input);
        top.add(add);
        top.add(slider);
        JPanel p = new JPanel(new BorderLayout(4, 4));
        p.setBorder(BorderFactory.createEmptyBorder(6, 6, 6, 6));
        p.add(top, BorderLayout.NORTH);
        p.add(new JScrollPane(table), BorderLayout.CENTER);
        p.add(status, BorderLayout.SOUTH);
        f.setContentPane(p);
        f.setSize(560, 320);
        f.setLocation(0, 0);
        f.setVisible(true);
    }
}
