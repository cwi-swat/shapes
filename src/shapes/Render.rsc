module shapes::Render
import util::HtmlDisplay;
import shapes::FigureServer;
import shapes::Figure;
import shapes::IFigure;

public void render(Figure fig1..., int width = -1, int height = -1, 
     Alignment align = <0.5, 0.5>, tuple[int, int] size = <0, 0>,
     str fillColor = "none", str lineColor = "black", bool debug = false,  
     Event event = on(nullCallback), int borderWidth = -1, str borderStyle = "", str borderColor = ""
     ,int lineWidth = -1, bool resizable = true, str cssFile="", bool defined = true, bool static = false)
     {
     renderWeb(fig1, width = width,  height = height,  align = align, fillColor = fillColor
     , lineColor = lineColor, lineWidth = lineWidth, size = size, event = event
     , borderWidth = borderWidth, borderStyle = borderStyle, borderColor=borderColor
     , resizable = resizable, defined = (width? && height?)||(size?) || defined, cssFile = cssFile, 
     debug = debug, static = static);
     // println(toString());
     htmlDisplay(getSite()+(static?"static":"dynamic"));
     }