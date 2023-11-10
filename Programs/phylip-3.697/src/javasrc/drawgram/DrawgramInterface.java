package drawgram;

import javax.swing.JOptionPane;

import util.TestFileNames;

import drawgram.DrawgramUserInterface.DrawgramData;

import com.sun.jna.Library;
import com.sun.jna.Native;

public class DrawgramInterface {
	    public interface Drawgram extends Library {
	        public void  drawgram(
	        		String  intree,
	        		String  usefont,
	        		String  plotfile,
	        		String  plotfileopt,
	        		String  treegrows,
	        		String  treestyle,
	        		boolean usebranchlengths,
	        		double  labelangle,
	        		boolean scalebranchlength,
	        		double  branchlength,
	        		double  breadthdepthratio,
	        		double  stemltreedratio,
	        		double  chhttipspratio,
	        		String  ancnodes,
	        		boolean doplot,
	        		String  finalplotkind);

	    }
		
		public boolean DrawgramRun(DrawgramData inVals){
			TestFileNames test = new TestFileNames();
			
			if (!test.FileAvailable(inVals.intree, "Intree"))
			{
				return false;
			}
			
			if (inVals.doplot) // only check if final plot
			{ 
				String opt = test.FileAlreadyExists(inVals.plotfile, "Plotfile");
				if (opt == "q")
				{
					return false;
				}
				else
				{
					if (opt == "a")
					{
						inVals.plotfileopt = "ab";
					}
					else
					{
						inVals.plotfileopt = "wb";					
					}
				}
			}
			
			// at this point we hook into the C code			
			String wherestr = "System.load";
			try
			{
				wherestr = "Native.loadLibrary";
				Drawgram Drawgram = (Drawgram) Native.loadLibrary("drawgram", Drawgram.class);
		        Drawgram.drawgram(
		        		inVals.intree,
		        		inVals.usefont,
		        		inVals.plotfile,
		        		inVals.plotfileopt,
		        		inVals.treegrows,
		        		inVals.treestyle,
		        		inVals.usebranchlengths,
		        		inVals.labelangle,
		        		inVals.scalebranchlength,
		        		inVals.branchlength,
		        		inVals.breadthdepthratio,
		        		inVals.stemltreedratio,
		        		inVals.chhttipspratio,
		        		inVals.ancnodes,
		        		inVals.doplot,
		        		inVals.finalplottype);
		        
				return true;
			}
			catch (UnsatisfiedLinkError e)
			{
				String mapedLibName = System.mapLibraryName("drawgram");
				String libpath = inVals.librarypath;
				if (mapedLibName.contains("jnilib"))
				{
					// mac
					libpath += "/libdrawgram.dylib";
				}
				else if (mapedLibName.contains("dll"))
				{
					// windows
					libpath += "\\drawgram.dll";
				}
				else
				{
					// unix
					libpath += "/libdrawgram.so";
				}
				String msg = "Drawgram library not found in : ";
				msg += libpath;
				msg += " by ";
				msg += wherestr;
				msg += ". Error msg: ";
				msg += e;
				System.out.println(msg);
				JOptionPane.showMessageDialog(null, msg, "Error", JOptionPane.ERROR_MESSAGE);
				String path = System.getProperty("java.library.path");
				JOptionPane.showMessageDialog(null, path, "after error", JOptionPane.INFORMATION_MESSAGE);
				JOptionPane.showMessageDialog(null, mapedLibName, "after error", JOptionPane.INFORMATION_MESSAGE);
			}
			return false;
		}
	}

	
