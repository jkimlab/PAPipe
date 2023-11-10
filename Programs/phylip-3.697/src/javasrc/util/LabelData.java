package util;
import java.awt.Font;
import java.awt.Point;

public class LabelData {
	Font m_useFont;
	Point.Double m_translation;
	Double m_rotation;
	String m_displayText;
	public LabelData()
	{
		m_useFont = new Font("SanSerif", Font.PLAIN, 12);
		m_translation = new Point.Double(0,0);
		m_rotation = 0.0;
		m_displayText = new String("undefined");
	}
	
	public LabelData(Font useFont, Point.Double translation, Double rotation, String displayText)
	{
		m_useFont = useFont;
		m_translation = translation;
		m_rotation = rotation;
		m_displayText = displayText;
	}
}
