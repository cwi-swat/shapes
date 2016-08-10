@license{
  Copyright (c) 2009-2015 CWI
  All rights reserved. This program and the accompanying materials
  are made available under the terms of the Eclipse Public License v1.0
  which accompanies this distribution, and is available at
  http://www.eclipse.org/legal/epl-v10.html
}
@contributor{Bert Lisser - Bert.Lisser@cwi.nl (CWI)}
@contributor{Paul Klint - Paul.Klint@cwi.nl - CWI}
module shapes::Figure

import util::Math;
import Prelude;
import lang::json::IO;

int occur = 0;

void initFigure() { occur = 0;}

/* Properties */

// Position for absolute placement of figure in parent

alias Position = tuple[num x, num y];

alias Rotate = tuple[num angle, num x, num y];

alias Rescale = tuple[tuple[num, num], tuple[num, num]];


// Alignment for relative placement of figure in parent



public alias Alignment = tuple[num hpos, num vpos];

public Alignment topLeft      	= <0.0, 0.0>;
public Alignment topMid          	= <0.5, 0.0>;
public Alignment topRight     	= <1.0, 0.0>;

public Alignment centerLeft   		= <0.0, 0.5>;
public Alignment centerMid     = <0.5, 0.5>;
public Alignment centerRight 	 	= <1.0, 0.5>;

public Alignment bottomLeft   	= <0.0, 1.0>;
public Alignment bottomMid 		= <0.5, 1.0>;
public Alignment bottomRight	= <1.0, 1.0>;


data Orientation =
		leftRight()
	|	rightLeft()
	| 	topDown()
	|	downTop();

// Events and bindings for input elements
alias StrCallBack = void(str,str,str);
alias RealCallBack = void(str,str,real);
alias IntCallBack = void(str,str,int);

// alias InputType = tuple[str lab, str f];


data Event
	= on(StrCallBack strCallBack)
	| on(RealCallBack realCallBack)
	| on(IntCallBack intCallBack)
	| on(str eventName, StrCallBack strCallBack)
	| on(str eventName, RealCallBack realCallBack) 
	| on(str eventName, IntCallBack intCallBack)
	| on(list[str] eventList, StrCallBack strCallBack)
	| on(list[str] eventList, RealCallBack realCallBack)
	| on(list[str] eventList, IntCallBack intCallBack)
	| noEvent()
	;


alias XYData 			= lrel[num x, num y];

/* 
   In bars the first column (rank) determines the bar placement order.	
   The third column is the category label. 
   In lines the third column determines the tooltips belonging to the points
*/
		 		 
alias XYLabeledData     = lrel[num xx, num yy, str label];	

alias GoogleData     = list[list[value]];	

data DDD = ddd(str name="", int size = 0, list[DDD] children = [], int width =10, int height = 10);

//data Margin = margin(int left = 0, int right = 0, int top = 0, int bottom = 0);

/*
	link
	gradient(numr)
	texture(loc image)
	lineCap flat, rounded, padded
	lineJoin	smooth, sharp(r), clipped
	dashOffset
		
	linestyle: color, width, cap, join, dashing, dashOffset
*/

// Vertices for defining shapes.

data Vertex
	= line(num x, num y)
	| lineBy(num x, num y)
	| move(num x, num y)
	| moveBy(num x, num y)
	| arc(num rx, num ry, num rotation, bool largeArc, bool sweep, num x, num y)
	;
	
alias Vertices = list[Vertex];

alias Points = lrel[num x, num y];

alias Constraint = tuple[bool(value v) cond, str emsg];

alias FormEntry = tuple[str id, value startValue, str fieldName, list[Constraint] constraints];

public alias Figures = list[Figure];

public num nullFunction(list[num] x) { return 0;}

void nullCallback(str x, str y, str z) {return;}

public data Attr (
    int width = -1,
    int height =  -1,
    int r = -1,
    num bigger = 1.0,
    bool disabled = false 
    ) = attr();
    
public data Property (
     value \value = ""
    ) = property();
    
public data Timer (
     int delay = -1,
     str command = ""
     // ,str mark = ""
    ) = timer();
    
    
public data Style (	
    bool svg = false,
    str visibility = "", 
    int width = -1,
    int height = -1,	
    int lineWidth = -1,			
    str lineColor = "", 
    str fillColor= "", 
    num fillOpacity = -1.0, 
    num lineOpacity= -1.0   
    ) = style();
    
    
public data Text (		
    str plain = "",
    str html = ""  
    ) = text();
    
    
public alias Prop =
    tuple[Attr attr, Style style,  Property property, Text text, Timer timer];
    
 
// public str strEmpty() {return "";}
    
    
public data Figure(
        // Naming
        str id = "",
        str visibility = "",  // hidden | visible
		// Dimensions and Alignmenting
		tuple[int,int] size = <0,0>,
		tuple[int, int, int, int] padding = <0, 0, 0, 0>, // left, top, right, botton 
		int width = -1,
		int height = -1,
		Position at = <0, 0>,
		Rotate rotate = <0, -1, -1>, 
		Alignment align = <0.5, 0.5>,
		Alignment cellAlign = <-1, -1>, 
		num bigger = 1.0,
		num shrink = 1.0, 
		num hshrink = 1.0, 
		num vshrink = 1.0, 
		num grow = 1.0, 
		num hgrow = 1.0, 
		num vgrow = 1.0, 
		bool resizable = true,
		tuple[int,int] gap = <0,0>,
		int hgap = 0,
		int vgap = 0,
        bool sizeFromParent = false,
        
    	// Line properties
		int lineWidth = -1,			
		str lineColor = "", 		
		list[int] lineDashing = [],	
		real lineOpacity = -1.0,
	
		// Area properties
		str fillColor    = "none", 			
		real fillOpacity = -1.0,	
		str fillRule     = "evenodd",
		
		tuple[int, int] rounded = <0, 0>,

		// Font and text properties
		
		str fontFamily = "",// "Helvetica, Arial, Verdana, sans-serif",
		str fontName = "", // "Helvetica",
		int fontSize = -1, // 12,
		str fontStyle = "",  //  normal|italic|oblique|initial|inherit   
		str fontWeight = "", // normal|bold|bolder|lighter|number|initial|inherit; normal==400, bold==700
		str fontColor = "",  // default "black",
		str textDecoration	= "", // none|underline|overline|line-through|initial|inherit
		
		// Interaction
		Event event = noEvent(),
		
		// Tooltip
		value tooltip = "",
		
		// Panel
		Figure panel = emptyFigure()
	) =
	
	emptyFigure(int seq = 0)
  

// atomic primitivesreturn [[z] +[*((c[z]?)?c[z]:"null")|c<-m]|z<-x];
	
   | htmlText(value text, str overflow = "hidden")		    			// text label html
   | text(value text, str overflow = "hidden")		    			// text label svg
// | markdown(value text)					// text with markdown markup (TODO: make flavor of text?)
// | math(value text)						// text with latex markup
   
// Graphical elements

   | box(Figure fig=emptyFigure())      	// rectangular box with inner element
   
   | ellipse(num cx = -1, num cy = -1, num rx=-1, num ry=-1, Figure fig=emptyFigure())
   
   | circle(num cx = -1, num cy = -1, num r=-1, Figure fig=emptyFigure())

// regular polygon   
   | ngon(int n=3, num r=-1, num angle = 0, Figure fig=emptyFigure(),
        Rescale scaleX = <<0,1>, <0, 1>>,
   	    Rescale scaleY = <<0,1>, <0, 1>>
     )	
   
   | polygon(Points points=[], bool fillEvenOdd = true,
            bool yReverse = false,
            Rescale scaleX = <<0,1>, <0, 1>>,
   			Rescale scaleY = <<0,1>, <0, 1>>)
   
   | shape(list[Vertex] vertices, 				// Arbitrary shape
   			bool shapeConnected = true, 	// Connect vertices with line/curve
   			bool shapeClosed = false, 		// Make a closed shape
   			bool shapeCurved = false, 		// Connect vertices with a spline
   			bool fillEvenOdd = true,
   			bool yReverse = true,		
   			Rescale scaleX = <<0,1>, <0, 1>>,
   			Rescale scaleY = <<0,1>, <0, 1>>,
   			Figure startMarker=emptyFigure(),
   			Figure midMarker=emptyFigure(), 
   			Figure endMarker=emptyFigure())
   
   | image(str src="")

// Figure composers
// borderStyle =  none|hidden|dotted|dashed|solid|double|groove|ridge|inset|outset|initial|inherit;              
   | hcat(Figures figs=[], str borderStyle="solid", int borderWidth=0, str borderColor = "", bool form= false) 					// horizontal and vertical concatenation
   | vcat(Figures figs=[], str borderStyle="solid", int borderWidth=0, str borderColor = "", bool form= false) 					// horizontal and vertical concatenation 
   | overlay(Figures figs=[])				
   | grid(list[Figures] figArray = [[]], str borderStyle="solid", int borderWidth=0, str borderColor = "", bool form= false) 	// grid of figures

// Figure transformations

   | atXY(int x, int y, Figure fig)	
   | atXY(tuple[int x, int y] xy, Figure fig)			// Move to Alignment relative to origin of enclosing Figure
   | atX(int x, Figure fig)				// TODO: how to handle negative values?
   | atY(int y, Figure fig)
   
   | rotateDeg(num angle, int x, int y, Figure fig)
   | rotateDeg(num angle, Figure fig)
   
// Input elements
   | buttonInput(str txt, bool disabled=false,  value \value = "")
   | checkboxInput(list[str] choices = ["0"], value \value = ())
   | choiceInput(list[str] choices = ["0"], value \value = choices[0])
   // | colorInput()
   
   // date
   // datetime
   // email
   // month
   // time
   // tel
   // week
   // url
   
  //  | numInput()
   | rangeInput(num low=0, num high=100, num step=1, value \value = 50.0)
   | strInput(int nchars=20, value \value="", bool keydown= true) 
   | choice(int selection = 0, Figures figs = [])
  
/*
   | _computeFigure(bool() recomp,Figure () computeFig, FProperties props)
 
*/


// Charts
	| comboChart(list[Chart] charts =[],  ChartOptions options = chartOptions(), bool tickLabels = false,
	  int tooltipColumn = 1)
    | lineChart(GoogleData googleData = [], XYData xyData = [], ChartOptions options = chartOptions())
    | areaChart(GoogleData googleData = [], XYData xyData = [], ChartOptions options = chartOptions())
	| scatterChart(GoogleData googleData = [], XYData xyData = [], ChartOptions options = chartOptions())
	| candlestickChart(GoogleData googleData =[], ChartOptions options = chartOptions())
	| pieChart(GoogleData googleData = [],  ChartOptions options = chartOptions())

   | graph(list[tuple[str, Figure]] nodes = [], list[Edge] edges = [], map[str, NodeProperty] nodeProperty = (), 
     GraphOptions graphOptions = graphOptions(), map[str, str] figId=())
   | tree(Figure root, list[Figure] figs
	       ,int xSep = 1, int ySep = 2, str pathColor = "black"
	       ,Orientation orientation = topDown()
	       ,bool manhattan=false
// For memory management
	       , int refinement=5, int rasterHeight=150)
	       
   |d3Pack(DDD d = ddd(), str fillNode="rgb(31, 119, 180)", str fillLeaf = "ff7f0e", num fillOpacityNode=0.25, num fillOpacityLeaf=1.0,
          int diameter = 960, bool inTooltip = false)
   |d3Treemap(DDD d = ddd(), bool inTooltip = false)
   |d3Tree(Figure root)
   |d3Tree(DDD d = ddd())
   ;
   
data GraphOptions = graphOptions(
    str orientation = "topDown", int nodeSep = 50, int edgeSep=10, int layerSep= 30, str flavor="layeredGraph"
        
    );
 
data NodeProperty = nodeProperty(str shape="",str labelStyle="", str style = "", str label="");

data Edge = edge(str from, str to, str label = "", str lineInterpolate="basis" // linear, step-before, step-after
     , str lineColor = "" ,str labelStyle="", str arrowheadStyle = "" // normal, vee, undirected
     , str id = "", str labelPos= "r"  // l, r, c
     , list[int] lineDashing = []
     , int labelOffset = 10, int lineWidth = -1);
  
data ChartArea ( 
     value left = "",
     value width = "",
     value top = "",
     value height = "",
     value backgroundColor = ""
     ) = chartArea();
 
                
data Legend (bool none = false,
             str alignment = "",
             int maxLines = -1,
             str position ="") = legend()
            ;
            
           
data ViewWindow(int max = -1, int min = -1) = viewWindow();

data Gridlines(str color = "", int count =-1) = gridlines();

data Series (
    str color ="",
    str curveType = "",
    int lineWidth = -1,
    str pointShape = "",
    int pointSize = -1,
    str \type=""
    ) = series();
    

data Bar (value groupWidth = "") = bar();

data Animation(
      int duration = -1,
      str easing = "",
      bool startup = false
      ) = animation();

data Tick(num v = -1, str f  ="") = tick();

data TextStyle(str color="", str fontName="", int fontSize=-1, 
       bool bold = false, bool italic = false) = textStyle();
    
data Axis(str title="",
          num minValue = -1,
          num maxValue = -1,
          ViewWindow viewWindow_= ViewWindow::viewWindow(),
          bool slantedText = true,
          bool logScale = false,
          int slantedTextAngle = -1, 
          int direction = -1,
          str textPosition = "",
          str format = "", 
           Gridlines gridlines_ =  Gridlines::gridlines() ,
          list[Tick] tick_ = [],
          TextStyle titleTextStyle_ = textStyle(),
          TextStyle textStyle_ = textStyle())
          = axis();
          
               
data Candlestick( 
     bool hollowIsRising = false,
     CandlestickColor fallingColor = candlestickColor(),
     CandlestickColor risingColor = candlestickColor()
     ) = candlestick(); 
     

data CandlestickColor( 
     str fill = "",
     str stroke = "",
     int strokeWidth = -1
     ) = candlestickColor(); 
     
data SankeyColor( 
     str fill = "",
     str stroke = "",
     real fillOpacity = -1.0,
     int strokeWidth = -1
     ) = sankeyColor(); 

data SankeyLabel( 
     str fontName = "",
     int fontSize = -1,
     str color = "",
     int strokeWidth = -1,
     bool bold = false, 
     bool italic = false
     ) = sankeyLabel(); 
     
data SankeyNode(
     SankeyLabel label = sankeyLabel(),
     int labelPadding = -1,
     int nodePadding = -6,
     int width = -1
     ) = sankeyNode();
         
data SankeyLink (
     SankeyColor color = sankeyColor()
     ) = sankeyLink();
  
data Sankey(
      int iterations = -1,
      SankeyLink link = sankeyLink(),
      SankeyNode \node = sankeyNode()
     ) = sankey();   
                  
data ChartOptions (str title = "",
             Animation animation_ = Animation::animation(),
             Axis hAxis = axis(),
             Axis vAxis = axis(),
             ChartArea chartArea_ = ChartArea::chartArea(),
             Bar bar_ = Bar::bar(),
             int width=-1,
             int height = -1,
             bool forceIFrame = true,
             bool is3D = false, 
             Legend legend_ = Legend::legend(),
             int lineWidth = -1,
             int pointSize = -1,
             bool interpolateNulls = false,
             str curveType = "",
             str seriesType = "",
             str pointShape = "",
             bool isStacked = false,
             Candlestick candlestick_ = Candlestick::candlestick(),
             Sankey sankey_ = Sankey::sankey(),
             list[Series] series_ = []
             ) = chartOptions()
            ;
            

ChartOptions updateOptions (list[Chart] charts, ChartOptions options) {
    options.series_ = [];
    for (c<-charts) {
        Series s = series();
        switch(c) {
            case Chart::line(XYData d1): s.\type = "line";
            case Chart::line(XYLabeledData d2): s.\type = "line";
            case Chart::area(XYData d3): s.\type=  "area";
            case Chart::area(XYLabeledData d4): s.\type=  "area";
            case Chart::bar(_) : s.\type = "bars";
            }
        if (!isEmpty(c.color)) s.color = c.color;
        if (!isEmpty(c.curveType)) s.curveType = c.curveType;
        if (c.lineWidth>=0)  s.lineWidth = c.lineWidth;
        if (!isEmpty(c.pointShape)) s.pointShape = c.pointShape;
        if (c.pointSize>=0) s.pointSize = c.pointSize;
        options.series_ += [s];
        }
    return options;
    }   

data Chart(str name = "", str color = "", str curveType = "",
     int lineWidth = -1, str pointShape = "", int pointSize = -1)
    =
	  line(XYData xydata) 
	| line(XYLabeledData xylabeleddata) 
	| area(XYData xydata)
	| area(XYLabeledData xylabeleddata)
	| bar(XYLabeledData xylabeledData)
	;
	

public Figure idEllipse(num rx, num ry) = ellipse(rx=rx, ry = ry, lineWidth = 0, fillColor = "none");

public Figure idCircle(num r) = circle(r= r, lineWidth = 0, fillColor = "none");

public Figure idNgon(int n, num r) = ngon(n=  n, r= r, lineWidth = 0, fillColor = "none");

public Figure idRect(int width, int height) = box(width = width, height = height, lineWidth = 0, fillColor = "none");

/* options must be renamed to graphOptions */
public Figure graph(list[tuple[str, Figure]] n, list[Edge] e, tuple[int, int] size=<0,0>, int width = -1, int height = -1,
   int lineWidth = 1, GraphOptions options = graphOptions()) =  
   graph(nodes = n, edges = e, lineWidth = lineWidth, 
               nodeProperty = (), size = size, width = width, height = height,
               graphOptions = options)
               ;
             	
	
map[str, str] getTooltipMap(int tooltipColumn) {
    str typ = tooltipColumn < 0 || tooltipColumn == 2 ? "string":"number";
    return ("type": typ, "role":"tooltip");
    }

tuple[list[map[str, str]] header, map[tuple[value, int], list[value]] \data] 
   tData(Chart c, int tooltipColumn) {
     list[list[value]] r = [];
     list[map[str, str]] h = [];
     switch(c) {
        case line(XYData x): {r = [[d[0], d[1]]|d<-x]; h = [("type":"number", "label":c.name)];}
        case area(XYData x): {r = [[d[0], d[1]]|d<-x]; h = [("type":"number", "label":c.name)];}
        case line(XYLabeledData x): {
                                     r = [[d[0], d[1], tooltipColumn>=0?"<d[tooltipColumn]>":d[2]]|d<-x];
                                     h = [("type":"number", "label":c.name), getTooltipMap(tooltipColumn)];
                                    }
        case area(XYLabeledData x): {
                                      r = [[d[0], d[1], tooltipColumn>=0?"<d[tooltipColumn]>":d[2]]|d<-x];
                                      h = [("type":"number", "label":c.name), getTooltipMap(tooltipColumn)];
                                    }
        case bar(XYLabeledData x): {
                                    r = [[d[0], d[1], tooltipColumn>=0?"<d[tooltipColumn]>":d[2]]|d<-x]; 
                                    h = [("type":"number","label":c.name), getTooltipMap(tooltipColumn)];
                                   }           
        }
     map[tuple[value, int], list[value]] q  = ();
     for (d<-r) {
         int i = 0;
         while(q[<d[0], i>]?) i = i + 1;
         q[<d[0], i>] = tail(d);
         }
     return <h, q>;
     }
     
bool hasXYLabeledData(Chart c) {
     switch(c) {
         case line(XYLabeledData _): return true;
         case area(XYLabeledData _): return true;
         case bar(XYLabeledData _): return true;
         }
     return false;
     } 
    

list[list[value]] joinData(list[Chart] charts, bool tickLabels, int tooltipColumn) {
   list[tuple[list[map[str, str]] header, map[tuple[value, int], list[value]]\data]] m = [tData(c, tooltipColumn)|c<-charts];   
   set[tuple[value, int]] d = union({domain(c.\data)|c <-m});   
   list[tuple[value, int]] x = sort(toList(d));
   int i = 0;
   for (c<-charts) {
       if (hasXYLabeledData(c)) break;
       i = i +1;
       }
   if (!tickLabels || i == size(charts)) 
      return [[("type":"number")]+[*c.\header|c<-m]]+[[z[0]] +[*((c.\data[z]?)?c.\data[z]:"null")|c<-m]|z<-x];
   else {
      map[value, value] lab =  (z:m[i].\data[z][1]|z<-x);
      m = [tData(c, tooltipColumn)|c<-charts];  
      return 
           [[("type":"string")]+[*c.\header|c<-m]]+
           [[lab[z]] +[*((c.\data[z]?)?c.\data[z]:"null")|c<-m]|z<-x];
      }
   }

/* 
public Figure svg(Figure f, tuple[int, int] size = <0, 0>) {
    Figure r = box(size=size, lineWidth = 0, fillColor = "none", fig = f);
    return r;
    }
*/
  
public map[str, value] adt2map(node t) {
   map[str, value] q = getKeywordParameters(t);
   map[str, value] r = (replaceLast(d,"_",""):q[d]|d<-q);
   for (d<-r) {
        if (node n := r[d]) {
           r[d] = adt2map(n);
        }
        if (list[node] l:=r[d]) {
           r[d] = [adt2map(e)|e<-l];
           }
      }
   return r;
   }
   
public str adt2json(node t) {
   return toJSON(adt2map(t), true);
   }
      
public Figure plot(Points xy, Rescale x, Rescale y, bool shapeCurved = true
      ,str lineColor = "", int lineWidth = -1, str fillColor = ""
      , int width = -1, int height = -1
      , bool fillEvenOdd = true
      ) {
      Vertices v = [move(head(xy)[0], head(xy)[1])]
                  +[line(d[0], d[1])|d<-tail(xy)];
      return shape(v, scaleX = x, scaleY = y, shapeCurved = shapeCurved,
      lineColor = lineColor, lineWidth = lineWidth, fillColor = fillColor,
      width = width, height = height, fillEvenOdd = fillEvenOdd);
      }

public Figure frame(Figure f, num shrink=1.0, num grow=1.0, str id = "", str visibility="visible") {
      return box(lineWidth=0, fillColor="none", fig = f, shrink= shrink, grow = grow, id = false?"<newId()>_frame":id
      , visibility = visibility);
      }
      
public Figure circleSegment(num cx = 100, num cy =100, num r =50, num startAngle = 0, num endAngle =60,
      str fillColor = "", str lineColor = "", int lineWidth = -1, bool fill = true,tuple[int,int] size = <0,0>
      ) {
      num x1 = cx+ r*cos(startAngle/180*PI());
      num y1 = cy+ r*sin(startAngle/180*PI());
      num x2 = cx +r*cos(endAngle/180*PI());
      num y2 = cy +r*sin(endAngle/180*PI());
      Vertices v = [move(x1, y1), arc(r, r, 0, false, true, x2, y2)];
      if (fill) v+= [line(cx, cy)];
      return shape(v, fillColor = fillColor, lineColor = lineColor, lineWidth = lineWidth, shapeClosed=fill, size = size);
      }
      
int currentColor = 7;

public void resetColor() {currentColor = 7;} 

public str pickColor() {int r = currentColor;currentColor = (currentColor+3)%size(colors); return colors[r];}

public str figToString(Figure f) {
     str r = "<f>";
     r = replaceAll(r, "\<0.0,0.0\>", "topLeft");
     r = replaceAll(r, "\<0.5,0.0\>", "topMid");
     r = replaceAll(r, "\<1.0,0.0\>", "topRight");
     r = replaceAll(r, "\<0.0,0.5\>", "centerLeft");
     r = replaceAll(r, "\<0.5,0.5\>", "centerMid");
     r = replaceAll(r, "\<1.0,0.5\>", "centerRight");
     r = replaceAll(r, "\<0.0,1.0\>", "bottomLeft");
     r = replaceAll(r, "\<0.5,1.0\>", "bottomMid");
     r = replaceAll(r, "\<1.0,1.0\>", "bottomRight");
     return r;
     }


public list[str] colors = 
["aliceblue",
            "antiquewhite",
            "aqua",
            "aquamarine",
            "azure",
            "beige",
            "bisque",
            "black",
            "blanchedalmond",
            "blue",
            "blueviolet",
            "brown",
            "burlywood",
            "cadetblue",
            "chartreuse",
            "chocolate",
            "coral",
            "cornflowerblue",
            "cornsilk",
            "crimson",
            "cyan",
            "darkblue",
            "darkcyan",
            "darkgoldenrod",
            "darkgray",
            "darkgreen",
            "darkkhaki",
            "darkmagenta",
            "darkolivegreen",
            "darkorange",
            "darkorchid",
            "darkred",
            "darksalmon",
            "darkseagreen",
            "darkslateblue",
            "darkslategray",
            "darkturquoise",
            "darkviolet",
            "deeppink",
            "deepskyblue",
            "dimgray",
            "dodgerblue",
            "firebrick",
            "floralwhite",
            "forestgreen",
            "fuchsia",
            "gainsboro",
            "ghostwhite",
            "gold",
            "goldenrod",
            "gray",
            "green",
            "greenyellow",
            "honeydew",
            "hotpink",
            "indianred",
            "indigo",
            "ivory",
            "khaki",
            "lavender",
            "lavenderblush",
            "lawngreen",
            "lemonchiffon",
            "lightblue",
            "lightcoral",
            "lightcyan",
            "lightgoldenrodyellow",
            "lightgray",
            "lightgreen",
            "lightpink",
            "lightsalmon",
            "lightseagreen",
            "lightskyblue",
            "lightslategray",
            "lightsteelblue",
            "lightyellow",
            "lime",
            "limegreen",
            "linen",
            "magenta",
            "maroon",
            "mediumaquamarine",
            "mediumblue",
            "mediumorchid",
            "mediumpurple",
            "mediumseagreen",
            "mediumslateblue",
            "mediumspringgreen",
            "mediumturquoise",
            "mediumvioletred",
            "midnightblue",
            "mintcream",
            "mistyrose",
            "moccasin",
            "navajowhite",
            "navy",
            "oldlace",
            "olive",
            "olivedrab",
            "orange",
            "orangered",
            "orchid",
            "palegoldenrod",
            "palegreen",
            "paleturquoise",
            "palevioletred",
            "papayawhip",
            "peachpuff",
            "peru",
            "pink",
            "plum",
            "powderblue",
            "purple",
            "rebeccapurple",
            "red",
            "rosybrown",
            "royalblue",
            "saddlebrown",
            "salmon",
            "sandybrown",
            "seagreen",
            "seashell",
            "sienna",
            "silver",
            "skyblue",
            "slateblue",
            "slategray",
            "snow",
            "springgreen",
            "steelblue",
            "tan",
            "teal",
            "thistle",
            "tomato",
            "turquoise",
            "violet",
            "wheat",
            "white",
            "whitesmoke",
            "yellow",
            "yellowgreen"
        ];
        
 public str randomColor() =  colors[arbInt(size(colors))];
 
 
 Figure(Figure , str ) self(Figure g) {return 
              Figure(Figure f, value c) {g.fig = f; return g;}
              ;}
              
public str newName() {
  occur+=1;
  return "myName<occur>";
  }
  
public str newId() {
  occur+=1;
  return "myName<occur>";
  }
  
str fileName(loc l) {
     str p = l.path;
     int n = findLast(p, "/");
     return substring(p, n+1, size(p));
     }
     
map[str, list[list[str]]] _compact(list[list[str]] xs) { 
    if (isEmpty(xs)) return ();  
    map[str,  list[list[str]]] r = ();
    for (list[str] x<-xs) {
         list[list[str]] q = ((r[head(x)]?)? r[head(x)]+[tail(x)]:[tail(x)]);
         r[head(x)] = q;
         }
    return r;
    }
  
list[DDD] compact(list[list[str]] xs, map[loc, int] m, loc path) {
    map[str, list[list[str]]] q = _compact(xs);
    list[DDD] r = [];
    for (str x<-q) {
         if (isEmpty(head(q[x]))) r = r + ddd(name=substring(x, 0, findLast(x, ".")), size=m[path+x]); 
         else r = r + ddd(name=x, children=compact(q[x], m, path +x));
         }
    return r;
    }
  
public DDD fileMap(loc source, str suffix) {
    list[loc] todo = [source];
    list[loc] done = [];
    while (!isEmpty(todo)) {
        <elem,todo> = takeOneFrom(todo);
        for (e <- listEntries(elem)) {
           loc f = elem +e;
		   if (isDirectory(f)) {
		   	todo += f;
		   }
		   else {
		        if (endsWith(f.path, suffix))
		        done += f;
		   }
	      }
	    }
        map[loc, int] m = (d:size(readFileLines(d))|d<-done);
        list[list[str]] r = [];
        for (d<-done) {
            str p = d.path; 
            r=r+[split("/", p)];
            }
        list[DDD] p = compact(r, m, source.parent);
        return head(p);
    }
 
 public tuple[int, int](num, num) lattice(int width, int height, int nx, int ny) {
     return tuple[int, int](num x, num y){return <toInt((x*width)/nx), toInt((y*height)/ny)>;};
     }
     
 public int (num) latticeX(int width, int nx) {
     return int(num x){return toInt((x*width)/nx);};
     }
     
 public int(num) latticeY(int height, int ny) {
     return int(num y){return toInt((y*height)/ny);};
     }
     
     