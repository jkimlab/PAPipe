package drawtree;

import java.awt.EventQueue;
import java.io.File;
import java.lang.Math;

import javax.swing.DefaultListCellRenderer;
import javax.swing.JFrame;
import javax.swing.JButton;
import javax.swing.JRadioButton;
import javax.swing.JTextField;
import javax.swing.JLabel;
import javax.swing.SwingConstants;
import javax.swing.JComboBox;
import javax.swing.DefaultComboBoxModel;
import javax.swing.UIManager;

import java.awt.event.ActionListener;
import java.awt.event.ActionEvent;
import javax.swing.JFileChooser;
import javax.swing.JSeparator;

import util.DrawPreview;
import java.awt.Font;
import java.awt.Color;
import java.awt.Graphics;

public class DrawtreeUserInterface {
	
	public class DrawtreeData{
		String  intree;
		String  plotfile;
		String  plotfileopt;
		String  usefont;
		String  treegrows;
		boolean usebranchlengths;
		String  labeldirec;
		Double  labelangle;
		Double  treerotation;
		Double  treearc;
		String  iterationkind;
		int     iterationcount;
		boolean regularizeangles;
		boolean avoidlabeloverlap;
		boolean branchrescale;
		Double  branchscaler;
		Double  relcharhgt;
		String  librarypath;
		boolean doplot; // false = preview
		String  finalplottype;
	}

	private JFrame frmDrawtreeControls;
	private JButton InputTreeBtn;
	private JTextField IntreeTxt;
	private JTextField PlotTxt;
	private JButton plotBtn;
	private JComboBox cmbxPlotFont;
	private JRadioButton useLenY;
	private JRadioButton useLenN;
	private JComboBox cmbxLabelAngle;
	private JTextField treeRotationTxt;
	private JLabel lblTreeRotation;
	private JLabel lblFixedAngleOf;
	private JComboBox cmbxAngle;
	private JComboBox cmbxIterate;
	private JLabel lblAvoidOverlap;
	private JRadioButton avdOverY;
	private JRadioButton avdOverN;
	private JComboBox cmbxRescale;
	private JTextField relCharHgtTxt;
	private JLabel lblRegularizeTheAngles;
	private JRadioButton regangleY;
	private JRadioButton regangleN;
	private JLabel lblBranchScale;
	private JTextField branchScaleTxt;
	private JTextField treeArcTxt;
	private JRadioButton treeHRB;
	private JRadioButton treeVRB;
	private JLabel lblMaximumIterations;
	private JTextField IterationTxt;
	private JLabel lblFinalPlotType;
	private JComboBox cmbxFinalPlotType;

	private String filedir;
	private Color phylipBG;


	/**
	 * Launch the application.
	 */
	public static void main(String[] args) {
		EventQueue.invokeLater(new Runnable() {
			public void run() {
				try {
					DrawtreeUserInterface window = new DrawtreeUserInterface();
					window.frmDrawtreeControls.setVisible(true);
				} catch (Exception e) {
					e.printStackTrace();
				}
			}
		});
	}
	
	protected void ChooseFile(JTextField file) {		
		//Construct a new file choose whose default path is the path to this executable, which 
		//is returned by System.getProperty("user.dir")
		
		JFileChooser fileChooser = new JFileChooser( filedir);

		int option = fileChooser.showOpenDialog(frmDrawtreeControls.getRootPane());
		if (option == JFileChooser.APPROVE_OPTION) {
			File selectedFile = fileChooser.getSelectedFile();
			filedir = fileChooser.getCurrentDirectory().getAbsolutePath();
			file.setText(selectedFile.getPath());
		}	
	}
	
	protected void ChoosePlot(JTextField file) {		
		//Construct a new file choose whose default path is the path to this executable, which 
		//is returned by System.getProperty("user.dir")
		
		JFileChooser fileChooser = new JFileChooser( System.getProperty("user.dir"));

		int option = fileChooser.showOpenDialog(frmDrawtreeControls.getRootPane());
		if (option == JFileChooser.APPROVE_OPTION) {
			File selectedFile = fileChooser.getSelectedFile();
			file.setText(selectedFile.getPath());
		}	
	}
	
	protected void BranchLengthToggle(boolean uselength) {	
		
		if (uselength){
			useLenY.setSelected(true);
			useLenN.setSelected(false);
		}	
		else{
			useLenY.setSelected(false);
			useLenN.setSelected(true);
		}		
	}
	
	protected void AvoidOverlapToggle(boolean avoidoverlap) {		
		if (avoidoverlap){
			avdOverY.setSelected(true);
			avdOverN.setSelected(false);
		}	
		else{
			avdOverY.setSelected(false);
			avdOverN.setSelected(true);
		}		
	}
	
	protected void LabelAngleToggle() {		
		if ((cmbxLabelAngle.getSelectedItem().toString()).contains("Fixed")){
			lblFixedAngleOf.setEnabled(true);
			cmbxAngle.setEnabled(true);
		}	
		else{
			lblFixedAngleOf.setEnabled(false);
			cmbxAngle.setEnabled(false);
		}		
	}
	
	protected void IterationType() {		
		if ((cmbxIterate.getSelectedItem().toString()).contains("No")){
			lblRegularizeTheAngles.setEnabled(true);
			regangleY.setEnabled(true);
			regangleN.setEnabled(true);
			lblAvoidOverlap.setEnabled(false);
			avdOverY.setEnabled(false);
			avdOverN.setEnabled(false);
			lblMaximumIterations.setEnabled(false);
			IterationTxt.setEnabled(false);
			IterationTxt.setText("0");
		}	
		else{
			lblRegularizeTheAngles.setEnabled(false);
			regangleY.setEnabled(false);
			regangleN.setEnabled(false);
			lblAvoidOverlap.setEnabled(true);
			avdOverY.setEnabled(true);
			avdOverN.setEnabled(true);
			lblMaximumIterations.setEnabled(true);
			IterationTxt.setEnabled(true);
			if ((cmbxIterate.getSelectedItem().toString()).contains("Equal")){
				IterationTxt.setText("100");
			}
			else{
				IterationTxt.setText("50");
			}
		}		
	}
	
	protected void ScaleValue() {		
		if ((cmbxRescale.getSelectedItem().toString()).contains("Fixed")){
			lblBranchScale.setEnabled(true);
			branchScaleTxt.setEnabled(true);
			branchScaleTxt.setEditable(true);
		}	
		else{
			lblBranchScale.setEnabled(false);
			branchScaleTxt.setEnabled(false);
			branchScaleTxt.setEditable(false);
		}		
	}
	
	protected void RegAngleToggle(boolean doregular) {		
		if (doregular){
			regangleY.setSelected(true);
			regangleN.setSelected(false);
		}	
		else{
			regangleY.setSelected(false);
			regangleN.setSelected(true);
		}		
	}
	
	protected void SweepLimit() {
		// doing a mod 360 in case the user gets clever
		if (Math.abs(Double.parseDouble(treeArcTxt.getText())) > 360)
		{
			treeArcTxt.setText(Double.toString(Double.parseDouble(treeArcTxt.getText())%360));
		}
		if (Double.parseDouble(treeArcTxt.getText()) == 0.0)
		{
			treeArcTxt.setText(Double.toString(360));
		}
	}
	
	protected void RotationLimit() {
		// doing a mod 360 in case the user gets clever
		if (Double.parseDouble(treeRotationTxt.getText()) > 360)
		{
			treeRotationTxt.setText(Double.toString(Double.parseDouble(treeRotationTxt.getText())%360));
		}
	}
	
	protected void TreeGrowToggle(boolean ishoriz) {		
		if (ishoriz){
			treeHRB.setSelected(true);
			treeVRB.setSelected(false);
		}	
		else{
			treeHRB.setSelected(false);
			treeVRB.setSelected(true);
		}		
	}

	
	protected boolean LaunchDrawtreeInterface(DrawtreeData inputdata){
		inputdata.intree = (String)IntreeTxt.getText();
		inputdata.plotfile = (String)PlotTxt.getText();
		inputdata.plotfileopt = "wb";
		inputdata.usefont =  cmbxPlotFont.getSelectedItem().toString();	
		inputdata.usebranchlengths = useLenY.isSelected();
		
		// Angle of Labels
		inputdata.labeldirec = "middle";
		for (int i=0; i<cmbxLabelAngle.getItemCount(); i++)
		{
			if((cmbxLabelAngle.getItemAt(i).toString().contains(cmbxLabelAngle.getSelectedItem().toString())))
			{
				switch (cmbxLabelAngle.getSelectedIndex()){
					case 0: //middle
						inputdata.labeldirec = "middle";
						break;
					case 1: //fixed
						inputdata.labeldirec = "fixed";
						break;
					case 2: //radial
						inputdata.labeldirec = "radial";
						break;
					case 3: //along
						inputdata.labeldirec = "along";
						break;
					default:
						inputdata.labeldirec = "middle";
						break;													
				}
			}
		}
		
		// fixed label angles
		inputdata.labelangle = 0.0;
		for (int i=0; i<cmbxAngle.getItemCount(); i++)
		{
			if((cmbxAngle.getItemAt(i).toString().contains(cmbxAngle.getSelectedItem().toString())))
			{
				switch (cmbxAngle.getSelectedIndex()){
					case 0: //0.0
						inputdata.labelangle = 0.0;
						break;
					case 1: //90.0
						inputdata.labelangle = 90.0;
						break;
					case 2: //-90.0
						inputdata.labelangle = -90.0;
						break;
					default:
						inputdata.labelangle = 0.0;
						break;													
				}
			}
		}
		if (treeHRB.isSelected())
		{
			inputdata.treegrows = "horizontal";
		}
		else
		{
			inputdata.treegrows = "vertical";					
		}
		
		// just in case the user managed to enter values without a carriage return
		RotationLimit();
		SweepLimit();
		
		inputdata.treerotation = new Double(treeRotationTxt.getText());
		inputdata.treearc = new Double(treeArcTxt.getText());
		
		inputdata.iterationkind = "improve";
		for (int i=0; i<cmbxIterate.getItemCount(); i++)
		{
			if((cmbxIterate.getItemAt(i).toString().contains(cmbxIterate.getSelectedItem().toString())))
			{
				switch (cmbxIterate.getSelectedIndex()){
					case 0: //equal daylight
						inputdata.iterationkind = "improve";
						break;
					case 1: //nbody
						inputdata.iterationkind = "nbody";
						break;
					case 2: //no
						inputdata.iterationkind = "no";
						break;
					default:
						inputdata.iterationkind = "improve";
						break;													
				}
			}
		}
		
		inputdata.iterationcount = Integer.parseInt(IterationTxt.getText());

		inputdata.regularizeangles = regangleY.isSelected();
		inputdata.avoidlabeloverlap = avdOverY.isSelected();
		
		inputdata.branchrescale = false;
		inputdata.branchscaler = 1.0;
		for (int i=0; i<cmbxRescale.getItemCount(); i++)
		{
			if((cmbxRescale.getItemAt(i).toString().contains(cmbxRescale.getSelectedItem().toString())))
			{
				switch (cmbxRescale.getSelectedIndex()){
					case 0: //automatic
						inputdata.branchrescale = true;
						break;
					case 1: //fixed length
						inputdata.branchrescale = false;
						inputdata.branchscaler = new Double(branchScaleTxt.getText());
						break;
					default:
						inputdata.branchrescale = true;
						break;													
				}
			}
		}
		inputdata.relcharhgt = new Double(relCharHgtTxt.getText());
		inputdata.librarypath = System.getProperty("user.dir"); // hardwired - can be made user enterable if need be
		
		
		switch (cmbxFinalPlotType.getSelectedIndex()){
			case 0: // postscript
				inputdata.finalplottype = "lw";
				break;
			case 1: // PICT
				inputdata.finalplottype = "pict";
				break;
			case 2: // PCL
				inputdata.finalplottype = "pcl";
				break;
			case 3: // Windows Bitmap
				inputdata.finalplottype = "bmp";
				break;
			case 4: // FIG 2.0
				inputdata.finalplottype = "fig";
				break;
			case 5: // Idraw
				inputdata.finalplottype = "idraw";
				break;
			case 6: // VRML
				inputdata.finalplottype = "vrml";
				break;
			case 7: // PCX
				inputdata.finalplottype = "pcx";
				break;
			case 8: // Tek4010
				inputdata.finalplottype = "tek";
				break;
			case 9: // X Bitmap
				inputdata.finalplottype = "xbm";
				break;
			case 10: // POVRAY 3D
				inputdata.finalplottype = "pov";
				break;
			case 11: // Rayshade 3D
				inputdata.finalplottype = "ray";
				break;
			case 12: // HPGL
				inputdata.finalplottype = "hp";
				break;
			case 13: // DEC ReGIS
				inputdata.finalplottype = "decregis";
				break;
			case 14: // Epson MX-80
				inputdata.finalplottype = "epson";
				break;
			case 15: // Prowriter/Imagewriter
				inputdata.finalplottype = "citoh";
				break;
//			case 16: // Toshiba 24-pin - removed broken in drawtree
//				inputdata.finalplottype = "toshiba";
//				break;
			case 16: // Okidata dot-matrix
				inputdata.finalplottype = "oki";
				break;
			case 17: // Houston Instruments plotter
				inputdata.finalplottype = "houston";
				break;
			case 18: // other
				inputdata.finalplottype = "other";
				break;
			default:
				inputdata.finalplottype = "lw";
				break;	
		}
				
		DrawtreeInterface dg = new DrawtreeInterface();
		return (dg.DrawtreeRun(inputdata));		
	}	

	/**
	 * Create the application.
	 */
	public DrawtreeUserInterface() {
		initialize();
	}

	/**
	 * Initialize the contents of the frame.
	 */
	@SuppressWarnings("serial")
	private void initialize() {
		filedir = System.getProperty("user.dir");
		phylipBG = new Color(204, 255, 255);
		UIManager.put("ComboBox.disabledBackground", phylipBG); 
		
		frmDrawtreeControls = new JFrame();
		frmDrawtreeControls.getContentPane().setBackground(phylipBG);
		frmDrawtreeControls.setBackground(phylipBG);
		frmDrawtreeControls.setTitle("Drawtree");
		frmDrawtreeControls.setBounds(100, 100, 490, 596);
		frmDrawtreeControls.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
		frmDrawtreeControls.getContentPane().setLayout(null);
		
		InputTreeBtn = new JButton("Input Tree");
		InputTreeBtn.setFont(new Font("Arial", Font.BOLD, 13));
		InputTreeBtn.addActionListener(new ActionListener() {
			public void actionPerformed(ActionEvent e) {
				ChooseFile(IntreeTxt);
			}
		});
		InputTreeBtn.setBounds(10, 10, 117, 28);
		frmDrawtreeControls.getContentPane().add(InputTreeBtn);
		
		IntreeTxt = new JTextField();
		IntreeTxt.setFont(new Font("Arial", Font.PLAIN, 13));
		IntreeTxt.setText("intree");
		IntreeTxt.setBounds(131, 10, 333, 28);
		frmDrawtreeControls.getContentPane().add(IntreeTxt);
		IntreeTxt.setColumns(10);
		
		JSeparator separator = new JSeparator();
		separator.setBounds(0, 68, 485, 12);
		frmDrawtreeControls.getContentPane().add(separator);
		
		plotBtn = new JButton("Plot File");
		plotBtn.setFont(new Font("Arial", Font.BOLD, 13));
		plotBtn.addActionListener(new ActionListener() {
			public void actionPerformed(ActionEvent arg0) {
				ChooseFile(PlotTxt);
			}
		});
		plotBtn.setBounds(10, 39, 117, 28);
		frmDrawtreeControls.getContentPane().add(plotBtn);
		
		PlotTxt = new JTextField();
		PlotTxt.setFont(new Font("Arial", Font.PLAIN, 13));
		PlotTxt.setText("plotfile.ps");
		PlotTxt.setBounds(131, 39, 333, 28);
		frmDrawtreeControls.getContentPane().add(PlotTxt);
		PlotTxt.setColumns(10);
		
		JLabel lblNewLabel_2 = new JLabel("PostScript Font:");
		lblNewLabel_2.setFont(new Font("Arial", Font.BOLD, 13));
		lblNewLabel_2.setHorizontalAlignment(SwingConstants.RIGHT);
		lblNewLabel_2.setBounds(23, 87, 204, 16);
		frmDrawtreeControls.getContentPane().add(lblNewLabel_2);
		
		cmbxPlotFont = new JComboBox();
		cmbxPlotFont.setFont(new Font("Arial", Font.PLAIN, 13));
		cmbxPlotFont.setModel(new DefaultComboBoxModel(new String[] {
				"Times-Roman", "Times-Bold", "Helvetica", "Helvetica-Bold", "Courier", "Courier-Bold", 
				"AvantGarde-Book","AvantGarde-BookOblique", "AvantGarde-Demi", "AvantGarde-DemiOblique", 
				"Bookman-Light", "Bookman-LightItalic", "Bookman-Demi", "Bookman-DemiItalic", 
				"Courier-Oblique", "Courier-BoldOblique", "Helvetica-Oblique", 
				"Helvetica-BoldOblique", "Helvetica-Narrow", "Helvetica-Narrow-Oblique", 
				"Helvetica-Narrow-Bold", "Helvetica-Narrow-BoldOblique", "NewCenturySchlbk-Roman", 
				"NewCenturySchlbk-Italic", "NewCenturySchlbk-Bold", "NewCenturySchlbk-BoldItalic", 
				"Palatino-Roman", "Palatino-Italic", "Palatino-Bold", "Palatino-BoldItalic", 
				 "Times-BoldItalic",  "Times-Italic", "ZapfChancery-MediumItalic"}));
		cmbxPlotFont.setBounds(239, 82, 216, 27);
		cmbxPlotFont.setRenderer(new DefaultListCellRenderer() {
		    public void paint(Graphics g) {
		        setBackground(Color.WHITE);
		        setForeground(Color.BLACK);
		        super.paint(g);
		    }
		});
		frmDrawtreeControls.getContentPane().add(cmbxPlotFont);
		
		
		JLabel lblUseBranchLengths = new JLabel("Use branch lengths:");
		lblUseBranchLengths.setFont(new Font("Arial", Font.BOLD, 13));
		lblUseBranchLengths.setHorizontalAlignment(SwingConstants.TRAILING);
		lblUseBranchLengths.setBounds(23, 145, 204, 16);
		frmDrawtreeControls.getContentPane().add(lblUseBranchLengths);
		
		useLenY = new JRadioButton("Yes");
		useLenY.setFont(new Font("Arial", Font.BOLD, 13));
		useLenY.addActionListener(new ActionListener() {
			public void actionPerformed(ActionEvent e) {
				BranchLengthToggle(true);
			}
		});
		useLenY.setSelected(true);
		useLenY.setBounds(239, 142, 71, 23);
		useLenY.setBackground(phylipBG);
		frmDrawtreeControls.getContentPane().add(useLenY);
		
		useLenN = new JRadioButton("No");
		useLenN.setFont(new Font("Arial", Font.BOLD, 13));
		useLenN.addActionListener(new ActionListener() {
			public void actionPerformed(ActionEvent e) {
				BranchLengthToggle(false);
			}
		});
		useLenN.setBounds(312, 142, 54, 23);
		useLenN.setBackground(phylipBG);
		frmDrawtreeControls.getContentPane().add(useLenN);
		
		lblTreeRotation = new JLabel("Angle of tree:");
		lblTreeRotation.setFont(new Font("Arial", Font.BOLD, 13));
		lblTreeRotation.setHorizontalAlignment(SwingConstants.TRAILING);
		lblTreeRotation.setBounds(23, 232, 204, 16);
		frmDrawtreeControls.getContentPane().add(lblTreeRotation);
		
		treeRotationTxt = new JTextField();
		treeRotationTxt.setFont(new Font("Arial", Font.PLAIN, 13));
		treeRotationTxt.setHorizontalAlignment(SwingConstants.RIGHT);
		treeRotationTxt.setText("90.0");
		treeRotationTxt.addActionListener(new ActionListener() {
			public void actionPerformed(ActionEvent e) {
				RotationLimit();
			}
		});
		treeRotationTxt.setBounds(239, 227, 89, 27);
		frmDrawtreeControls.getContentPane().add(treeRotationTxt);
		treeRotationTxt.setColumns(10);
		
		JLabel lblTreeArc = new JLabel("Arc of tree:");
		lblTreeArc.setFont(new Font("Arial", Font.BOLD, 13));
		lblTreeArc.setHorizontalAlignment(SwingConstants.RIGHT);
		lblTreeArc.setBounds(23, 261, 204, 16);
		frmDrawtreeControls.getContentPane().add(lblTreeArc);
		
		treeArcTxt = new JTextField();
		treeArcTxt.setFont(new Font("Arial", Font.PLAIN, 13));
		treeArcTxt.setHorizontalAlignment(SwingConstants.RIGHT);
		treeArcTxt.setText("360.0");
		treeArcTxt.addActionListener(new ActionListener() {
			public void actionPerformed(ActionEvent e) {
				SweepLimit();
			}
		});
		treeArcTxt.setBounds(239, 256, 89, 27);
		frmDrawtreeControls.getContentPane().add(treeArcTxt);
		treeArcTxt.setColumns(10);
		
		JLabel lblBranchLen = new JLabel(" (if present)");
		lblBranchLen.setFont(new Font("Arial", Font.BOLD, 13));
		lblBranchLen.setBounds(366, 145, 89, 16);
		lblBranchLen.setBackground(phylipBG);
		frmDrawtreeControls.getContentPane().add(lblBranchLen);
			
		JButton btnPlotFile = new JButton("Create Plot File");
		btnPlotFile.setFont(new Font("Arial", Font.BOLD, 13));
		btnPlotFile.addActionListener(new ActionListener() {
			public void actionPerformed(ActionEvent e) {
				DrawtreeData inputdata = new DrawtreeData();
				inputdata.doplot = true;
				@SuppressWarnings("unused")
				boolean retval = LaunchDrawtreeInterface(inputdata);
			}
		});
		btnPlotFile.setBounds(164, 522, 156, 29);
		frmDrawtreeControls.getContentPane().add(btnPlotFile);
		
		JButton btnPreview = new JButton("Preview");
		btnPreview.setFont(new Font("Arial", Font.BOLD, 13));
		btnPreview.addActionListener(new ActionListener() {
			public void actionPerformed(ActionEvent e) {
				DrawtreeData inputdata = new DrawtreeData();
				inputdata.doplot = false;
				//boolean retval = true;
				
				//System.out.println("calling LaunchDrawtreeInterface"); 
				boolean retval = LaunchDrawtreeInterface(inputdata);
				if (retval)
				{
					
					String title = "Preview: " + (String)PlotTxt.getText();
					String curDir = System.getProperty("user.dir");
					curDir += "/JavaPreview.ps";
					//System.out.("calling DrawgramPreview"); 

					new DrawPreview(title, curDir);
				}
				
			}
		});
		
		btnPreview.setBounds(25, 522, 117, 29);
		frmDrawtreeControls.getContentPane().add(btnPreview);
		
		JButton btnQuit = new JButton("Quit");
		btnQuit.setFont(new Font("Arial", Font.BOLD, 13));
		btnQuit.addActionListener(new ActionListener() {
			public void actionPerformed(ActionEvent e) {
				System.exit(0);
			}
		});
		btnQuit.setBounds(342, 522, 117, 29);
		frmDrawtreeControls.getContentPane().add(btnQuit);
		
		JLabel lblAngleOfLabels = new JLabel("Angle of labels:");
		lblAngleOfLabels.setFont(new Font("Arial", Font.BOLD, 13));
		lblAngleOfLabels.setHorizontalAlignment(SwingConstants.RIGHT);
		lblAngleOfLabels.setBounds(23, 174, 204, 16);
		frmDrawtreeControls.getContentPane().add(lblAngleOfLabels);
		
		cmbxLabelAngle = new JComboBox();
		cmbxLabelAngle.setFont(new Font("Arial", Font.PLAIN, 13));
		cmbxLabelAngle.setModel(new DefaultComboBoxModel(new String[] {"Middle of Label", "Fixed", "Radial", "Along Branches"}));
		cmbxLabelAngle.addActionListener(new ActionListener() {
			public void actionPerformed(ActionEvent e) {
				LabelAngleToggle();
			}
		});
		cmbxLabelAngle.setBounds(239, 169, 181, 27);
		cmbxLabelAngle.setRenderer(new DefaultListCellRenderer() {
		    public void paint(Graphics g) {
		        setBackground(Color.WHITE);
		        setForeground(Color.BLACK);
		        super.paint(g);
		    }
		});
		frmDrawtreeControls.getContentPane().add(cmbxLabelAngle);
		
		lblFixedAngleOf = new JLabel("Fixed label angle:");
		lblFixedAngleOf.setFont(new Font("Arial", Font.BOLD, 13));
		lblFixedAngleOf.setEnabled(false);
		lblFixedAngleOf.setHorizontalAlignment(SwingConstants.RIGHT);
		lblFixedAngleOf.setBounds(23, 203, 204, 16);
		frmDrawtreeControls.getContentPane().add(lblFixedAngleOf);
		
		cmbxAngle = new JComboBox();
		cmbxAngle.setFont(new Font("Arial", Font.PLAIN, 13));
		cmbxAngle.setEnabled(false);
		cmbxAngle.setModel(new DefaultComboBoxModel(new String[] {"    0.0", "  90.0", "-90.0"}));
		cmbxAngle.setBounds(239, 198, 92, 27);
		cmbxAngle.setRenderer(new DefaultListCellRenderer() {
		    public void paint(Graphics g) {
		        setBackground(Color.WHITE);
		        setForeground(Color.BLACK);
		        super.paint(g);
		    }
		});
		frmDrawtreeControls.getContentPane().add(cmbxAngle);
		
		JLabel lblIterateToImprove = new JLabel("Iterate to improve tree:");
		lblIterateToImprove.setFont(new Font("Arial", Font.BOLD, 13));
		lblIterateToImprove.setHorizontalAlignment(SwingConstants.RIGHT);
		lblIterateToImprove.setBounds(23, 290, 204, 16);
		frmDrawtreeControls.getContentPane().add(lblIterateToImprove);
		
		cmbxIterate = new JComboBox();
		cmbxIterate.setFont(new Font("Arial", Font.PLAIN, 13));
		cmbxIterate.setModel(new DefaultComboBoxModel(new String[] {"Equal-Daylight algorithm", "n-Body algorithm", "No"}));
		cmbxIterate.addActionListener(new ActionListener() {
			public void actionPerformed(ActionEvent e) {
				IterationType();
			}
		});
		cmbxIterate.setBounds(239, 285, 216, 27);
		cmbxIterate.setRenderer(new DefaultListCellRenderer() {
		    public void paint(Graphics g) {
		        setBackground(Color.WHITE);
		        setForeground(Color.BLACK);
		        super.paint(g);
		    }
		});
		frmDrawtreeControls.getContentPane().add(cmbxIterate);
		
		lblMaximumIterations = new JLabel("Maximum iterations:");
		lblMaximumIterations.setFont(new Font("Arial", Font.BOLD, 13));
		lblMaximumIterations.setHorizontalAlignment(SwingConstants.TRAILING);
		lblMaximumIterations.setBounds(23, 319, 204, 16);
		frmDrawtreeControls.getContentPane().add(lblMaximumIterations);
		
		IterationTxt = new JTextField();
		IterationTxt.setFont(new Font("Arial", Font.PLAIN, 13));
		IterationTxt.setText("100");
		IterationTxt.setBounds(239, 314, 46, 27);
		frmDrawtreeControls.getContentPane().add(IterationTxt);
		IterationTxt.setColumns(10);
		
		lblAvoidOverlap = new JLabel("Try to avoid label overlap:");
		lblAvoidOverlap.setFont(new Font("Arial", Font.BOLD, 13));
		lblAvoidOverlap.setHorizontalAlignment(SwingConstants.RIGHT);
		lblAvoidOverlap.setBounds(23, 377, 204, 16);
		frmDrawtreeControls.getContentPane().add(lblAvoidOverlap);
		
		avdOverY = new JRadioButton("Yes");
		avdOverY.setFont(new Font("Arial", Font.BOLD, 13));
		avdOverY.addActionListener(new ActionListener() {
			public void actionPerformed(ActionEvent e) {
				AvoidOverlapToggle(true);
			}
		});
		avdOverY.setBounds(239, 374, 71, 23);
		avdOverY.setBackground(phylipBG);
		frmDrawtreeControls.getContentPane().add(avdOverY);
		
		avdOverN = new JRadioButton("No");
		avdOverN.setFont(new Font("Arial", Font.BOLD, 13));
		avdOverN.setSelected(true);
		avdOverN.addActionListener(new ActionListener() {
			public void actionPerformed(ActionEvent e) {
				AvoidOverlapToggle(false);
			}
		});
		avdOverN.setBounds(312, 374, 54, 23);
		avdOverN.setBackground(phylipBG);
		frmDrawtreeControls.getContentPane().add(avdOverN);
		
		JLabel lblBranchLengths = new JLabel("Branch lengths:");
		lblBranchLengths.setFont(new Font("Arial", Font.BOLD, 13));
		lblBranchLengths.setHorizontalAlignment(SwingConstants.RIGHT);
		lblBranchLengths.setBounds(23, 406, 204, 16);
		frmDrawtreeControls.getContentPane().add(lblBranchLengths);
		
		cmbxRescale = new JComboBox();
		cmbxRescale.setFont(new Font("Arial", Font.PLAIN, 13));
		cmbxRescale.setModel(new DefaultComboBoxModel(new String[] {"Automatically rescale", "Fixed scale"}));
		cmbxRescale.addActionListener(new ActionListener() {
			public void actionPerformed(ActionEvent e) {
				ScaleValue();
			}
		});
		cmbxRescale.setBounds(239, 401, 216, 27);
		cmbxRescale.setRenderer(new DefaultListCellRenderer() {
		    public void paint(Graphics g) {
		        setBackground(Color.WHITE);
		        setForeground(Color.BLACK);
		        super.paint(g);
		    }
		});
		frmDrawtreeControls.getContentPane().add(cmbxRescale);
				
		lblBranchScale = new JLabel("Branch scale:");
		lblBranchScale.setFont(new Font("Arial", Font.BOLD, 13));
		lblBranchScale.setEnabled(false);
		lblBranchScale.setHorizontalAlignment(SwingConstants.RIGHT);
		lblBranchScale.setBounds(23, 464, 204, 16);
		frmDrawtreeControls.getContentPane().add(lblBranchScale);
		
		branchScaleTxt = new JTextField();
		branchScaleTxt.setFont(new Font("Arial", Font.PLAIN, 13));
		branchScaleTxt.setEditable(false);
		branchScaleTxt.setEnabled(false);
		branchScaleTxt.setText("0.15");
		branchScaleTxt.setBounds(239, 459, 63, 27);
		frmDrawtreeControls.getContentPane().add(branchScaleTxt);
		branchScaleTxt.setColumns(10);
		
		JLabel lblNewLabel_3 = new JLabel("Relative character height:");
		lblNewLabel_3.setFont(new Font("Arial", Font.BOLD, 13));
		lblNewLabel_3.setHorizontalAlignment(SwingConstants.TRAILING);
		lblNewLabel_3.setBounds(23, 435, 204, 16);
		frmDrawtreeControls.getContentPane().add(lblNewLabel_3);
		
		relCharHgtTxt = new JTextField();
		relCharHgtTxt.setFont(new Font("Arial", Font.PLAIN, 13));
		relCharHgtTxt.setText("0.3333");
		relCharHgtTxt.setBounds(239, 430, 63, 27);
		frmDrawtreeControls.getContentPane().add(relCharHgtTxt);
		relCharHgtTxt.setColumns(10);
				
		lblRegularizeTheAngles = new JLabel("Regularize the angles:");
		lblRegularizeTheAngles.setEnabled(false);
		lblRegularizeTheAngles.setFont(new Font("Arial", Font.BOLD, 13));
		lblRegularizeTheAngles.setHorizontalAlignment(SwingConstants.RIGHT);
		lblRegularizeTheAngles.setBounds(23, 348, 204, 16);
		frmDrawtreeControls.getContentPane().add(lblRegularizeTheAngles);
		
		regangleY = new JRadioButton("Yes");
		regangleY.setEnabled(false);
		regangleY.setFont(new Font("Arial", Font.BOLD, 13));
		regangleY.addActionListener(new ActionListener() {
			public void actionPerformed(ActionEvent e) {
				RegAngleToggle(true);
			}
		});
		regangleY.setBounds(239, 345, 71, 23);
		regangleY.setBackground(phylipBG);
		frmDrawtreeControls.getContentPane().add(regangleY);
		
		regangleN = new JRadioButton("No");
		regangleN.setEnabled(false);
		regangleN.setFont(new Font("Arial", Font.BOLD, 13));
		regangleN.addActionListener(new ActionListener() {
			public void actionPerformed(ActionEvent e) {
				RegAngleToggle(false);
			}
		});
		regangleN.setSelected(true);
		regangleN.setBounds(312, 345, 54, 23);
		regangleN.setBackground(phylipBG);
		frmDrawtreeControls.getContentPane().add(regangleN);		
		
		JLabel label = new JLabel("Tree grows:");
		label.setFont(new Font("Arial", Font.BOLD, 13));
		label.setHorizontalAlignment(SwingConstants.TRAILING);
		label.setBounds(23, 116, 204, 16);
		frmDrawtreeControls.getContentPane().add(label);
		
		treeHRB = new JRadioButton("Horizontally");
		treeHRB.setFont(new Font("Arial", Font.BOLD, 13));
		treeHRB.addActionListener(new ActionListener() {
			public void actionPerformed(ActionEvent e) {
				TreeGrowToggle(true);
			}
		});
		treeHRB.setBounds(239, 113, 117, 23);
		treeHRB.setBackground(phylipBG);
		frmDrawtreeControls.getContentPane().add(treeHRB);
		
		treeVRB = new JRadioButton("Vertically");
		treeVRB.setFont(new Font("Arial", Font.BOLD, 13));
		treeVRB.setSelected(true);
		treeVRB.addActionListener(new ActionListener() {
			public void actionPerformed(ActionEvent e) {
				TreeGrowToggle(false);
			}
		});
		treeVRB.setBounds(356, 113, 111, 23);
		treeVRB.setBackground(phylipBG);
		frmDrawtreeControls.getContentPane().add(treeVRB);
		
		lblFinalPlotType = new JLabel("Final plot file type:");
		lblFinalPlotType.setHorizontalAlignment(SwingConstants.TRAILING);
		lblFinalPlotType.setFont(new Font("Arial", Font.BOLD, 13));
		lblFinalPlotType.setBounds(16, 493, 211, 16);
		frmDrawtreeControls.getContentPane().add(lblFinalPlotType);
		
		cmbxFinalPlotType = new JComboBox();
		cmbxFinalPlotType.setModel(new DefaultComboBoxModel(new String[] {
				"Postscript","PICT", "PCL","Windows BMP","FIG 2.0","Idraw","VRML","PCX","Tek4010",
				"X Bitmap","POVRAY 3D","Rayshade 3D","HPGL","DEC ReGIS","Epson MX-80","Prowriter/Imagewriter",
//				"Toshiba 24-pin","Okidata dot-matrix","Houston Instruments plotter", "other"
				"Okidata dot-matrix","Houston Instruments plotter", "other" // Toshiba removed - broken in drawtree
				}));
		cmbxFinalPlotType.setSelectedIndex(0);
		cmbxFinalPlotType.setFont(new Font("Arial", Font.PLAIN, 13));
		cmbxFinalPlotType.setBounds(239, 487, 216, 28);
		cmbxFinalPlotType.setRenderer(new DefaultListCellRenderer() {
		    public void paint(Graphics g) {
		        setBackground(Color.WHITE);
		        setForeground(Color.BLACK);
		        super.paint(g);
		    }
		});
		frmDrawtreeControls.getContentPane().add(cmbxFinalPlotType);

	}
}
