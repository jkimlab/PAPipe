package util;
import java.awt.EventQueue;

import javax.swing.JFrame;
import javax.swing.JTextField;

import javax.swing.JPanel;
import javax.swing.JLabel;
import javax.swing.SwingConstants;
import java.awt.event.ActionListener;
import java.awt.event.ActionEvent;
import javax.swing.JButton;
import java.awt.Color;

public class PhylipFileDialog {
	private JFrame frame;
	/**
	 * @wbp.nonvisual location=991,851
	 */
	private final JLabel lblTitle = new JLabel("WARNING");
	private final JTextField txtFile = new JTextField();
	private final JLabel lblFile = new JLabel("File:");
	private final JLabel lblExists = new JLabel("already exists. ");
	private final JButton btnReplace = new JButton("Replace");
	private final JButton btnAppend = new JButton("Append");
	private final JButton btnChoose = new JButton("Choose a new file");
	private final JButton btnQuit = new JButton("Quit");

	public enum FileAction{REPLACE, APPEND, QUIT}
	
	public class phylipAction{
		FileAction retval;
	}

	/**
	 * Launch the application.
	 */
	public static void main(String[] args) {
		EventQueue.invokeLater(new Runnable() {
			public void run() {
				try {
					PhylipFileDialog window = new PhylipFileDialog();
					window.frame.setVisible(true);
				} catch (Exception e) {
					e.printStackTrace();
				}
			}
		});
	}

	/**
	 * Create the application.
	 */
	public PhylipFileDialog() {
		initialize();
	}
	
	protected void FileActionToggle(FileAction kind) {		
		 phylipAction action = new phylipAction();
		 action.retval = kind;
		 /*
		 try{
			 this.finalize();
		 } catch (Exception e) {
				e.printStackTrace();
		}
		*/
	}

	/**
	 * Initialize the contents of the frame.
	 */
	private void initialize() {
		txtFile.setBounds(42, 35, 336, 28);
		txtFile.setColumns(10);
		frame = new JFrame();
		frame.setBounds(100, 100, 500, 150);
		frame.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
		frame.getContentPane().setLayout(null);
		
		JPanel panel = new JPanel();
		panel.setBounds(0, 0, 494, 23);
		frame.getContentPane().add(panel);
		lblTitle.setHorizontalAlignment(SwingConstants.CENTER);
		lblTitle.setForeground(Color.RED);
		
		panel.add(lblTitle);
		
		frame.getContentPane().add(txtFile);
		lblFile.setBounds(10, 41, 36, 16);
		
		frame.getContentPane().add(lblFile);
		lblExists.setBounds(384, 41, 95, 16);
		
		frame.getContentPane().add(lblExists);
		
		btnReplace.addActionListener(new ActionListener() {
			public void actionPerformed(ActionEvent e) {
				 FileActionToggle(FileAction.REPLACE);			
			}
		});
		btnReplace.setBounds(10, 75, 104, 29);
		frame.getContentPane().add(btnReplace);
		
		btnAppend.addActionListener(new ActionListener() {
			public void actionPerformed(ActionEvent e) {
				 FileActionToggle(FileAction.APPEND);
			}
		});
		btnAppend.setBounds(122, 75, 95, 29);
		frame.getContentPane().add(btnAppend);
		
		btnChoose.addActionListener(new ActionListener() {
			public void actionPerformed(ActionEvent e) {
				 FileActionToggle(FileAction.QUIT);			
			}
		});
		btnChoose.setBounds(218, 75, 160, 29);		
		frame.getContentPane().add(btnChoose);
		
		btnQuit.addActionListener(new ActionListener() {
			public void actionPerformed(ActionEvent e) {
				 FileActionToggle(FileAction.QUIT);			
			}
		});
		btnQuit.setBounds(384, 75, 100, 29);		
		frame.getContentPane().add(btnQuit);
	}

}
