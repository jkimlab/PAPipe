package util;
import java.awt.*; 

import javax.swing.*;

import util.PlotData;
import util.SectionData;

import java.awt.geom.*;

import java.lang.Math;

import java.io.File;
import java.io.FileNotFoundException;
import java.util.Scanner;
import java.awt.geom.Line2D;

@SuppressWarnings("serial")
public class DrawPreview extends JFrame
{
	
	public DrawPreview(String plotfilename, String plotfile) // constructor
	{
	    super(plotfilename); // label frame
	    try 
	    {
		    // read the file
			//System.out.println("calling ReadPlotFile"); 
	    	PlotData curplot = ReadPlotFile(plotfile);
	    	
		    if (curplot != null)
		    {
			    //setBounds(0,0,585,765);// set frame
			    setBounds(200,200,curplot.m_plotwidth, curplot.m_plotheight);// set frame
			    setDefaultCloseOperation(JFrame.DISPOSE_ON_CLOSE);
			    Container con=this.getContentPane(); // inherit main frame
			    con.setBackground(Color.white);        // paint background
			    GCanvas canvas=new GCanvas(curplot);     // create drawing canvas
				Color bkgrnd = new Color( 204, 255, 255);
				canvas.setBackground(bkgrnd);

			    con.add(canvas); 	// add to frame 
			    setVisible(true);	// show
		    }
	    }
		catch (FileNotFoundException e)
		{
			String msg = "Plot file: ";
			msg += plotfilename;
			msg += " does not exist.";
			JOptionPane.showMessageDialog(null, msg, "Error", JOptionPane.ERROR_MESSAGE);
			
		}

	}
	  
	public PlotData ReadPlotFile(String plotfilename) throws FileNotFoundException// constructor
	{
		PlotData curplot = new PlotData();
	  	SectionData cursec = new SectionData();
	  	cursec.strokewidth = -1.0;
		Scanner scanfile = new Scanner(new File(plotfilename));
		boolean pagefound = false;
		while (scanfile.hasNextLine()) 
		{
			String curline = scanfile.nextLine();
		    Scanner scanline = new Scanner(curline);
		    scanline.useDelimiter(" ");
		    if (scanline.hasNext())
		    {
				if (pagefound)
				{
					if (curline.contains(" l"))
					{
						// pick up line limits
				  		int index = 0;
			  			Double xbeg = 0.0;
			  			Double ybeg = 0.0;
			  			Double xend = 0.0;
			  			Double yend = 0.0;
					  	while (scanline.hasNext())
					  	{
					  		if(scanline.hasNextDouble())
					  		{
					  			switch (index)
					  			{
						  			case 0: xbeg = scanline.nextDouble(); break;
						  			case 1: ybeg = scanline.nextDouble(); break;
						  			case 2: xend = scanline.nextDouble(); break;
						  			case 3: yend = scanline.nextDouble(); break;
					  			}
					  			index+=1;
					  		}
					  		else
					  		{
					  			scanline.next();
					  		}
					  	}
					  	
					  	// correct for inverted y value
					  	ybeg = curplot.m_plotheight - ybeg;
					  	yend = curplot.m_plotheight - yend;
					  	
					  	// make line
					  	Line2D.Double cur2d = new Line2D.Double(xbeg,ybeg,xend,yend);
					  	cursec.lines.add(cur2d);
					}
					else if (curline.contains(" moveto"))
					{
						// Cubic Bezier curve is on two lines
						// the first defines the start of the curve
				  		int index = 0;
			  			Double xbeg  = 0.0;
			  			Double ybeg  = 0.0;
			  			Double xoff1 = 0.0;
			  			Double yoff1 = 0.0;
			  			Double xoff2 = 0.0;
			  			Double yoff2 = 0.0;
			  			Double xend  = 0.0;
			  			Double yend  = 0.0;
					  	while (scanline.hasNext())
					  	{
					  		if(scanline.hasNextDouble())
					  		{
					  			switch (index)
					  			{
						  			case 0: xbeg = scanline.nextDouble(); break;
						  			case 1: ybeg = scanline.nextDouble(); break;
					  			}
					  			index+=1;
					  		}
					  		else
					  		{
					  			scanline.next();
					  		}
					  	}
					  	
						// the second defines the two off curve points and the end of the curve
					  	curline = scanfile.nextLine();
					  	scanline = new Scanner(curline);
					  	index = 0;
					  	while (scanline.hasNext())
					  	{
					  		if(scanline.hasNextDouble())
					  		{
					  			switch (index)
					  			{
						  			case 0: xoff1 = scanline.nextDouble(); break;
						  			case 1: yoff1 = scanline.nextDouble(); break;
						  			case 2: xoff2 = scanline.nextDouble(); break;
						  			case 3: yoff2 = scanline.nextDouble(); break;
						  			case 4: xend  = scanline.nextDouble(); break;
						  			case 5: yend  = scanline.nextDouble(); break;
					  			}
					  			index+=1;
					  		}
					  		else
					  		{
					  			scanline.next();
					  		}
					  	}
					  	
					  	// correct for inverted y value
					  	ybeg  = curplot.m_plotheight - ybeg;
					  	yoff1 = curplot.m_plotheight - yoff1;
					  	yoff2 = curplot.m_plotheight - yoff2;
					  	yend  = curplot.m_plotheight - yend;
					  	
					  	// make curve
					  	CubicCurve2D.Double cube2d = new CubicCurve2D.Double(xbeg,ybeg,xoff1,yoff1,xoff2,yoff2,xend,yend);
					  	cursec.curves.add(cube2d);
					
						
					}
						
			    }
				
				if (curline.contains("DocumentMedia:"))
				{
					// get image dimensions
					int index = 0;
				  	while (scanline.hasNext())
				  	{
				  		if(scanline.hasNextInt())
				  		{
				  			if (index == 0)
				  			{
				  				curplot.m_plotwidth = scanline.nextInt();
				  			}
				  			else if (index == 1)
				  			{
				  				curplot.m_plotheight = scanline.nextInt();
				  			}
				  			else
				  			{
					  			scanline.next();
				  			}
				  			index+= 1;
				  		}
				  		else
				  		{
				  			scanline.next();
				  		}
				  	}
				}
				else if (curline.contains("setlinewidth"))
				{
					// get line width
					if (cursec.strokewidth > 0)
					{
						// output previous section if it exists
						curplot.m_treePart.add(cursec);
					}
				  	cursec = new SectionData();
				  	while (scanline.hasNext())
				  	{
				  		if(scanline.hasNextDouble())
				  		{
				  			cursec.strokewidth = scanline.nextDouble();
				  		}
				  		else
				  		{
				  			scanline.next(); // throw away misc text
				  		}
				  	}								
				}
				else if (curline.contains("Page:"))
				{
					pagefound = true;
				}			
				else if (curline.contains("findfont"))
				{
					// text output is on 4 lines
					Font useFont;
					Point.Double translation = new Point.Double(0,0);
					Double rotation = 0.0;
					String displayText = new String("");
					
					// first line has the font name and the scaling
					String fontstring = scanline.next().replace('/', ' ');
					fontstring = fontstring.trim();
					String []fontparts = fontstring.split("-");
					
					int fontsize = 0;
					while(scanline.hasNext())
					{
						if (scanline.hasNextDouble())
						{
							fontsize = (int)scanline.nextDouble();
						}
				  		else
				  		{
				  			scanline.next(); // throw away misc text
				  		}
					}
					String fontkind;
					if (fontparts.length == 1)
					{
						// Courier & Helvetica
						fontkind = "book";
					}
					else if (fontparts.length == 3)
					{
						// Helvetica-Narrow
						fontkind = fontparts[2].toLowerCase();					
					}
					else
					{
						fontkind = fontparts[1].toLowerCase();
					}
					
					if (fontkind.contains("roman") ||
						fontkind.contains("book") ||
						fontkind.contains("narrow") ||
						fontkind.contains("light"))
					{
						useFont = new Font(fontparts[0], Font.PLAIN, fontsize);			
					}
					else if(fontkind.contains("bolditalic") ||
							fontkind.contains("boldoblique") ||
							fontkind.contains("demioblique") ||
							fontkind.contains("demiitalic"))
					{
						useFont = new Font(fontparts[0], Font.ITALIC+Font.BOLD, fontsize);				
					}
					else if(fontkind.contains("bold") ||
							fontkind.contains("demi") )
						{
							useFont = new Font(fontparts[0], Font.BOLD, fontsize);							
						}
					else if(fontkind.contains("italic") ||
							fontkind.contains("oblique") ||
							fontkind.contains("bookoblique") ||
							fontkind.contains("lightitalic") ||
							fontkind.contains("mediumitalic"))
						{
							useFont = new Font(fontparts[0], Font.ITALIC, fontsize);		
						}
					else
					{
						useFont = new Font("SanSerif", Font.PLAIN, fontsize);	
					
					}
					
					//useFont = new Font("AvantGarde-BookOblique", Font.PLAIN, fontsize);

					// second line has the start position and rotation data
				  	curline = scanfile.nextLine();
				  	scanline = new Scanner(curline);				
					boolean xfound = false;
					boolean yfound = false;
					while(scanline.hasNext())
					{
						if (scanline.hasNextDouble())
						{
							if (!xfound)
							{
								translation.x = scanline.nextDouble();
								xfound = true;
							}
							else if (!yfound)
							{
								translation.y = scanline.nextDouble();
								translation.y = curplot.m_plotheight - translation.y;  // inverted y correction
								yfound = true;
							}
							else
							{
								rotation = -scanline.nextDouble(); // inverted y correction
							}
						}
				  		else
				  		{
				  			scanline.next(); // throw away misc text
				  		}
					}
					
					// third line is a (0,0) moveto
				  	curline = scanfile.nextLine();
				  	scanline = new Scanner(curline);
				  	
					// last line is (name) show
				  	curline = scanfile.nextLine();
					if(curline.contains("("))
					{
						displayText = curline.substring((curline.indexOf('(') + 1), curline.lastIndexOf(')'));
					}
					
				  	// make text block
					LabelData newlabel = new LabelData(useFont, translation, rotation, displayText);
				  	cursec.texts.add(newlabel);
				}
		    }
		}
		
		// output final section if it exists
		if (cursec.strokewidth > 0)
		{
			curplot.m_treePart.add(cursec);
		}
		return curplot;
	}	
}

@SuppressWarnings("serial")
class GCanvas extends Canvas // create a canvas for your graphics
{	
	private PlotData locplot;
	public GCanvas(PlotData curplot)
	{
		locplot = curplot;
	}

	public void paint(Graphics g) // display shapes on canvas
	  {
	    Graphics2D g2D=(Graphics2D) g; // cast to 2D
	    g2D.setRenderingHint(RenderingHints.KEY_ANTIALIASING,
	                         RenderingHints.VALUE_ANTIALIAS_ON);
	    
		//System.out.println("in paint"); 
		for (int i=0; i<locplot.m_treePart.size(); i++)
		{
			SectionData section = locplot.m_treePart.get(i);
			setStroke(g2D, section.strokewidth);
			
			for (int j=0; j<section.lines.size(); j++)
			{
				drawLine(g2D, section.lines.get(j));
			}
			for (int j=0; j<section.curves.size(); j++)
			{
				drawCubic(g2D, section.curves.get(j));
			}
			for (int j=0; j<section.texts.size(); j++)
			{
				showText(g2D, section.texts.get(j), locplot.m_plotwidth, locplot.m_plotheight);
			}
			
		}
	  }
  
	  public void setStroke(Graphics2D g2D, double width)
	  {
		  BasicStroke stroke1 = new BasicStroke((float)width, java.awt.BasicStroke.CAP_ROUND, java.awt.BasicStroke.JOIN_ROUND); 
		  g2D.setStroke(stroke1);
	  }
	  
	  public void drawLine(Graphics2D g2D, double x1, double y1, double x2, double y2)
	  {
		  Line2D.Double line1 = new Line2D.Double(x1,y1,x2,y2);
		  g2D.draw(line1);
	  }
	  
	  public void drawLine(Graphics2D g2D, Line2D.Double line1)
	  {
		  g2D.draw(line1);
	  }
	  
	  public void drawArc(Graphics2D g2D, double x1, double y1, double x2, double y2, double sd, double rd, int cl)
	  {
		  Arc2D.Double arc1=new Arc2D.Double(x1,y1,x2,y2,sd,rd,cl);
		  g2D.fill(arc1);
	  }
	  
	  public void drawEllipse(Graphics2D g2D,double x1,double y1,double x2,double y2)
	  {
		  Ellipse2D.Double oval1=new Ellipse2D.Double(x1,y1,x2,y2);
		  g2D.fill(oval1);
	  }
	  
	  public void drawCubic(Graphics2D g2D,double x1,double y1,double x2,double y2,double x3,double y3,double x4,double y4)
	  {
		  CubicCurve2D.Double curve1=new CubicCurve2D.Double(x1,y1,x2,y2,x3,y3,x4,y4);
		  g2D.fill(curve1);
	  }
	  
	  public void drawCubic(Graphics2D g2D, CubicCurve2D.Double curve1)
	  {
		  g2D.draw(curve1);
	  }
	  
	  public void showText(Graphics2D g2D, LabelData text, int dispWidth, int dispHeight)
	  {
		  AffineTransform oldat = g2D.getTransform();
		  
		  // have to add rotation after translate
		  // if you do it the other way the rotation 
		  // gets applied to the translation values
		  AffineTransform newat = new AffineTransform();
		  newat.translate((int)(text.m_translation.x), (int)(text.m_translation.y) );
		  newat.rotate(Math.toRadians(text.m_rotation)); 
		  
		  g2D.setTransform(newat);
		  g2D.setFont(text.m_useFont);
		  g2D.drawString(text.m_displayText,0,0);	
		  
		  // may be unnecessary, but safer
		  g2D.setTransform(oldat);
	  }
}
