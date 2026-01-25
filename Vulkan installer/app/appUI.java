import javax.swing.*;
import java.awt.*;
import java.awt.event.*;

public class Main {
    public static void main(String[] args) {
        JFrame frame = new JFrame("Vulkan Installer");
        frame.setSize(400, 400);
        frame.setMinimumSize(new Dimension(400, 400));
        frame.setLayout(null); 
        frame.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);

        RoundedButton button = new RoundedButton("Start installer...");
        button.setBackground(new Color(70, 130, 180));
        button.setForeground(Color.WHITE);
        
        // Add the button to the frame first
        frame.add(button);

        // This is the "EventListener" that updates position dynamically
        frame.addComponentListener(new ComponentAdapter() {
            @Override
            public void componentResized(ComponentEvent e) {
                // 1. Get current window dimensions
                int frameW = frame.getContentPane().getWidth();
                int frameH = frame.getContentPane().getHeight();

                // 2. Set button dimensions
                int btnW = 200;
                int btnH = 50;

                // 3. Calculate Center X (Window Center - half of button width)
                int x = (frameW - btnW) / 2;
                
                // 4. Update the button position and size
                button.setBounds(x, 150, btnW, btnH);
            }
        });

        button.addActionListener(e -> button.setVisible(false));
        
        frame.setVisible(true);
    }
}

// RoundedButton class remains exactly the same as yours
class RoundedButton extends JButton {
    public RoundedButton(String label) {
        super(label);
        setContentAreaFilled(false); 
        setFocusPainted(false);     
        setBorderPainted(false);   
    }

    @Override
    protected void paintComponent(Graphics g) {
        Graphics2D graphic = (Graphics2D) g.create();
        graphic.setRenderingHint(RenderingHints.KEY_ANTIALIASING, RenderingHints.VALUE_ANTIALIAS_ON);
        if (getModel().isArmed()) {
            graphic.setColor(getBackground().darker());
        } else {
            graphic.setColor(getBackground());
        }
        graphic.fillRoundRect(0, 0, getWidth(), getHeight(), 20, 20);
        graphic.dispose();
        super.paintComponent(g); 
    }
}
