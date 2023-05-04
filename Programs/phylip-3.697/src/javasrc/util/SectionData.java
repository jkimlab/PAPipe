package util;

import java.awt.geom.CubicCurve2D;
import java.awt.geom.Line2D;
import java.util.ArrayList;

public class SectionData {
	public Double strokewidth;
	public ArrayList <Line2D.Double> lines;
	public ArrayList <CubicCurve2D.Double> curves;
	public ArrayList <LabelData> texts;
	public SectionData()
	{
		strokewidth = -1.0;
		texts = new ArrayList<LabelData>();
		lines = new ArrayList<Line2D.Double>();
		curves = new ArrayList<CubicCurve2D.Double>();
	}
}
