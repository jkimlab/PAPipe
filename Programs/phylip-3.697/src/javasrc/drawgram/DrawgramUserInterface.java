package drawgram;

import java.awt.EventQueue;
import java.io.File;

import javax.swing.DefaultListCellRenderer;
import javax.swing.JFrame;
import javax.swing.JLabel;
import javax.swing.JRadioButton;
import javax.swing.JButton;
import javax.swing.JTextField;
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

public class DrawgramUserInterface {

	public class DrawgramData{
		String  intree;
		String  usefont;
		String  plotfile;
		String  plotfileopt;
		String  treegrows;
		String  treestyle;
		boolean usebranchlengths;
		Double  labelangle;
		boolean scalebranchlength;
		Double  branchlength;
		Double  breadthdepthratio;
		Double  stemltreedratio;
		Double  chhttipspratio;
		String  ancnodes;
		String  librarypath;
		boolean doplot; // false = do preview
		String  finalplottype;
	}

	public enum LastPage{COUNT, SIZE, OVERLAP}
	private String filedir;
	private Color phylipBG;
	
	private String ancNodesCBdefault = new String("Weighted");

	private JFrame frmDrawgramControls;
	private JTextField labelAngleTxt;
	private JLabel lblAngleLabels;
	private JTextField branchLenTxt;
	private JTextField depthBreadthTxt;
	private JTextField stemLenTreeDpthTxt;
	private JTextField charHgtTipSpTxt;
	private JRadioButton treeHRB;
	private JRadioButton treeVRB;
	private JRadioButton useLenY;
	private JRadioButton useLenN;
	private JRadioButton branchScaleAutoRB;
	private JLabel branchScaleTxt;
	private JLabel lblCm;
	private JComboBox cmbxTreeStyle;
	private JComboBox cmbxAncNodes;
	private JButton InputTreeBtn;
	private JTextField IntreeTxt;
	private JTextField PlotTxt;
	private JButton plotBtn;
	private JComboBox cmbxPlotFont;
	private JLabel lblFinalPlotType;
	private JComboBox cmbxFinalPlotType;
	private JButton btnPreview;
	private JButton btnQuit;
	private JButton btnPlotFile;
		
	/**
	 * Launch the application.
	 */
	public static void main(String[] args) {
		EventQueue.invokeLater(new Runnable() {
			public void run() {
				try {
					DrawgramUserInterface window = new DrawgramUserInterface();
					window.frmDrawgramControls.setVisible(true);
				} catch (Exception e) {
					e.printStackTrace();
				}
			}
		});
	}

	/**
	 * Create the application.
	 */
	public DrawgramUserInterface() {
		initialize();
	}

	// event handlers
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
	
	protected void BranchLengthToggle(boolean uselength) {		
		if (uselength){
			useLenY.setSelected(true);
			useLenN.setSelected(false);
			cmbxAncNodes.setEnabled(true);
			for (int i=0; i<cmbxAncNodes.getItemCount(); i++)
			{
				if(cmbxAncNodes.getItemAt(i).toString().contains(ancNodesCBdefault))
				{
					cmbxAncNodes.setSelectedIndex(i);
				}
			}
			cmbxAncNodes.setForeground(Color.BLACK);
		}	
		else{
			useLenY.setSelected(false);
			useLenN.setSelected(true);
			cmbxAncNodes.setEnabled(false);
			ancNodesCBdefault = cmbxAncNodes.getSelectedItem().toString();
			for (int i=0; i<cmbxAncNodes.getItemCount(); i++)
			{
				if(cmbxAncNodes.getItemAt(i).toString().contains("Centered"))
				{
					cmbxAncNodes.setSelectedIndex(i);
				}
			}
			cmbxAncNodes.setForeground(Color.GRAY);
		}		
	}
	
	protected void ScaleAutoToggle(boolean isauto) {		
		if (isauto){
			branchScaleAutoRB.setSelected(true);
			branchScaleTxt.setEnabled(false);
			branchLenTxt.setEnabled(false);
			lblCm.setEnabled(false);
		}	
		else{
			branchScaleAutoRB.setSelected(false);
			branchScaleTxt.setEnabled(true);
			branchLenTxt.setEnabled(true);
			lblCm.setEnabled(true);
		}		
	}
	
	protected void ChooseFile(JTextField file) {		
		//Construct a new file choose whose default path is the path to this executable, which 
		//is returned by System.getProperty("user.dir")
		
		JFileChooser fileChooser = new JFileChooser( filedir);

		int option = fileChooser.showOpenDialog(frmDrawgramControls.getRootPane());
		if (option == JFileChooser.APPROVE_OPTION) {
			File selectedFile = fileChooser.getSelectedFile();
			filedir = fileChooser.getCurrentDirectory().getAbsolutePath();
			file.setText(selectedFile.getPath());
		}	
	}
	
	protected void LabelAngleToggle() {		
		if ((cmbxTreeStyle.getSelectedItem().toString()).contains("Circular")){
			lblAngleLabels.setEnabled(false);
			labelAngleTxt.setEnabled(false);
		}	
		else{
			lblAngleLabels.setEnabled(true);
			labelAngleTxt.setEnabled(true);
		}		
	}
	
	protected void SetBackgroundColor(){
		cmbxPlotFont.setBackground(phylipBG);
	}
	
	protected boolean LaunchDrawgramInterface(DrawgramData inputdata){
				
		inputdata.intree = (String)IntreeTxt.getText();
		inputdata.usefont =  cmbxPlotFont.getSelectedItem().toString();
		inputdata.plotfile = (String)PlotTxt.getText();
		inputdata.plotfileopt = "wb";
		if (treeHRB.isSelected())
		{
			inputdata.treegrows = "horizontal";
		}
		else
		{
			inputdata.treegrows = "vertical";					
		}
		
		switch (cmbxTreeStyle.getSelectedIndex()){
			case 0: //Phenogram
				inputdata.treestyle = "phenogram";
				break;
			case 1: //Cladogram
				inputdata.treestyle = "cladogram";
				break;
			case 2: //Curvogram
				inputdata.treestyle = "curvogram";
				break;
			case 3: //Eurogram
				inputdata.treestyle = "eurogram";
				break;
			case 4: //Swoopogram"
				inputdata.treestyle = "swoopogram";
				break;
			case 5: //Circular tree
				inputdata.treestyle = "circular";
				break;
			default:
				inputdata.treestyle = "phenogram";
				break;													
		}
		
		inputdata.usebranchlengths = useLenY.isSelected();
		inputdata.labelangle = new Double(labelAngleTxt.getText());
		inputdata.scalebranchlength = branchScaleAutoRB.isSelected();
		inputdata.branchlength = new Double(branchLenTxt.getText());
		inputdata.breadthdepthratio = new Double(depthBreadthTxt.getText());
		inputdata.stemltreedratio = new Double(stemLenTreeDpthTxt.getText());
		inputdata.chhttipspratio = new Double(charHgtTipSpTxt.getText());
		
		switch (cmbxAncNodes.getSelectedIndex()){
			case 0: //Weighted
				inputdata.ancnodes = "weighted";
				break;
			case 1: //Intermediate
				inputdata.ancnodes = "intermediate";
				break;
			case 2: //Centered
				inputdata.ancnodes = "centered";
				break;
			case 3: //Innermost
				inputdata.ancnodes = "inner";
				break;
			case 4: //V-shaped
				inputdata.ancnodes = "vshaped";
				break;
			default:
				inputdata.ancnodes = "weighted";
				break;													
		}
		
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
//			case 16: // Toshiba 24-pin - removed broken in drawgram
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
	
		inputdata.librarypath = System.getProperty("user.dir"); // hardwired - can be made user enterable if need be
				
		DrawgramInterface dg = new DrawgramInterface();
		return (dg.DrawgramRun(inputdata));
		
	}

	/**
	 * Initialize the contents of the frame.
	 */
	@SuppressWarnings("serial")
	private void initialize() {
		filedir = System.getProperty("user.dir");
		phylipBG = new Color(204, 255, 255);
		UIManager.put("ComboBox.disabledBackground", phylipBG); 
		
		frmDrawgramControls = new JFrame();
		frmDrawgramControls.getContentPane().setBackground(phylipBG);
		frmDrawgramControls.setBackground(phylipBG);
		frmDrawgramControls.setTitle("Drawgram");
		frmDrawgramControls.setFont(new Font("Arial", Font.BOLD, 13));
		frmDrawgramControls.setBounds(100, 100, 490, 480);
		frmDrawgramControls.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
		frmDrawgramControls.getContentPane().setLayout(null);
		
		InputTreeBtn = new JButton("Input Tree");
		InputTreeBtn.setFont(new Font("Arial", Font.BOLD, 13));
		InputTreeBtn.addActionListener(new ActionListener() {
			public void actionPerformed(ActionEvent e) {
				ChooseFile(IntreeTxt);
			}
		});
		InputTreeBtn.setBounds(10, 10, 117, 28);
		frmDrawgramControls.getContentPane().add(InputTreeBtn);
		
		IntreeTxt = new JTextField();
		IntreeTxt.setFont(new Font("Arial", Font.PLAIN, 13));
		IntreeTxt.setText("intree");
		IntreeTxt.setBounds(131, 10, 333, 28);
		frmDrawgramControls.getContentPane().add(IntreeTxt);
		IntreeTxt.setColumns(10);
		
		JSeparator separator = new JSeparator();
		separator.setBounds(-10, 70, 530, 12);
		frmDrawgramControls.getContentPane().add(separator);
		
		JLabel lblTreeGrows = new JLabel("Tree grows:");
		lblTreeGrows.setFont(new Font("Arial", Font.BOLD, 13));
		lblTreeGrows.setHorizontalAlignment(SwingConstants.TRAILING);
		lblTreeGrows.setBounds(13, 116, 211, 16);
		frmDrawgramControls.getContentPane().add(lblTreeGrows);
		
		treeHRB = new JRadioButton("Horizontally");
		treeHRB.setFont(new Font("Arial", Font.BOLD, 13));
		treeHRB.addActionListener(new ActionListener() {
			public void actionPerformed(ActionEvent e) {
				TreeGrowToggle(true);
			}
		});
		treeHRB.setSelected(true);
		treeHRB.setBounds(228, 113, 117, 23);
		treeHRB.setBackground(phylipBG);
		frmDrawgramControls.getContentPane().add(treeHRB);
		
		treeVRB = new JRadioButton("Vertically");
		treeVRB.setFont(new Font("Arial", Font.BOLD, 13));
		treeVRB.addActionListener(new ActionListener() {
			public void actionPerformed(ActionEvent e) {
				TreeGrowToggle(false);
			}
		});
		treeVRB.setBounds(341, 113, 117, 23);
		treeVRB.setBackground(phylipBG);
		frmDrawgramControls.getContentPane().add(treeVRB);
		
		JLabel lblTreeStyle = new JLabel("Tree style:");
		lblTreeStyle.setFont(new Font("Arial", Font.BOLD, 13));
		lblTreeStyle.setHorizontalAlignment(SwingConstants.TRAILING);
		lblTreeStyle.setBounds(13, 145, 211, 16);
		frmDrawgramControls.getContentPane().add(lblTreeStyle);
		
		JLabel lblUseBranchLengths = new JLabel("Use branch lengths:");
		lblUseBranchLengths.setFont(new Font("Arial", Font.BOLD, 13));
		lblUseBranchLengths.setHorizontalAlignment(SwingConstants.TRAILING);
		lblUseBranchLengths.setBounds(13, 174, 211, 16);
		frmDrawgramControls.getContentPane().add(lblUseBranchLengths);
		
		useLenY = new JRadioButton("Yes");
		useLenY.setFont(new Font("Arial", Font.BOLD, 13));
		useLenY.addActionListener(new ActionListener() {
			public void actionPerformed(ActionEvent e) {
				BranchLengthToggle(true);
			}
		});
		useLenY.setSelected(true);
		useLenY.setBounds(228, 171, 61, 23);
		useLenY.setBackground(phylipBG);
		frmDrawgramControls.getContentPane().add(useLenY);
		
		useLenN = new JRadioButton("No");
		useLenN.setFont(new Font("Arial", Font.BOLD, 13));
		useLenN.addActionListener(new ActionListener() {
			public void actionPerformed(ActionEvent e) {
				BranchLengthToggle(false);
			}
		});
		useLenN.setBounds(285, 171, 54, 23);
		useLenN.setBackground(phylipBG);
		frmDrawgramControls.getContentPane().add(useLenN);
		
		lblAngleLabels = new JLabel("Angle of labels:");
		lblAngleLabels.setFont(new Font("Arial", Font.BOLD, 13));
		lblAngleLabels.setHorizontalAlignment(SwingConstants.TRAILING);
		lblAngleLabels.setBounds(13, 203, 211, 16);
		frmDrawgramControls.getContentPane().add(lblAngleLabels);
		
		labelAngleTxt = new JTextField();
		labelAngleTxt.setFont(new Font("Arial", Font.PLAIN, 13));
		labelAngleTxt.setText("90.0");
		labelAngleTxt.setBounds(228, 198, 47, 27);
		frmDrawgramControls.getContentPane().add(labelAngleTxt);
		labelAngleTxt.setColumns(10);
		
		JLabel lblBranchLenScaling = new JLabel("Branch length scaling:");
		lblBranchLenScaling.setFont(new Font("Arial", Font.BOLD, 13));
		lblBranchLenScaling.setHorizontalAlignment(SwingConstants.TRAILING);
		lblBranchLenScaling.setBounds(13, 232, 211, 16);
		frmDrawgramControls.getContentPane().add(lblBranchLenScaling);
		
		branchScaleAutoRB = new JRadioButton("Automatic");
		branchScaleAutoRB.setFont(new Font("Arial", Font.BOLD, 13));
		branchScaleAutoRB.addActionListener(new ActionListener() {
			public void actionPerformed(ActionEvent e) {
				ScaleAutoToggle(branchScaleAutoRB.isSelected());
			}
		});
		branchScaleAutoRB.setSelected(true);
		branchScaleAutoRB.setBounds(228, 229, 109, 23);
		branchScaleAutoRB.setBackground(phylipBG);
		frmDrawgramControls.getContentPane().add(branchScaleAutoRB);
		
		branchScaleTxt = new JLabel("Scale");
		branchScaleTxt.setFont(new Font("Arial", Font.BOLD, 13));
		branchScaleTxt.setEnabled(false);
		branchScaleTxt.setBounds(341, 232, 47, 16);
		frmDrawgramControls.getContentPane().add(branchScaleTxt);
		
		branchLenTxt = new JTextField();
		branchLenTxt.setEnabled(false);
		branchLenTxt.setText("1.0");
		branchLenTxt.setFont(new Font("Arial", Font.PLAIN, 13));
		branchLenTxt.setBounds(387, 226, 54, 28);
		frmDrawgramControls.getContentPane().add(branchLenTxt);
		branchLenTxt.setColumns(10);
		
		lblCm = new JLabel("cm");
		lblCm.setFont(new Font("Arial", Font.BOLD, 13));
		lblCm.setEnabled(false);
		lblCm.setBounds(441, 232, 26, 16);
		frmDrawgramControls.getContentPane().add(lblCm);
		
		JLabel lblDepthBreadthOfTree = new JLabel("Depth/breadth of tree:");
		lblDepthBreadthOfTree.setFont(new Font("Arial", Font.BOLD, 13));
		lblDepthBreadthOfTree.setHorizontalAlignment(SwingConstants.TRAILING);
		lblDepthBreadthOfTree.setBounds(13, 261, 211, 16);
		frmDrawgramControls.getContentPane().add(lblDepthBreadthOfTree);
		
		depthBreadthTxt = new JTextField();
		depthBreadthTxt.setFont(new Font("Arial", Font.PLAIN, 13));
		depthBreadthTxt.setText("0.53");
		depthBreadthTxt.setBounds(228, 256, 54, 27);
		frmDrawgramControls.getContentPane().add(depthBreadthTxt);
		depthBreadthTxt.setColumns(10);
		
		JLabel lblStemLengthTreeDepth = new JLabel("Stem length/tree depth:");
		lblStemLengthTreeDepth.setFont(new Font("Arial", Font.BOLD, 13));
		lblStemLengthTreeDepth.setHorizontalAlignment(SwingConstants.TRAILING);
		lblStemLengthTreeDepth.setBounds(13, 290, 211, 16);
		frmDrawgramControls.getContentPane().add(lblStemLengthTreeDepth);
		
		stemLenTreeDpthTxt = new JTextField();
		stemLenTreeDpthTxt.setFont(new Font("Arial", Font.PLAIN, 13));
		stemLenTreeDpthTxt.setText("0.05");
		stemLenTreeDpthTxt.setBounds(228, 285, 54, 27);
		frmDrawgramControls.getContentPane().add(stemLenTreeDpthTxt);
		stemLenTreeDpthTxt.setColumns(10);
		
		JLabel lblCharHgtTipSpace = new JLabel("Character height/tip space:");
		lblCharHgtTipSpace.setFont(new Font("Arial", Font.BOLD, 13));
		lblCharHgtTipSpace.setHorizontalAlignment(SwingConstants.TRAILING);
		lblCharHgtTipSpace.setBounds(13, 319, 211, 16);
		frmDrawgramControls.getContentPane().add(lblCharHgtTipSpace);
 
		charHgtTipSpTxt = new JTextField();
		charHgtTipSpTxt.setFont(new Font("Arial", Font.PLAIN, 13));
		charHgtTipSpTxt.setText("0.333");
		charHgtTipSpTxt.setBounds(228, 314, 69, 27);
		frmDrawgramControls.getContentPane().add(charHgtTipSpTxt);
		charHgtTipSpTxt.setColumns(10);
		
		JLabel lblAncestralNodes = new JLabel("Ancestral nodes:");
		lblAncestralNodes.setFont(new Font("Arial", Font.BOLD, 13));
		lblAncestralNodes.setHorizontalAlignment(SwingConstants.TRAILING);
		lblAncestralNodes.setBounds(13, 348, 211, 16);
		frmDrawgramControls.getContentPane().add(lblAncestralNodes);
		
		cmbxTreeStyle = new JComboBox();
		cmbxTreeStyle.setFont(new Font("Arial", Font.PLAIN, 13));
		cmbxTreeStyle.setModel(new DefaultComboBoxModel(new String[] {"Phenogram", "Cladogram", "Curvogram", "Eurogram", "Swoopogram", "Circular tree"}));
		cmbxTreeStyle.addActionListener(new ActionListener() {
			public void actionPerformed(ActionEvent e) {
				LabelAngleToggle();
			}
		});
		cmbxTreeStyle.setRenderer(new DefaultListCellRenderer() {
		    public void paint(Graphics g) {
		        setBackground(Color.WHITE);
		        setForeground(Color.BLACK);
		        super.paint(g);
		    }
		});
		cmbxTreeStyle.setBounds(228, 139, 193, 28);
		frmDrawgramControls.getContentPane().add(cmbxTreeStyle);
		
		cmbxAncNodes = new JComboBox();
		cmbxAncNodes.setFont(new Font("Arial", Font.PLAIN, 13));
		cmbxAncNodes.setModel(new DefaultComboBoxModel(new String[] {"Weighted", "Intermediate", "Centered", "Innermost", "V-shaped"}));
		cmbxAncNodes.setRenderer(new DefaultListCellRenderer() {
		    public void paint(Graphics g) {
		        setBackground(Color.WHITE);
		        setForeground(Color.BLACK);
		        super.paint(g);
		    }
		});
		cmbxAncNodes.setBounds(228, 342, 193, 28);
		frmDrawgramControls.getContentPane().add(cmbxAncNodes);

		branchScaleAutoRB.addActionListener(new ActionListener() {
			public void actionPerformed(ActionEvent e) {
				ScaleAutoToggle(branchScaleAutoRB.isSelected());
			}
		});
		
		
		btnPreview = new JButton("Preview");
		btnPreview.setFont(new Font("Arial", Font.BOLD, 13));
		btnPreview.addActionListener(new ActionListener() {
			public void actionPerformed(ActionEvent e) {
				DrawgramData inputdata = new DrawgramData();
				inputdata.doplot = false;
				boolean retval = LaunchDrawgramInterface(inputdata);
				if (retval)
				{
					
					String title = "Preview: " + (String)PlotTxt.getText();
					String curDir = System.getProperty("user.dir");
					curDir += "/JavaPreview.ps";

					new DrawPreview(title, curDir);
				}
			}
		});
		
		btnPreview.setBounds(25, 406, 117, 29);
		frmDrawgramControls.getContentPane().add(btnPreview);
		
		btnQuit = new JButton("Quit");
		btnQuit.setFont(new Font("Arial", Font.BOLD, 13));
		btnQuit.addActionListener(new ActionListener() {
			public void actionPerformed(ActionEvent e) {
				System.exit(0);
			}
		});
		btnQuit.setBounds(342, 406, 117, 29);
		frmDrawgramControls.getContentPane().add(btnQuit);
		
		JLabel lblBranchLen = new JLabel(" (if present)");
		lblBranchLen.setFont(new Font("Arial", Font.BOLD, 13));
		lblBranchLen.setBounds(345, 174, 89, 16);
		frmDrawgramControls.getContentPane().add(lblBranchLen);
		
		plotBtn = new JButton("Plot File");
		plotBtn.setFont(new Font("Arial", Font.BOLD, 13));
		plotBtn.addActionListener(new ActionListener() {
			public void actionPerformed(ActionEvent arg0) {
				ChooseFile(PlotTxt);
			}
		});
		plotBtn.setBounds(10, 39, 117, 28);
		frmDrawgramControls.getContentPane().add(plotBtn);
		
		PlotTxt = new JTextField();
		PlotTxt.setFont(new Font("Arial", Font.PLAIN, 13));
		PlotTxt.setText("plotfile.ps");
		PlotTxt.setBounds(131, 39, 333, 28);
		frmDrawgramControls.getContentPane().add(PlotTxt);
		PlotTxt.setColumns(10);
		
		btnPlotFile = new JButton("Create Plot File");
		btnPlotFile.setFont(new Font("Arial", Font.BOLD, 13));
		btnPlotFile.addActionListener(new ActionListener() {
			public void actionPerformed(ActionEvent e) {
				DrawgramData inputdata = new DrawgramData();
				inputdata.doplot = true;
				@SuppressWarnings("unused")
				boolean retval = LaunchDrawgramInterface(inputdata);
			}
		});
		btnPlotFile.setBounds(164, 406, 156, 29);
		frmDrawgramControls.getContentPane().add(btnPlotFile);
		
		JLabel lblPSFont = new JLabel("PostScript Font:");
		lblPSFont.setFont(new Font("Arial", Font.BOLD, 13));
		lblPSFont.setHorizontalAlignment(SwingConstants.RIGHT);
		lblPSFont.setBounds(13, 87, 211, 16);
		frmDrawgramControls.getContentPane().add(lblPSFont);
		
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
		cmbxPlotFont.setBounds(228, 81, 228, 28);
		cmbxPlotFont.setRenderer(new DefaultListCellRenderer() {
		    public void paint(Graphics g) {
		        setBackground(Color.WHITE);
		        setForeground(Color.BLACK);
		        super.paint(g);
		    }
		});
		frmDrawgramControls.getContentPane().add(cmbxPlotFont);
		
		lblFinalPlotType = new JLabel("Final plot file type:");
		lblFinalPlotType.setHorizontalAlignment(SwingConstants.TRAILING);
		lblFinalPlotType.setFont(new Font("Arial", Font.BOLD, 13));
		lblFinalPlotType.setBounds(13, 377, 211, 16);
		frmDrawgramControls.getContentPane().add(lblFinalPlotType);
		
		cmbxFinalPlotType = new JComboBox();
		cmbxFinalPlotType.setModel(new DefaultComboBoxModel(new String[] {
				"Postscript","PICT", "PCL","Windows BMP","FIG 2.0","Idraw","VRML","PCX","Tek4010",
				"X Bitmap","POVRAY 3D","Rayshade 3D","HPGL","DEC ReGIS","Epson MX-80","Prowriter/Imagewriter",
//				"Toshiba 24-pin","Okidata dot-matrix","Houston Instruments plotter", "other"
				"Okidata dot-matrix","Houston Instruments plotter", "other" // remove Toshiba - broken in drawgram
				}));
		cmbxFinalPlotType.setSelectedIndex(0);
		cmbxFinalPlotType.setFont(new Font("Arial", Font.PLAIN, 13));
		cmbxFinalPlotType.setBounds(228, 371, 193, 28);
		cmbxFinalPlotType.setRenderer(new DefaultListCellRenderer() {
		    public void paint(Graphics g) {
		        setBackground(Color.WHITE);
		        setForeground(Color.BLACK);
		        super.paint(g);
		    }
		});
		frmDrawgramControls.getContentPane().add(cmbxFinalPlotType);
		
		
		
	}
}
