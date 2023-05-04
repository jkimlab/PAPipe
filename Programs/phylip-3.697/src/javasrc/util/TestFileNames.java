package util;

import java.io.File;
import java.io.IOException;

import javax.swing.JOptionPane;

public class TestFileNames {
	public boolean DuplicateFileNames(String file1, String file1name, String file2, String file2name) 
	{
		File testfile1 = new File(file1);
		File testfile2 = new File(file2);
		
		if (testfile1.exists() && testfile2.exists()){
			
			// check if file1 and file2 are the same
			String file1path = "";
			try {
				file1path = testfile1.getCanonicalPath();
			} catch (IOException e) {
				// should never happen
				e.printStackTrace();
			}
			
			String file2path = "";
			try {
				file2path = testfile2.getCanonicalPath();
			} catch (IOException e) {
				// should never happen
				e.printStackTrace();
			}
			
			if (file1path.equals(file2path))
			{
				String msg = file1name;
				msg += " and ";
				msg += file2name;
				msg += " files are both named \"";
				msg += file1;
				msg += "\" which will not work.";
				JOptionPane.showMessageDialog(null, msg, "Error", JOptionPane.ERROR_MESSAGE);
				return false;
			}
		}
		return true;
	}
	
	public boolean FileAvailable(String file, String filename) 
	{
		File infile = new File(file);
		if (!infile.exists()){
			String msg = filename;
			msg += " File: ";
			msg += file;
			msg += " does not exist.";
			JOptionPane.showMessageDialog(null, msg, "Error", JOptionPane.ERROR_MESSAGE);
			return false;
		}
		return true;
	}
	
	public String FileAlreadyExists(String file, String filename) 
	{
		Object[] options = {"Quit", "Append", "Replace"};
		
		File outfile = new File(file);
		if (outfile.exists()){
			String msg = filename;
			msg += " File: ";
			msg += file;
			msg += " exists. Overwrite?";
			int retval = JOptionPane.showOptionDialog(null, msg, "Warning", JOptionPane.YES_NO_CANCEL_OPTION,JOptionPane.WARNING_MESSAGE, null,options,options[0]);
			if (retval == JOptionPane.CANCEL_OPTION){
				return "w";
			} else{
				if (retval == JOptionPane.NO_OPTION){
					return "a";
				} else{
					return "q";					
				}
			}
		}
		return "w";
	}
}
