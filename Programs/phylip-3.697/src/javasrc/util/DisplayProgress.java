package util;
import java.awt.Font;
import java.io.FileNotFoundException;
import java.io.File;
import java.util.Scanner;

import javax.swing.JFrame;
import javax.swing.JOptionPane;
import javax.swing.JScrollPane;
import javax.swing.JTextArea;

@SuppressWarnings("serial")
public class DisplayProgress extends JFrame
{
	public DisplayProgress(String progressfilename, String progressfile) // constructor
	{
	    super(progressfilename); // label frame
		//Font useFont = new Font("Monospaced", Font.PLAIN, 12);
        JTextArea ta = new JTextArea(200,400); 
        ta.setFont(new Font("Monospaced", Font.PLAIN, 12));
        JScrollPane jsp = new JScrollPane(ta,JScrollPane.VERTICAL_SCROLLBAR_AS_NEEDED,JScrollPane.HORIZONTAL_SCROLLBAR_AS_NEEDED);          
	    try 
	    {
	    	
			Scanner sf = new Scanner(new File(progressfile));
			while (sf.hasNextLine()) 
			{
				String curline = sf.nextLine();
				ta.append(curline);
				ta.append("\n");
			}

            ta.setEditable(false);
            jsp.getViewport().add(ta); 
            this.getContentPane().add(jsp);
            this.setLocation(800, 200);
            this.setSize(600, 400);
		    this.setVisible(true);	
 	           
	    }
		catch (FileNotFoundException e)
		{
			String msg = "Progress file: ";
			msg += progressfile;
			msg += " does not exist.";
			JOptionPane.showMessageDialog(null, msg, "Error", JOptionPane.ERROR_MESSAGE);			
		}
	}
}
