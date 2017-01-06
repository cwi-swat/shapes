@license{
  Copyright (c) 2009-2015 CWI
  All rights reserved. This program and the accompanying materials
  are made available under the terms of the Eclipse Public License v1.0
  which accompanies this distribution, and is available at
  http://www.eclipse.org/legal/epl-v10.html
}
@contributor{Bert Lisser - Bert.Lisser@cwi.nl (CWI)}
@contributor{Paul Klint - Paul.Klint@cwi.nl - CWI}

module shapes::IFigure
import Prelude;
import util::Webserver;
import lang::json::IO;
import util::Math;

import shapes::Figure;
import shapes::Tree;
import util::Reflective;
import util::Eval;
 
private loc base = getModuleLocation("shapes::Figure").parent;

private bool reload = false;

public loc getBase()= base;


alias Options = tuple[
       int width, int height
     , Alignment align, tuple[int, int] size
     , str fillColor, str lineColor 
     , int lineWidth, bool display, real lineOpacity, real fillOpacity
     , Event event, int borderWidth, str borderStyle, str borderColor
     , bool resizable, bool defined, str cssFile]
     ;
     
Options options = <-1, -1 ,topLeft, <-1, -1> ,"", "" ,-1, false, 1.0, 1.0 ,noEvent(), -1, "", "" ,false, false, "">;
     
public Options getOptions() = options;

public void setOptions(Options opt) {options = opt;}

// The random accessable data element by key id belonging to a widget, like _box, _circle, _hcat. 

alias Elm = tuple[value f, int seq, str id, str begintag, str endtag, str script, int width, int height,
      int x, int y, num hshrink, num vshrink, 
      Alignment align,  Alignment cellAlign, int lineWidth, str lineColor, bool sizeFromParent, bool svg];

// Map which stores the widget info

public map[str, Elm] widget = (); 


bool _display = true;


// The tree which is the compiled Figure, the only field is id.
// Id is a reference to hashmap widget

public data IFigure = ifigure(str id, list[IFigure] child);

// public data IFigure = ifigure(str content);

public data IFigure = iemptyFigure(int seq);

// --------------------------------------------------------------------------------

bool debug = false;
str cssLocation = "";

int seq = 0;
int occur = 0;

// ----------------------------------------------------------------------------------
alias State = tuple[str name, Prop v];
public list[State] state = [];
public list[Prop] old = [];
//-----------------------------------------------------------------------------------

public map[str, str] parentMap = ();

public map[str, Figure] figMap = ();

public list[str] widgetOrder = [];

public list[str] adjust = [];

public list[str] googleChart = [];

public list[str] graphs = [];

public list[str] loadCalls = [];

list[IFigure] tooltips = [];

list[IFigure] panels = [];

map[str, map[str, str]] extraGraphData = ();

public list[str] markerScript = [];

public map[str, tuple[str, str]] dialog = ();

public map[str, list[IFigure] ] defs = ();

list[IFigure] currentFigs = [];

list[Figure] currentFigures = [];

tuple[int width, int height] screen = <-1, -1>;

int upperBound = 99999;
int lowerBound = 2;

int getN(IFigure fig1) = getN(getId(fig1));

int getN(Figure fig1) = (Figure g:ngon():= fig1)?g.n:0;

int getN(str id) = (figMap[id]?)?((Figure g:ngon():=figMap[id])?g.n:0):0;

num getAngle(IFigure fig1) = getAngle(getId(fig1));

num getAngle(str id) = (figMap[id]?)?((Figure g:ngon():=figMap[id])?g.angle:0):0;

num getAngle(Figure fig1) = (Figure g:ngon():= fig1)?g.angle:0;


// ----------------------------------------------------------------------------------------

public void setDebug(bool b) {
   debug = b;
   }
   
public bool isSvg(str id) = widget[id].svg;

public void null(str event, str id, str val ){return;}

tuple[str, str] prompt = <"", "">;

str alert = "";

list[tuple[str id, str lab, str val]] labval=[];

bool isPassive(Figure f) = f.event==noEvent()  && isEmptyTooltip(f.tooltip) && f.panel==emptyFigure();

str child(str id1) {
    if (findFirst(id1,"#") < 1) return id1;
    list[str] s = split("#", id1);
    IFigure z = iemptyFigure(0);  
    for (IFigure fig<-currentFigs) {  
    top-down visit(fig) {
        case IFigure g:ifigure(str id ,_): {
             if (id == s[0])  z = g;
             }
        };
     for (str d<-tail(s)) {
             int v = toInt(d);
             if (ifigure(_, list[IFigure] childq):=z) {
                 z = childq[v];
                 }          
              } 
      }
    return z.id;
    }
    
map[str, value] toMap(DDD p)  {
     map[str, value] m = getKeywordParameters(p);
     if (!isEmpty(p.children))
        m["children"] = [toMap(x)|DDD x <- p.children];
     return m;
     } 
     
str clipPath(str id, list[str] cs) {
    if (isEmpty(cs)) return "";
    str r = "\<defs\>\<clipPath id=\"<id>\"\>";
    for (str c<-cs) {
         r+=c;
         }
    r+= "\</clipPath\>\</defs\>";
    return r;
    }   
     
    
map[str, str] _getIdFig(Figure f) = extraGraphData[f.id];
    
Attr _getAttr(str id) = state[widget[child(id)].seq].v.attr;

void _setAttr(str id, Attr v) {
    state[widget[child(id)].seq].v.attr = v;
    }

Style _getStyle(str id) = state[widget[child(id)].seq].v.style;

void _setStyle(str id, Style v) {state[widget[child(id)].seq].v.style = v;}

Text _getText(str id) = state[widget[child(id)].seq].v.text;

Property _getProperty(str id) {return state[widget[id].seq].v.property;}

void _setProperty(str id, Property v) {state[widget[id].seq].v.property = v;}

void _setText(str id, Text v) {state[widget[child(id)].seq].v.text = v;}

void _setPrompt(tuple[str, str] p) {prompt = p;}

void _setAlert(str a) {alert= a;}

str  _getPromptStr(str tg)= dialog[tg][1];

void _setPrompt(list[tuple[str, str , str]] xs) {
      labval = xs;
      }

void _setTimer(str id, Timer v) {state[widget[id].seq].v.timer = v;}

Timer _getTimer(str id) = state[widget[id].seq].v.timer;

bool hasInnerFigure(Figure f) = box():=f || ellipse() := f || circle():= f || ngon():=f;

void addState(Figure f) {
    Attr attr = attr(bigger = f.bigger);
    if (buttonInput(_):=f) 
         attr.disabled = f.disabled;
    Property property = property();
    if (choiceInput():=f)
         property.\value = f.\value;
    if (buttonInput(_):=f)
         property.\value = f.\value;
    if (rangeInput():=f)
         property.\value = f.\value;
    if (strInput():=f)
         property.\value = f.\value;
    if (checkboxInput():=f) 
         if (map[str, bool] s2b := f.\value)
         {
         property.\value = (x:(s2b[x]?)?s2b[x]:false|x<-f.choices);
         }
    Style style = style(fillColor=getFillColor(f)
       ,lineColor =getLineColor(f), lineWidth = getLineWidth(f),
       lineOpacity = getLineOpacity(f), fillOpacity= getFillOpacity(f),
       visibility = getVisibility(f));
    Text text = text();
    Timer timer = timer();
    Prop prop = <attr, style, property, text, timer >;
    seq=seq+1;
    state += <f.id, prop >;
    old+= prop;
    }
    
public void _setFigures(list[Figure] figs) {
    currentFigures = figs;
    reload = true;
    }
      
public void clearWidget() { 
    // println("clearWidget");
    currentFigs = [];
    widget = (); widgetOrder = [];adjust=[]; googleChart=[]; loadCalls = []; graphs= [];
    markerScript = [];
    defs=(); 
    dialog = ();
    parentMap=(); figMap = ();extraGraphData=();
    seq = 0; occur = 0;
    old =[];
    prompt  = <"", "">;
    alert = "";
    state = [];
    labval = [];
    initFigure();
    tooltips = [];
    panels = [];
    _display = true;
    screen = <-1, -1>;
    }
    
str visitFig(IFigure fig) {
       if (ifigure(str id, list[IFigure] f):= fig) {
          return "<widget[id].begintag> <for(d<-f){><visitFig(d)><}><widget[id].endtag>\n";
       }
    return "";
    }
    
              
str visitFig(list[IFigure] figs) {
    str r = "\<div id=\"figureArea\"\>";
    for (IFigure fig<-figs) {
       bool print = (figMap[fig.id]?)?figMap[fig.id].print:true;
       r+="\<div class=\"<print?"page":"button">\"\>";
       r+=visitFig(fig);
       r+="\</div\>";
       }
    r+="\</div\>";
    return r;
    }
 
str visitTooltipFigs() {
    if (isEmpty(panels) && isEmpty(tooltips)) return "";
    str r =
"\<div class=\"panel\"\>\<svg id = \"panel\" width=<0> height=<0> \>";
    for (IFigure fi<-panels) {
         if (g:ifigure(str id, _):=fi) {
            // r+= "\<foreignObject id=\"<id>_fox\" x=\"<getAtX(g)>\" y=\"<getAtY(g)>\" width=\"<upperBound>px\" height=\"<upperBound>px\"\>" ;
            r+= visitFig(g); 
            // r+= "\</foreignObject\>";     
            }
         }
    r+="\</svg\>\</div\>\n";
    r+=
"\<div class=\"tooltip\"\>\<svg id = \"tooltip\" width=<0> height=<0> \>";
    for (IFigure fi<-tooltips) {
         if (g:ifigure(str id, _):=fi) {
            r+= visitFig(g);        
            }
         }
    r+="\</svg\>\</div\>";
    return r;
    }  

    
str visitDefs(str id, bool marker) {
    if (defs[id]?) {
     for (f<-defs[id]) {
         // markerScript+= "alert(<getWidth(f)>);";
         markerScript+= "d3.select(\"#m_<f.id>\")
         ' <attr1("markerWidth", getWidth(f)+2)>
         ' <attr1("markerHeight", getHeight(f)+2)>
         ' ;
         "
         ;       
         }
     return "\n\<defs\>
           ' <for (f<-defs[id]){> <if(marker){> \<marker id=\"m_<f.id>\" 
           ' refX = <marker?getWidth(f)/2:0> refY = <marker?getHeight(f)/2:0> <marker?"orient=\"auto\"":"">
           ' \> 
           ' <}else{>  \<g id=\"g_<f.id>\"\><}> 
           ' <visitFig(f)>
           ' <if(marker){> \</marker\> <} else {>\</g\><}>
           ' <}>
           '\</defs\>\n
           ";
    }
    return "";
    }

str google = "\<script src=\'https://www.google.com/jsapi?autoload={
        ' \"modules\":[{
        ' \"name\":\"visualization\",
        ' \"version\":\"1\"
        ' }]
        '}\'\> \</script\>"
;     
       
str getIntro() {
   str res = "\<html\>
        '\<head\>      
        '\<style\>
        'body {
        '    font: 300 14px \'Helvetica Neue\', Helvetica;
        ' }
        'pre {
        '    text-align:left;
        ' }
        'text {
        '    fill:grey;
        ' }
        '.node rect {
        ' stroke: #333;
        ' fill: #fff;
       '}
       '.edgePath path {
       ' stroke: #333;
       ' fill: #333;
       ' stroke-width: 1.5px;
       '  }
       ' .page {break-after: page;}
       '.tooltip{
       'position: absolute;
       'top: 0;
        'left: 0;
        'width: 100%;
        'height: 100%;
        '// z-index: 10;
        '// background-color: rgba(0,0,0,0.5); /*dim the background*/
        'pointer-events:  none
        }
        '.panel{
       'position: absolute;
       'top: 0;
        'left: 0;
        'width: 100%;
        'height: 100%;
        '// z-index: 10;
        '// background-color: rgba(0,0,0,0.5); /*dim the background*/
        'pointer-events:  none
        }
        '#close {
          'visibility: hidden;
        }
        '\</style\>   
        '<if (!isEmpty(cssLocation)) {> \<link rel=\"stylesheet\" href= \"<cssLocation>\" type=\"text/css\"/\> <}>
        '\<script src=\"IFigure.js\"\>\</script\>
        '\<script src=\"Packer.js\"\>\</script\>
        '\<script src=\"pack.js\"\>\</script\>
        '\<script src=\"http://d3js.org/d3.v3.min.js\" charset=\"utf-8\"\>\</script\>        
        '\<script src=\"http://cpettitt.github.io/project/dagre-d3/latest/dagre-d3.min.js\"\>\</script\>
        '<google> 
        '\<script\>
        ' var screenWidth = 0;
        ' var screenHeight = 0;
        ' var upperBound = <upperBound>;  
        ' var lowerBound = <lowerBound>;  
        ' setSite(\"<getSiteStr()>\");    
        ' function initFunction() {
        '  alertSize();
        ' d3.select(\"#figureArea\")<style("width", screen.width)><style("height", screen.height)>;
        '  <for (d<-markerScript) {> <d> <}>
        '  <for (d<-widgetOrder) {> <widget[d].script> <}>
        '  <for (d<-reverse(adjust)) {> <d> <}>
        '  <for (int d<-[0..size(currentFigs)]) {> <_display?"doFunction(\"load\", \"figureArea<d>\")();":""><}>; 
        '  <for (d<-graphs) {> <d> <}>  
        '  <for (d<-panels) {> adjust_panel(\"<getParentFig(d.id).id>\",\"<d.id>\", <getAtX(d)>, <getAtY(d)>); <}> 
        '  <for (d<-tooltips) {> adjust_tooltip(\"<getParentFig(d.id).id>\",\"<d.id>\", <getAtX(d)>, <getAtY(d)>); <}> 
        '  <for (d<-googleChart) {> <d> <}>  
        '  // setTimeout(function(){<for (d<-loadCalls) {><_display?"doFunction(\"load\", \"<d>\")()":"\"\"">;<}> }, 1000); 
        ' <for (d<-loadCalls) {><_display?"doFunction(\"load\", \"<d>\")()":"\"\"">;<}>  
       ' }
       ' d3.selectAll(\"table\").remove();
       ' onload=initFunction;
       '\</script\>
       '\</head\>
       '\<body id=\"body\"\>
       '<visitFig(currentFigs)>
       '<visitTooltipFigs()>    
       '\</body\>     
		'\</html\>\n";
    // println(res);
	return replaceAll(res,"\n\n", "");
	}
	
Response page(get(/^\/static$/)) { 
	return response(getIntro());
}

Response page(get(/^\/dynamic$/)) { 
     _render(currentFigures, width = options.width,  height = options.height,  align = options.align
           ,fillColor = options.fillColor
           ,lineColor = options.lineColor, size = options.size, display = options.display
           ,borderWidth = options.borderWidth, borderStyle = options.borderStyle, resizable = options.resizable
           ,cssFile = options.cssFile, defined = options.defined, lineWidth = options.lineWidth, event = options.event
           ); 
	return response(getIntro());
}

bool eqProp(Prop p, Prop q) = p == q;
   
list[State] diffNewOld() {
    return [state[i]|i<-[0..size(state)], !eqProp(state[i].v, old[i])];
    }
    
bool isBigger(Figure f) {
   return getKeywordParameters(f)["bigger"]?;
   }
   
bool isRotate(Figure f) {
   return getKeywordParameters(f)["rotate"]?;
   }
   
bool isAlign(Figure f) {
   return getKeywordParameters(f)["align"]?;
   }
   
bool isCellAlign(Figure f) {
   return getKeywordParameters(f)["cellAlign"]?;
   }
   
bool isWidth(Figure f) {
   return getKeywordParameters(f)["width"]?;
   }
   
bool isHeight(Figure f) {
   return getKeywordParameters(f)["height"]?;
   }

bool isAlignment(Alignment align) = align!=<-1, -1>;

map[str, value] makeMap(Prop p) {
   map[str, value] attr = getKeywordParameters(p.attr);
   map[str, value] style = getKeywordParameters(p.style);
   map[str, value] property = getKeywordParameters(p.property);
   map[str, value] text = getKeywordParameters(p.text);  
   map[str, value] timer = getKeywordParameters(p.timer); 
   return ("attr":attr, "style":style,"property":property
          ,"text":text, "timer":timer);
   }
   
list[bool] toFlags(str v)  {
   list[bool] r = [];
   for (int i<-[0..size(v)]) {
       r += [(v[i]!="0")];
       }
   return r;
   }
   
void assign(str v) {  
   dialog[labval[0][0]]=<labval[0][1],v>;
   labval = tail(labval); 
   }
   
public void invokeF(str e, str n, str v) {
   value q = widget[n].f;
   switch (q) {
       case void(str, str, str) f: f(e, n, v);
       case void(str, str, int) f: f(e, n, toInt(v));
       case void(str, str, real) f: f(e, n, toReal(v));
       }
    }
    
Figure _getFigure(str n) = figMap[n];
 
void callCallback(str e, str n, str v) { 
   if (!figMap[n]?) return;
   // println("callback: <e> <n>  <v> <labval>");
   if (e=="prompt")  assign(v);
   if (isEmpty(labval)) {
     // println("Go on"); 
     v = replaceAll(v,"^plus","+");
     v = replaceAll(v,"^div","/");
     Figure f = figMap[n];
     // println("callCallBack <n> <f.id>");
     if (choiceInput():=f) { 
       Property a = _getProperty(n);
       a.\value= v;
       _setProperty(n, a);
       old[widget[n].seq].property = a;
       }
     if (checkboxInput():=f) { 
       Property a = _getProperty(n);
       value q = a.\value;
       if (map[str, bool] b := q) {
          int  d = toInt(v);
          if (d<0) b[f.choices[-d-1]] = false;
          else b[f.choices[d-1]] = true;
          a.\value = b;
         _setProperty(n, a);
          old[widget[n].seq].property = a;
          }
       }
     if (rangeInput():=f) { 
       Property a = _getProperty(n);
       a.\value = toReal(v);
       _setProperty(n, a);
       old[widget[n].seq].property = a;
       }
     if (strInput():=f) { 
       Property a = _getProperty(n);
       a.\value = v;
       _setProperty(n, a);
       old[widget[n].seq].property = a;
       } 
      invokeF(e, n, v);
     }
    if (!isEmpty(labval)) {   
       _setPrompt(<labval[0][1], labval[0][2]>); 
       return; 
       } 
   }
   
Response page(req:post(/^\/getValue\/<ev:[a-zA-Z0-9_]+>\/<name:[a-zA-Z0-9_]+>\/<v:.*>/, Body _)) {
	// println("post: getValue: <name>, <parameters>");
	// widget[name].f(ev, name, v);  // !!! The callback will be called
	// println(parameters);
	//  str lab = name;
	for (str id<-req.parameters) {
	     callCallback(ev, id, req.parameters[id]);
	     }
	callCallback(ev, name, v);
	list[State] changed = diffNewOld();
	// println(old);
	map[str, Prop] changedMap1 = toMapUnique(changed);	
	map[str, map[str, value]] changedMap = (s:makeMap(changedMap1[s])|s<-changedMap1);
	if (!isEmpty(alert)) {
      if (changedMap[name]?)
	    changedMap[name]["alert"]=alert;
	  else
	    changedMap[name] = ("alert":alert);
	  alert = "";
	  }
	str g = prompt[0]=="undefined"?"":prompt[0];
	if (changedMap[name]?)
	    changedMap[name]["prompt"]=g;
	else
	    changedMap[name] = ("prompt":g);
	 if (reload) {
	     if (changedMap[name]?)
	          changedMap[name]["reload"]="reload";
	     else
	       changedMap[name] = ("reload":"reload");
	       reload = false;
	     }
	old = [s.v|s<-state];
	prompt = <"", "">; 
	//return response("<res>"); 
	return jsonResponse(ok(), (), changedMap);
}

default Response page(get(str path)) {
   // println("File response: <base+path>");
   return response(base + path); 
   }

private loc startFigureServer() {
  	loc site = |http://localhost:8081|; 
   while (true) {
    try {
      //println("Trying ... <site>");
      //serve(site, dispatchserver(page));
      serve(site, page);
      return site;
    }  
    catch IO(_): {
      site.port += 1; 
    }
  }
}

private loc site = startFigureServer();

private str getSiteStr() = "<site>"[1 .. -1];

public loc getSite() = site;

value getRenderCallback(Event event) {return void(str e, str n, str v) {
    value q = getCallback(event);
    switch (q) {
       case void(str, str, str) f: f(e, n, v);
       case void(str, str, int) f: f(e, n, toInt(v));
       case void(str, str, real) f: f(e, n, toReal(v));
       }
     }; 
 }
 
str extraQuote(str s) = "\"<s>\"";
  
IFigure  _d3Pack(str id, Figure f, str json) {
     str begintag= beginTag(id, f.align);
     str endtag = endTag();
     int width = f.width<0?1200:f.width;
     int height = f.height<0?800:f.height;
     str lineColor = isEmpty(f.lineColor)?f.fillNode:f.lineColor;
     // println(f.diameter);
     widget[id] = <null, seq, id, begintag, endtag,
     "
     'd3.select(\"#<id>\").attr(\"w\", <width>).attr(\"h\", <height>);
     'packDraw(\"<id>_td\", <json>, <extraQuote(f.fillNode)>, <extraQuote(f.fillLeaf)>, <f.fillOpacityNode>, <f.fillOpacityLeaf>,
     <extraQuote(lineColor)>, <f.lineWidth<0?1:f.lineWidth>, <f.diameter>, <f.inTooltip>);
     ",  f.width, f.height, 0, 0, 1, 1, f.align, f.cellAlign,  1, "", false, false >;
     widgetOrder+= id;  
     return ifigure("<id>", []);
     }
     
IFigure  _d3Treemap(str id, Figure f, str json) {
     str begintag= beginTag(id, f.align);
     str endtag = endTag();
     int width = f.width<0?1200:f.width;
     int height = f.height<0?800:f.height;
     widget[id] = <null, seq, id, begintag, endtag,
     "
     'd3.select(\"#<id>\").attr(\"w\", <width>).attr(\"h\", <height>);
     'treemapDraw(\"<id>_td\", <json>, <width>, <height>, \"<f.fillColor>\", <f.inTooltip>);
     ",  f.width, f.height, 0, 0, 1, 1, f.align, f.cellAlign,  1, "", false, false >;
     widgetOrder+= id;  
     return ifigure("<id>", []);
     }
     
str tids(list[str]  ids) {
    str r = "[";
    list[str] qs = ["\"<q>\""|q<-ids];
    r+= intercalate(",", qs);
    r+="]";
    return r;
    }
     
IFigure  _d3Tree(str id, Figure f, list[str] ids, list[IFigure] fig1, str json) {
     str begintag= "\<svg id= \"<id>_svg\" \> \<g  id=\"<id>\"\>
     <for(x<-tail(fig1)){>\<path/\>\n<}>
     ";
     str endtag = "\</g\>\</svg\>";
     int width = f.width<0?1200:f.width;
     int height = f.height<0?800:f.height;
     int lineWidth = f.lineWidth<0?1:f.lineWidth;
     num fillOpacity = f.fillOpacity<0?1.0:f.fillOpacity;
     // println(tids(ids));
     widget[id] = <null, seq, id, begintag, endtag,
     "
     'treeDraw(\"<id>\", <tids(ids)>, <json>, <width>, <height>, \"<f.fillColor>\", <fillOpacity>, 
         \"<f.lineColor>\", <lineWidth>);
     'd3.select(\"#<id>_svg\").attr(\"width\", <width>).attr(\"height\", <height>);
     ",  width, height, 0, 0, 1, 1, f.align, f.cellAlign,  1, "", false, false >;
     widgetOrder+= id;  
     addState(f);
     return ifigure("<id>", fig1);
     }


public void _render(str id, IFigure fig1, int width = 800, int height = 800, 
     Alignment align = centerMid, int borderWidth = -1, str borderStyle="", str borderColor = "",
     str fillColor = "none", str lineColor = "black", bool display = true, Event event = noEvent(),
     bool resizable = true, bool defined = false, str cssFile= "")
     {
     _display = display;
    str begintag= beginTag(id, getAlign(fig1));
    str endtag = endTag(); 
    widget[id] = <(display?getRenderCallback(event):null), seq, id, begintag, endtag, 
        "
        'd3.select(\"#<id>\")       
        '<style("border","0px solid black")> 
        '<style("border-width",borderWidth)>
        '<style("border-style",borderStyle)>
        '<style("border-color",borderColor)>
        '<style("background", fillColor)>
        ; 
        'adjustTableFromCells(\"<id>\", <figCalls([fig1])>);       
        "
       , width, height, 0, 0, 1, 1, align,  align , 1, "", false, false >;
      
       widgetOrder += id;
    adjust+=  "adjustHcatCells("+figCalls([fig1])+", \"<id>\", 0,  0, 0, 0, 0);\n";
    currentFigs += [ifigure(id, [fig1])];
    // println("site=<site>");
    cssLocation = cssFile;
}

str getId(IFigure f) {
    if (ifigure(id, _) := f) return id;
    return "emptyFigure";
    }

str getSeq(IFigure f) {
    if (ifigure(id, _) := f) return id;
    if (iemptyFigure(int seq):=f) return {"emptyFigure_<seq>";}
    return "emptyFigure";
    }    
    
    
void setX(IFigure f, int x) {
    if (ifigure(id, _) := f)  widget[id].x = x;
    }
    
void setY(IFigure f, int y) {
    if (ifigure(id, _) := f) widget[id].y  =y;
    }
    

int getWidth(IFigure f) {
    if (ifigure(id, _) := f) return widget[id].width;
    return -1;
    }
    
int getHeight(IFigure f) {
    if (ifigure(id, _) := f) return widget[id].height;
    return -1;
    }

int getLineWidth(IFigure f) {
    if (ifigure(id, _) := f) return widget[id].lineWidth;
    return -1;
    }
    
int getLineWidth(Figure f) {
    int lw = f.lineWidth;
    while (lw<0) {
        // println(f);
        if (!(parentMap[f.id]?)) return 1;
        f = figMap[parentMap[f.id]];      
        lw = f.lineWidth;
        }
   return lw;
  }
  
str getLineColor(Figure f) {
    str c = f.lineColor;
    while (isEmpty(c)) {
        if (!(parentMap[f.id]?)) return "";
        f = figMap[parentMap[f.id]];
        c = f.lineColor;
        }
   return c;
  }
  
bool getResizable(Figure f) {
    bool c = f.resizable;
    while (c && parentMap[f.id]?) {
       f = figMap[parentMap[f.id]];
       c  = f.resizable;
       }
     return c;
  }

str getFillColor(Figure f) {
    str c = f.fillColor;
    while (isEmpty(c)) {
        if (!parentMap[f.id]?) return "";
        f = figMap[parentMap[f.id]];
        c = f.fillColor;
        }
   value v = f.tooltip;
   if (c=="none" && (Figure x := v || (str q := v) && !isEmpty(q))) c = "white";
   if (c=="none" && noEvent()!:=f.event) c = "white";
   return c;
  } 
   
num getFillOpacity(Figure f) {
    num c = f.fillOpacity;
    while (c<0) {
        if (!(parentMap[f.id]?)) return 1.0;
        f = figMap[parentMap[f.id]];
        c = f.fillOpacity;
        }
   return c;
  }
  
num getLineOpacity(Figure f) {
    num c = f.lineOpacity;
    while (c<0) {
        if (!(parentMap[f.id]?)) return 1.0;
        f = figMap[parentMap[f.id]];
        c = f.lineOpacity;
        }
   return c;
  }
  
str getVisibility(Figure f) {
   str c = f.visibility;
   return c;
  }
  
 str getDeepVisibility(Figure f) {
    str c = f.visibility;
    while (isEmpty(c)) {
        if (!(parentMap[f.id]?)) return "inherit";
        f = figMap[parentMap[f.id]];
        c = f.visibility;
        }
   println("Value visib <c>");
   return c;
  }
    
bool getSizeFromParent(IFigure f) {
    if (ifigure(id, _) := f) return widget[id].sizeFromParent;
    return false;
    }

int getX(IFigure f) {
    if (ifigure(id, _) := f) return widget[id].x;
    return -1;
    }
    
int getY(IFigure f) {
    if (ifigure(id, _) := f) return widget[id].y;
    return -1;
    }
    
    
Alignment getAlign(IFigure f) {
    if (ifigure(id, _) := f) return widget[id].align;
    return <-1, -1>;
    } 

Alignment getCellAlign(IFigure f) {
    if (ifigure(id, _) := f) return widget[id].cellAlign;
    return <-1, -1>;
    } 
      
value getCallback(Event e) {
   //  println("getCallbak <e>");
    if (on(void(str, str, str) callback):=e) return callback;
    if (on(void(str, str, int) callback):=e) return callback;
    if (on(void(str, str, real) callback):=e) return callback;
    if (on(str _, StrCallBack callback):=e) return callback;
    if (on(str _, IntCallBack callback):=e) return callback;
    if (on(str _, RealCallBack callback):=e) return callback;
    if (on(list[str] _, StrCallBack callback):=e) return callback;
    if (on(list[str] _, IntCallBack callback):=e) return callback;
    if (on(list[str] _, RealCallBack callback):=e) return callback;  
    return null; 
    }
    
     
str getEvent(Event e) {
    if (on(str eventName, StrCallBack _):=e) return eventName;
    if (on(str eventName, IntCallBack _):=e) return eventName;
    if (on(str eventName, RealCallBack _):=e) return eventName;
    return "";
    }
    
list[str] getEvents(Event e) {
    if (on(list[str] eventName, StrCallBack _):=e) return eventName;
    if (on(list[str] eventName, IntCallBack _):=e) return eventName;
    if (on(list[str] eventName, RealCallBack _):=e) return eventName;
    return [];
    }   
str debugStyle() {
    if (debug) return style("border","1px solid black");
    return "";
    }

str borderStyleF(Figure f) {
      str r = 
      "<style("border-width",f.borderWidth)> 
      '<style("border-style",f.borderStyle)>
      '<style("border-color",f.borderColor)>";
      return r;
     }
    
str style(str key, str v) {
    if (isEmpty(v)) return "";
    return ".style(\"<key>\",\"<v>\")";
    }
    
str style1(str key, str v) {
    if (isEmpty(v)) return "";
    return ".style(\"<key>\",<v>)";
    }    
    
str style(str key, num v) {
    if (v<0) return "";
    return ".style(\"<key>\",\"<v>\")";
    }

str stylePx(str key, int v) {
    if (v<0) return "";
    return ".style(\"<key>\",\"<v>px\")";
    }
    
str attrPx(str key, int v) {
    if (v<0) return "";
    return ".attr(\"<key>\",\"<v>px\")";
    }
    
str attr1Px(str key, int v) {
    return ".attr(\"<key>\",\"<v>px\")";
    }   
       
str attr(str key, str v) {
    if (isEmpty(v)) return "";
    return ".attr(\"<key>\",\"<v>\")";
    }

str attr1(str key, str v) {
    if (isEmpty(v)) return "";
    return ".attr(\"<key>\",<v>)";
    }    

str attr(str key, int v) {
    if (v<0) return "";
    return ".attr(\"<key>\",\"<v>\")";
    }
    
str attr1(str key, int v) {
    if (v<0) return "";
    return ".attr(\"<key>\",<v>)";
    }
    
str attr(str key, real v) {
    if (v<0) return "";
    return ".attr(\"<key>\",\"<precision(v, 1)>\")";
    }
    
str text(str v, bool html) {
    if (isEmpty(v)) return "";
    s = replaceAll(v,"\\", "\\\\");
    s = replaceAll(s,"\n", "\\\n");
    s = "\"<replaceAll(s,"\"", "\\\"")>\""; 
    if (html) {
        return ".html(<s>)";
        }
    else 
        return ".text(<s>)";
    }
    
str on(Figure f) {
    if (!_display) return "";
    list[str] events = getEvents(f.event) + getEvent(f.event);
    // println("HELP: <events>");
    if (indexOf(events, "load")>=0) loadCalls+=f.id;
    return 
    "<for(str e<- events){><on(e, "doFunction(\"<e>\", \"<f.id>\")")><}>";
   }
   
        
str on(str ev, str proc) {
    if (!_display||isEmpty(ev)|| ev=="load") return "";
    return ".on(\"<ev>\", <proc>)";
    }
         
// -----------------------------------------------------------------------
int getTextWidth(Figure f, str s) {
     if (f.width>=0) return f.width;
     int fw =  f.fontSize<0?12:f.fontSize;
     return toInt(size(s)*fw);
     }
 
int getTextHeight(Figure f) {
   if (f.height>=0) return f.height;
   num fw =  (f.fontSize<0?12:f.fontSize)*1.2;
   return toInt(fw);
   }
   
int getTextX(Figure f, str s) {
     int fw =  (f.fontSize<0?12:f.fontSize);
     if (f.width>=0) {    
         return (f.width-size(s)*fw)/2;
         }
     return fw/2;
     }

int getTextY(Figure f) {
     int fw =  (f.fontSize<0?12:f.fontSize);
     fw += fw/2;
     if (f.height>=0) {
          return f.height/2+fw;  
          }  
     return fw;
     }  
          
IFigure _text(str id, bool inHtml, Figure f, str s, str overflow, bool addSvgTag) {
    bool isHtml = (text(_):=f && inHtml) || htmlText(_):=f;
    str begintag = "";
    bool tagSet = false;
    if (!isHtml || inHtml && addSvgTag) {
          begintag+=
         "\<svg id=\"<id>_svg\"\>";
         tagSet = true;   
         inHtml = false;   
         }
    if (!inHtml && isHtml) begintag+="\<foreignObject id=\"<id>_fo\" x=0 y=0 width=\"<upperBound>px\" height=\"<upperBound>px\"\>"; 
    begintag+=isHtml?"\<div  id=\"<id>\"\>":"\<text id=\"<id>\"\>";
    int width = f.width;
    int height = f.height;
    str endtag = isHtml?"\</div\>":"\</text\>";
    if (!inHtml && isHtml) endtag += "\</foreignObject\>";
    if (tagSet) {
         endtag+="\</svg\>"; 
         }
    f.lineWidth = 0;
    widget[id] = <null, seq, id, begintag, endtag, 
        "
        'd3.select(\"#<id>\")
        '<debugStyle()>
        '<stylePx("width", width)><stylePx("height", height)>
        '<attrPx("width", width)><attrPx("height", height)>
        '<stylePx("font-size", f.fontSize)>
        '<style("font-style", f.fontStyle)>
        '<style("font-family", f.fontFamily)>
        '<style("font-weight", f.fontWeight)>
        '<style("text-decoration", f.textDecoration)>
        '// <style("visibility", getVisibility(f))>
        '<isHtml?style("color", f.fontColor):(style("fill", f.fontColor))>
        '<if (!isHtml){> 
        '<style("stroke",f.fontLineColor)>
        '<style("stroke-width", f.fontLineWidth)>
        ' <}>
        '<isHtml?"":style("text-anchor", "middle")> 
        '<isHtml?style("overflow", overflow):"">
        '<isHtml?style("pointer-events", overflow=="hidden"?"none":"auto"):attr("pointer-events", "none")>
        '<text(s, isHtml)>
        ';
        'd3.select(\"#<id>_svg\")
        '<isHtml?"":attr("pointer-events", "none")>
        '<attr("width", f.width)><attr("height", f.height)>
        ';
        'd3.select(\"#<id>_fo\")
        '<attr("width", width)><attr("height", height)>
        '<attr("pointer-events", "none")> 
        '<debugStyle()>
        '; 
        'adjustText(\"<id>\");  
        "
        , width, height, getAtX(f), getAtY(f), f.hshrink, f.vshrink, f.align, f.cellAlign,  getLineWidth(f), getLineColor(f), f.sizeFromParent, true >;
       addState(f);
       widgetOrder+= id;
       return ifigure(id, []);
    }
    
str trChart(str cmd, str id, Figure chart) {
    map[str,value] kw = getKeywordParameters(chart);
    ChartOptions options = chart.options;
    str d = ""; 
    if ((kw["charts"]?) && !isEmpty(chart.charts)) {
      list[Chart] charts = chart.charts;
      d = 
      toJSON(joinData(charts, chart.tickLabels, chart.tooltipColumn), true);
      options = updateOptions(charts, options);
      }
    if ((kw["googleData"]?) && !isEmpty(chart.googleData)) 
       d = toJSON(chart.googleData, true);
    if ((kw["xyData"]?) && !isEmpty(chart.xyData)) {     
       d = toJSON([["x", "y"]] + [[e[0], e[1]]|e<-chart.xyData], true);
       }  
    if (options.width>=0) chart.width = options.width;
    if (options.height>=0) chart.height = options.height;
    return 
    "{
     '\"chartType\": \"<cmd>\",
     '\"containerId\":\"<id>\",
    ' \"options\": <adt2json(options)>,
    ' \"dataTable\": <d>  
    '}";   
    }
    
str drawVisualization(str fname, str json) { 
    return "
    'function <fname>() {
    'var wrap = new google.visualization.ChartWrapper(
    '<json>
    ');
    'wrap.draw();
    '}
    ";  
    }
    
value vl(value v) {
    if (str s:=v) return "\"<toLowerCase(s)>\"";
    if (int d:=v) return d;
    return "";
    }
    
IFigure _googlechart(str cmd, str id, Figure f, bool addSvgTag) {
    str begintag = "";
    ChartOptions options = f.options;
    int width = f.width<0?options.width:f.width;
    int height = f.height<0?options.height:f.height; 
    if (true || addSvgTag) {
          begintag+=
         "\<svg id=\"<id>_svg\" width=\"<width>px\" height=\"<height>px\"\> \<foreignObject id=\"<id>_outer_fo\"  x=0 y=0 width=\"<width>px\" height=\"<height>px\"\>";
         }
    begintag+="\<div id=\"<id>\" class=\"google\" \>";
    Alignment align =  f.width<0?topLeft:f.align;
    str endtag = "\</div\>"; 
    if (true || addSvgTag) {
         endtag += "\</foreignObject\>\</svg\>"; 
         }
    str fname = "googleChart_<id>";
    googleChart+="<fname>();\n";
    widget[id] = <null, seq, id, begintag, endtag, 
        "
        'd3.select(\"#<id>_outer_fo\")<attr("pointer-events", "all")>;
        'd3.select(\"#<id>\")
        '<debugStyle()>
        '<style("background-color", "<getFillColor(f)>")>
        '<stylePx("width", width)><stylePx("height", height)>
        ';
        '<drawVisualization(fname, trChart(cmd, id, f))>
        ';    
        "      
        , width, height, getAtX(f), getAtY(f), f.hshrink, f.vshrink, align, align, getLineWidth(f), getLineColor(f), f.sizeFromParent, false >;
       addState(f);
       widgetOrder+= id;
       return ifigure(id, []);
    }
    
 str getNodePropertyOpt(Figure f, str s, Figure g) {
    str r =  (emptyFigure():=g)?",{":",{shape:\"<g.id>\",label:\"\"";
    if ((f.nodeProperty[s]?)) {
        map[str, value] m = getKeywordParameters(f.nodeProperty[s]);
        for (t<-m) {
           r+=",<t>:<vl(m[t])>,";
           }       
        }
    r+="}";
    return r;
    }
    
str getGraphOpt(Figure g) {
   map[str, value] m = getKeywordParameters(g.graphOptions);
   str r =  "{style:\"fill:none\", ";
   if (!isEmpty(m)) {
        for (t<-m) {
           r+="<t>:<vl(m[t])>,";
           }    
        r = replaceLast(r,",","");                
        }
     r+="}";
    return r;
    }
    
str getEdgeOpt(Edge s) {
      map[str, value] m = getKeywordParameters(s);
      str r =  ",{";
      if (s.lineInterpolate=="basis") {
          r+="lineInterpolate:\"basis\",";
          }
      if (!isEmpty(m))  {  
         for (t<-m) 
           if (!(t=="lineColor"||t=="lineWidth"||t=="lineDashing"))
           {    
           if (t=="label" && str q:=m[t])  {r+="<t>:\"<q>\",";continue;}
           r+="<t>:<vl(m[t])>,";       
           }
         for (t<-m) 
           if (t=="lineColor"||t=="lineWidth"||t=="lineDashing")  {r+="style:\"fill:none"; break;}
         for (t<-m) 
           if (t=="lineColor"||t=="lineWidth"||t=="lineDashing") {
               if (t=="lineColor")  {r+=";stroke:<m[t]>";continue;}
               if (t=="lineWidth")  {r+=";stroke-width:<m[t]>";continue;}
               if (t=="lineDashing"){
                   if (list[int] q := m[t])
                      {r+=";stroke-dasharray: <lineDashing(q)>";continue;}
                   }
           }  
         for (t<-m) 
           if (t=="lineColor"||t=="lineWidth"||t=="lineDashing")  {r+="\","; break;}  
         r = replaceLast(r,",","");
         } 
         r+="}";      
    return r;
    }
    
 str trGraph(Figure g) {
    str r = "var g = new dagreD3.graphlib.Graph().setGraph(<getGraphOpt(g)>);";
    r +="
     '<for(s<-g.nodes){> g.setNode(\"<s[0]>\"<getNodePropertyOpt(g, s[0], s[1])>);<}>
     ";
    r+="
     '<for(s:edge(from, to)<-g.edges)
     {>g.setEdge(\"<from>\", \"<to>\"<getEdgeOpt(s)>);<}>
     ";
    r+="
    '<for(s<-g.nodes){> <emptyFigure():=s[1]?"":addShape(s[1])> <}>
    ";
    return r;
    }
    
str dagreIntersect(Figure s) {
    return "return dagreD3.intersect.polygon(node, points, point);";    
    }
    
str dagrePoints(Figure f) {
      str r = "function () {";
      if (ngon():=f) {        
          if (f.size != <0, 0>) {
            if (f.width<0) f.width = f.size[0];
            if (f.height<0) f.height = f.size[1];
            }
          if (f.r<0 && f.height>0 &&f.width>0) {
          int d = min([f.height, f.width]);
          f.r = (d)/2;
          }
          num angle = 2 * PI() / f.n;
          lrel[num, num] p  = [<f.r+f.r*cos(i*angle), f.r+f.r*sin(i*angle)>|int i<-[0..f.n]];  
          r+= "return <replaceLast( "[<for(z<-p){> {x:<toInt(z[0])>, y: <toInt(z[1])>},<}>]", ",", "")>";
          } else
       if (q:ellipse():=f) {
          r += "var rx = width/2; var ry = height/2; var n = 32; var angle= 2*Math.PI/n; var r=[];\n";
          r += "for (var i=0;i\<n; i++) {r.push({x:rx+rx*Math.cos(i*angle), y:ry+ry*Math.sin(i*angle)});}\n";
          r += "return r";
          } else 
       if (q:circle():=f) {
          r += "var R = width/2;  var n = 32; var angle= 2*Math.PI/n; var r=[];\n";
          r += "for (var i=0;i\<n; i++) {r.push({x:R+R*Math.cos(i*angle), y:R+R*Math.sin(i*angle)});}\n";
          r += "return r";
          } else 
       r +="return [{x:0, y:0}, {x:width, y:0}, {x:width, y:height}, {x:0, y:height}]";
       r+= ";}\n";
       return r;
       }
       
str addShape(Figure s) {  
    return "
    'render.shapes().<s.id> = function (parent, bbox, node) {
    'var width = d3.select(\"#<s.id>\").attr(\"width\");
    'var height = d3.select(\"#<s.id>\").attr(\"height\");
    'if (invalid(width))  width = d3.select(\"#<s.id>\").style(\"width\");
    'if (invalid(height)) height = d3.select(\"#<s.id>\").style(\"height\");
    'if (invalid(width))  width = d3.select(\"#<s.id>_svg\").attr(\"width\");
    'if (invalid(height)) height = d3.select(\"#<s.id>_svg\").attr(\"height\");
    'width = parseInt(width);
    'height= parseInt(height);
    'var points = <dagrePoints(s)>();
    'var dpoints = \"M \"+ points.map(function(d) { return d.x + \" \" + d.y; }).join(\" \")+\" Z\";
    'shapeSvg = parent.insert(\"path\", \":first-child\")
    ' <attr1("d", "dpoints")> 
    ' <style("fill", "none")><style("stroke", "none")>
    ' <attr1("transform", "\"translate(\"+-width/2+\",\"+-height/2+\")\"")>
    '  
    '    node.intersect = function(point) {
    '    <dagreIntersect(s)>
    '    }
    '    return shapeSvg;
    '    }  
    ";
    }
   
 str drawGraph(str fname, str id, str body, int width, int height) {
    return "
    'function <fname>() {   
    'var render = new dagreD3.render();
    'var svg = d3.select(\"#<id>\");
    'var inner = svg.append(\"g\");
    '<body>
    'render(inner, g);
    ' var offset = Math.ceil((<width>-g.graph().width)/2);
    ' svg.attr(\"width\", <width>).attr(\"height\", <height>);
    ' inner.attr(\"transform\", \"translate(\" + offset + \", 0)\");
    ' g.nodes().forEach(function(v) {
    '     var n = g.node(v);
    '     var id = n.shape;
    '     var z = d3.select(\"#\"+id);
    '     var width = z.attr(\"width\");
    '     var height =z.attr(\"height\");
    '     if (invalid(width)) width = z.style(\"width\");
    '     if (invalid(height)) height = z.style(\"height\");
    '     if (invalid(width))  width =  d3.select(\"#\"+id+\"_svg\").attr(\"width\");
    '     if (invalid(height)) height = d3.select(\"#\"+id+\"_svg\").attr(\"height\");
    '     width = parseInt(width);
    '     height= parseInt(height)+1;
    '     d3.select(\"#\"+id+\"_svg\")<attr1("x", "Math.floor(n.x-width/2+offset)")><attr1("y", "Math.floor(n.y-height/2)+1")>;
    '     });
    ' console.log(g.graph().width);
    '}   
    "; 
    }
      
    
 IFigure _graph(str id, Figure f) {
    int width = f.width;
    int height = f.height;
    str begintag =
         "\<svg id=\"<id>_svg\"\>\<g id=\"<id>\"\>";
    str endtag="\</g\>\</svg\>";   
    Alignment align =  width<0?topLeft:f.align; 
    str fname = "graph_<id>";
    graphs+="<fname>();\n";
    widget[id] = <null, seq, id, begintag, endtag, 
        "        
        '<drawGraph(fname, id, trGraph(f), width, height)>
        'd3.select(\"#<id>\")
        '<on(f)>
        ';
        'd3.select(\"#<id>_svg\")
        '<attrPx("width", width)><attrPx("height", height)>
        '; 
        "
        , width, height, 0, 0, f.vshrink, f.hshrink, align, align, getLineWidth(f), getLineColor(f), f.sizeFromParent, true >;
       addState(f);
       widgetOrder+= id;
       return ifigure(id, []);
    }
    
str beginTag(str id, Alignment align) {
    return "\<table  cellspacing=\"0\" cellpadding=\"0\" id=\"<id>\"\>\<tr\>
           '\<td <vAlign(align)> <hAlign(align)> id=\"<id>_td\"\>";
    }
  
str beginTag(str id, bool foreignObject, IFigure fig, Alignment align, int offset) {  
   str r =  foreignObject?
"\<foreignObject id=\"<id>_fo\" x=\"<getAtX(fig)+offset>\" y=\"<getAtY(fig)+offset>\" width=\"<upperBound>px\" height=\"<upperBound>px\"\>    
'<beginTag("<id>_fo_table", align)>
"       
    :"";
    return r;
 }
 
str beginTag(str id, bool foreignObject, IFigure fig, Alignment align)
 = beginTag(id, foreignObject, fig, align, 0);
 
str endTag(bool foreignObject) {
   str r = foreignObject?"<endTag()>\</foreignObject\>":"";
   return r;
   }
    
str endTag() {
   return "\</td\>\</tr\>\</table\>"; 
   } 
         
int getAtX(Figure f) {
         return toInt(f.at[0]);
         }
         
int getAtY(Figure f) {
         return toInt(f.at[1]);
         }
          
int getAtX(IFigure f) {  
    if (ifigure(id, _) := f) {
      return widget[id].x;
      }
    return 0;
    }
    
int getAtY(IFigure f) {
    if (ifigure(id, _) := f) return widget[id].y;
    return 0;
    } 

num getHshrink(IFigure f) {
    if (ifigure(id, _) := f) return widget[id].hshrink;
    return 0;
    }
    
num getVshrink(IFigure f) {
    if (ifigure(id, _) := f) return widget[id].vshrink;
    return 0;
    }  
   
str beginRotate(Figure f) {
    // println("beginRotate: <isRotate(f)>");
    if (!isRotate(f)) return "";
    if (f.rotate[1]<0 && f.rotate[2]<0) {  
        if (f.width<0  || f.height<0) return "\<g\>";
        f.rotate[1] = (f.width)/2;
        f.rotate[2] = (f.height)/2;
        // println("cx: <f.rotate[1]>  cy: <f.rotate[2]>");    
        }
        return "\<g transform=\" rotate(<f.rotate[0]>,<f.rotate[1]>,<f.rotate[2]>)\" \>";
    }
  
str endRotate(Figure f) {
// println("endRotate: <isRotate(f)>"); 
return !isRotate(f)? "":"\</g\>";
}

str beginScale(Figure f) {   
    if (!isBigger(f)) return "";
    if (f.width<0 || f.height<0)
       return "\<g id = \"<f.id>_g\" transform=\"scale(<f.bigger>)\" \>";
    else {
        int x =0;  
        int y =0;
        return "\<g id = \"<f.id>_g\" transform=\"translate(<-x>, <-y>) scale(<f.bigger>) translate(<x>, <y>)\"\>";
        }
    }
  
str endScale(Figure f) =  isBigger(f)?"\</g\>":"";
    
int hPadding(Figure f) = f.padding[0]+f.padding[2];     

int vPadding(Figure f) = f.padding[1]+f.padding[3]; 

bool hasInnerCircle(Figure f)  {
     if (!((box():=f) || (ellipse():=f) || (circle():=f) || (ngon():=f))) return false;
     f =  f.fig;
     while (atXY(_, _, Figure g):= f|| atXY(_,  Figure g):= f || atX(_,Figure g):=f || atY(_,Figure g):=f) {
          f = g;
          }
     return (circle():=f) || (ellipse():=f) || (ngon():=f);
     }
  
 str moveAt(bool fo, Figure f) = fo?"":"x=<getAtX(f)> y=<getAtY(f)>";
 
 str fromOuterToInner(IFigure fig, str id, int n, num angle, int x, int y) =  
   "fromOuterToInner(\"<getId(fig)>\", \"<id>\", <getHshrink(fig)>, <getVshrink(fig)>
   ', <getLineWidth(fig)>, <n>, <angle>, <x>, <y>);\n";
   
 str fromOuterToInner(IFigure fig, str id) = fromOuterToInner(fig, id, 0, 0, 0, 0);
         
 IFigure _rect(str id, bool fo, Figure f,  IFigure fig = iemptyFigure(0)) {   
      int lw = getLineWidth(f);  
      if (emptyFigure():=f.fig) fo = false;
      Alignment align = f.align;
      str begintag= 
         "
         '\<svg  xmlns = \'http://www.w3.org/2000/svg\'  id=\"<id>_svg\" \> <clipPath("clip_<id>", f.clipPath)> <beginScale(f)> <beginRotate(f)>
         '\<rect id=\"<id>\" /\> 
         '<beginTag("<id>", fo, fig, align, lw)>
         "; 
       str endtag =endTag(fo);
       endtag += endRotate(f);  
       endtag+=endScale(f);
       endtag += "\</svg\>"; 
       int width = f.width;
       int height = f.height; 
       Elm elm = <getCallback(f.event), seq, id, begintag, endtag, 
        "
        'd3.select(\"#<id>\")
        '<on(f)>
        '<attr("x", lw/2)><attr("y", lw/2)> 
        '<attr("rx", f.rounded[0])><attr("ry", f.rounded[1])> 
        '<attr("width", width)><attr("height", height)>
        '<if (!isEmpty(f.clipPath)) {><style("clip-path", "url(#clip_<id>)")><}>
        '<styleInsideSvg(id, f, fig)>
        ",toInt(f.bigger*f.width), toInt(f.bigger*f.height), getAtX(f), getAtY(f), f.hshrink, f.vshrink, f.align, f.cellAlign, 
          toInt(f.bigger*getLineWidth(f)), getLineColor(f), f.sizeFromParent, true>;
       widget[id]  =elm;
       addState(f);
       widgetOrder+= id;  
       if ((iemptyFigure(_)!:=fig) && getResizable(f) && (getWidth(fig)<0 || getHeight(fig)<0)
       )
       adjust+= fromOuterToInner(fig, id, getN(fig), getAngle(fig), getAtX(fig), getAtY(fig));  
       return ifigure(id, [fig]);
       } 
       
 bool isEmptyTooltip(value f) {
     return (str s:=f && isEmpty(s));
     }
 
 str styleInsideSvgOverlay(str id, Figure f) {
      str tooltip = "";
      if (str s := f.tooltip) {
            if (!isEmpty(s)) 
                 tooltip = ".append(\"svg:title\").text(\""+
                 replaceAll(replaceAll(s,"\n", "\\n"),"\"","\\\"") +"\")";
            }  
      int lw =  getLineWidth(f);
      int width = f.width;
      int height = f.height;
      if (width>=0) width = toInt(f.bigger*(width + lw));
      if (height>=0) height = toInt(f.bigger*(height + lw));
      return " 
        '<if(path(_,_,_,_,_)!:=f){><style("stroke-width",lw)><}>
        '<style("stroke","<getLineColor(f)>")>
        '<style("fill", "<getFillColor(f)>")> 
        '<style("stroke-dasharray", lineDashing(f.lineDashing))> 
        '<style("fill-opacity", getFillOpacity(f))> 
        '<style("stroke-opacity", getLineOpacity(f))>  
        '<style("visibility", getVisibility(f))> 
        '<attr("clickable", isPassive(f)?"no":"yes")>
        '<isPassive(f)||getVisibility(f)=="hidden"?attr("pointer-events", "none"):attr("pointer-events", "auto")>  
        '<tooltip> 
        ';   
        'd3.select(\"#<id>_svg\")
        '<attr("width", width)><attr("height", height)>
        '<attr("pointer-events", "none")>                
        ';
        ";
      } 
      
 str lineDashing(list[int] ld) {
      if (isEmpty(ld)) return "";
      str r = "<head(ld)> <for(d<-tail(ld)){> , <d> <}>";
      return r;
      }
      
 bool hasForm(Figure f) {
      if (q:grid():=f.fig && q.form) return true;
      if (q:hcat():=f.fig && q.form) return true;
      if (q:vcat():=f.fig && q.form) return true;
      return false;
      }
 
 str styleInsideSvg(str id, Figure f,  IFigure fig) {  
    int x  =getAtX(fig);
    int y = getAtY(fig);
    int lw = getLineWidth(f);
    int hpad = hPadding(f);
    int vpad = vPadding(f);
    int width = f.width>=0?f.width-lw:-1;
    int height = f.height>=0?f.height-lw:-1;
    str g = ""; 
    if (text(_):=f.fig) {
       int fw =  (f.fig.fontSize<0?12:f.fig.fontSize);
       int w = f.width/2; 
       int h =  f.height/2;
       g = "d3.select(\"#<fig.id>\")<attr("x", w)><attr("y", h+fw/2)>;";
       }
    return styleInsideSvgOverlay(id, f) +
        "    
        'd3.select(\"#<id>_fo\")
        '<attr("width", width)><attr("height", height)>
        '<style("visibility", getVisibility(f))> 
        '<hasForm(f)?attr("pointer-events", "all"):attr("pointer-events", "none")> 
        '<debugStyle()>
        ';    
        '       
        'd3.select(\"#<id>_fo_table\")
        '<style("width", width)><style("height", height)>
        '<attr("pointer-events", "none")> 
        '<_padding(f.padding)> 
        '<debugStyle()>
        ';
        '<g>
        "
        + ((iemptyFigure(_)!:=fig && f.width<0)?"fromInnerToOuterFigure(<figCall(f,getAtX(fig),getAtY(fig))>, \"<getId(fig)>\", <lw>, <hpad>, <vpad>);\n":"")
        ;     
      }
         
num cxL(Figure f) =  f.cx<0?
      (((ellipse():=f)?(f.rx):(f.r)) + (getLineWidth(f)>=0?(getLineWidth(f))/2.0:0))
      : f.cx;
num cyL(Figure f) =  f.cy<0?
      (((ellipse():=f)?(f.ry):(f.r))+ (getLineWidth(f)>=0?(getLineWidth(f))/2.0:0))
      : f.cy;

     
 IFigure _ellipse(str id, bool fo, Figure f,  IFigure fig = iemptyFigure(0)) {
      int lw = getLineWidth(f);    
      if (emptyFigure():=f.fig) fo = false;
      Alignment align = f.align;
      str tg = "";
      num x  = 0;
      num y = 0;
      switch (f) {
          case ellipse(): {
                           tg = "ellipse";
                           num lww = lw>=0?lw:0;
                           x = cxL(f)-f.rx-lww/2;
                           y = cyL(f)-f.ry-lww/2;
                           if (f.width>=0 && f.rx<0) f.rx = f.width/2;
                           if (f.height>=0 && f.ry<0) f.ry = f.height/2;    
                           if (f.width<0 && f.rx>=0) f.width= round(f.rx*2+x);
                           if (f.height<0 && f.ry>=0) f.height = round(f.ry*2+y);                   
                           }
          case circle(): {
                          num lww = lw>=0?lw:0;
                          tg = "circle";
                          x = cxL(f)-f.r-lww/2;
                          y = cyL(f)-f.r-lww/2;
                          if (f.width>=0 && f.height>=0 && f.r<0) 
                                       f.r = (max([f.width, f.height]))/2;
                          if (f.width<0 && f.r>=0) f.width= round(f.r*2+x);
                          if (f.height<0 && f.r>=0) f.height = round(f.r*2+y);                 
                          }
          } 
       str begintag =
         "\<svg  xmlns = \'http://www.w3.org/2000/svg\' id=\"<id>_svg\"\><beginScale(f)><beginRotate(f)>\<rect id=\"<id>_rect\"/\> \<<tg> id=\"<id>\"/\> 
         '<beginTag("<id>", fo, fig, align, lw)>
         ";
       str endtag = endTag(fo);
       endtag += "<endRotate(f)><endScale(f)>\</svg\>"; 
       int width = f.width;
       int height = f.height;
       widget[id] = <getCallback(f.event), seq, id, begintag, endtag, 
        "
        'd3.select(\"#<id>_rect\")
        '<style("fill","none")><style("stroke", debug?"black":"none")><style("stroke-width", 1)>
        '<attr("x", 0)><attr("y", 0)><attr("width", width)><attr("height", height)>
        ;
        'd3.select(\"#<id>\")
        '<on(f)>
        '<attr("cx", toP(cxL(f)))><attr("cy", toP(cyL(f)))> 
        '<attr("width", width)><attr("height", height)>
        '<ellipse():=f?"<attr("rx", toP(f.rx))><attr("ry", toP(f.ry))>":"<attr("r", toP(f.r))>">
        '<styleInsideSvg(id, f, fig)>
        ", width, height,  getAtX(f), getAtY(f), f.hshrink, f.vshrink, f.align, f.cellAlign,  getLineWidth(f), getLineColor(f)
         , f.sizeFromParent, true >;
       addState(f);
       widgetOrder+= id;
       if (iemptyFigure(_)!:=fig && getResizable(f) && (getWidth(fig)<0 || getHeight(fig)<0))
          adjust+= fromOuterToInner(fig, id, getN(fig), getAngle(fig), getAtX(fig), getAtY(fig)); 
       return ifigure(id, [fig]);
       }
       
num rescale(num d, Rescale s) = s[1][0] + (d-s[0][0])*(s[1][1]-s[1][0])/(s[0][1]-s[0][0]);
       
str toP(num d, Rescale s) {
        num e = rescale(d, s);
        num v = abs(e);
        return "<e<0?"-":""><toInt(v)>.<toInt(v*10)%10><toInt(v*100)%10><toInt(v*1000)%10>";
        }
        
str toP(num d) {
        if (d<0) return "";
        return toP(d, <<0,1>, <0, 1>>);
        }
      
str translatePoints(Figure f, Rescale scaleX, Rescale scaleY, int x, int y) {
       Points p;
       if (polygon():=f) {
           p = f.points;         
       }
       else if (f.r<0) return "";
       if (g:ngon():=f) {
             num angle = 2 * PI() / g.n;
             num z = g.angle/360.0*2*PI();
             p  = [<x+g.r*cos(z+i*angle), y+g.r*sin(z+i*angle)>|int i<-[0..g.n]];
             }
       return "<toP(p[0][0], scaleX)>,<toP(p[0][1], scaleY)>" + 
            "<for(t<-tail(p)){> <toP(t[0], scaleX)>,<toP(t[1], scaleY)><}>";
       }
    
str extraCircle(str id, Figure f) {
       if (ngon():=f) {
            return "\<circle id=\"<id>_circle\"/\>";
            }
       return "";
       } 
       
int corner(Figure f) {
     return corner(f.n, getLineWidth(f));
    }
    
int corner(int n, int lineWidth) {
     num angle = 2 * PI() / n;
     int lw = lineWidth<0?0:lineWidth;
     return toInt(lw/cos(0.5*angle))+1;
    }  
   

num rR(Figure f)  = ngon():=f?f.r+corner(f)/2:-1;

int getPolWidth(Figure f) {
         if (f.width>=0) return f.width;
         num width = rescale(max([p.x|p<-f.points]), f.scaleX)+getLineWidth(f);  
         return toInt(width);
         }

int getPolHeight(Figure f) {
         if (f.height>=0) return f.height;
         num height = rescale(max([p.y|p<-f.points]), f.scaleY)+getLineWidth(f);     
         return toInt(height);
         }
       
IFigure _polygon(str id, Figure f,  IFigure fig = iemptyFigure(0)) {
       if (f.yReverse) f.scaleY = <<0, f.height>, <f.height, 0>>;
       f.width = getPolWidth(f);
       f.height = getPolHeight(f);   
       str begintag = "";
       begintag+=
         "\<svg id=\"<id>_svg\"\>\<polygon id=\"<id>\"/\>       
         ";
       str endtag = "\</svg\>"; 
       widget[id] = <getCallback(f.event), seq, id, begintag, endtag, 
        "  
        'd3.select(\"#<id>\")
        '<on(getEvent(f.event), "doFunction(\"<getEvent(f.event)>\", \"<id>\")")>
        '<attr("points", translatePoints(f, f.scaleX, f.scaleY, 0, 0))>
        '<style("fill-rule", f.fillEvenOdd?"evenodd":"nonzero")>
        '<attr("width", f.width)><attr("height", f.height)>
        '<styleInsideSvgOverlay(id, f)>
        ", f.width, f.height, getAtX(f), getAtY(f),  f.hshrink, f.vshrink, f.align, f.cellAlign,  getLineWidth(f), getLineColor(f)
         , f.sizeFromParent, true >;
       addState(f);
       widgetOrder+= id;
       return ifigure(id, [fig]);
       }
       
 
num xV(Vertex v) = (line(num x, num y):=v)?x:((move(num x1, num y1):=v)?x1:0);

num yV(Vertex v) = (line(num x, num y):=v)?y:((move(num x1, num y1):=v)?y1:0);
      
str trVertices(Figure f) {
     if (shape(list[Vertex] vertices):=f) {
       return trVertices(f.vertices, shapeClosed= f.shapeClosed, shapeCurved = f.shapeCurved, shapeConnected= f.shapeConnected,
       scaleX = f.scaleX, scaleY=f.scaleY);
       }
     return "";
     }     
      
str trVertices(list[Vertex] vertices, bool shapeClosed = false, bool shapeCurved = true, bool shapeConnected = true,
    Rescale scaleX=<<0,1>, <0, 1>>, Rescale scaleY=<<0,1>, <0, 1>>) {
    if (size(vertices)==0) return "";
	str path = "M<toP(vertices[0].x, scaleX)> <toP(vertices[0].y, scaleY)>"; // Move to start point
	int n = size(vertices);
	if(shapeConnected && shapeCurved && n > 2){
		path += "Q<toP((vertices[0].x + vertices[1].x)/2.0, scaleX)> <toP((vertices[0].y + vertices[1].y)/2.0, scaleY)> <toP(vertices[1].x, scaleX)> <toP(vertices[1].y, scaleY)>";
		for(int i <- [2 ..n]){
			v = vertices[i];
			path += "<isAbsolute(v) ? "T" : "t"><toP(v.x, scaleX)> <toP(v.y, scaleY)>"; // Smooth point on quadartic curve
		}
	} else {
		for(int i <- [1 .. n]){
			v = vertices[i];
			path += "<directive(v)><toP(v.x, scaleX)> <toP(v.y, scaleY)>";
		}
	}	
	if(shapeConnected && shapeClosed) path += "Z";
	return path;		   
}

bool isAbsolute(Vertex v) = (getName(v) == "line" || getName(v) == "move" || getName(v) == "arc");

str directive(Vertex v) {switch(getName(v)) {
        case "line":return "L";
        case "lineBy":return "l";
        case "move":return "M";
        case "moveBy":return "m";
        case "arc": return "A <v.rx> <v.ry> <v.rotation> <v.largeArc?1:0> <v.sweep?1:0>";
        case "arcBy": return "a <v.rx> <v.ry> <v.rotation> <v.largeArc?1:0> <v.sweep?1:0>";
        }
        return "";
        }
        
str mS(Figure f, str v) = ((emptyFigure():=f)?"": v);

IFigure _pack(str id, Figure f, IFigure fig1...) {
       int width = f.width<0?1000:f.width;
       int height = f.height<0?10000:f.height;
       f.width=-1; f.height= -1;
       str begintag=
         "\<svg id=\"<id>_svg\" width=\"10000\" height=\"10000\" \>
         ' \<g id=<id>\> 
         ";
       str endtag = "\</g\>\</svg\>";
       widget[id] = <getCallback(f.event), seq, id, begintag, endtag, 
        "
        ' var blocks = [
        ' <for (IFigure d<-fig1) {> {id:\"<getId(d)>\",w: getWidth(\"#<getId(d)>_svg\"),h: getHeight(\"#<getId(d)>_svg\"),x: 0, y: 0},<}>];
        ' runPacker(\"<id>\", blocks, <width>, <height>);
        'd3.select(\"#<id>\")
        '// <on(getEvent(f.event), "doFunction(\"<id>\")")>
        '<styleInsideSvgOverlay(id, f)>
        ", f.width, f.height, getAtX(f), getAtY(f), f.hshrink, f.vshrink, f.align, f.cellAlign,  getLineWidth(f), getLineColor(f)
         , f.sizeFromParent, true >;
       widgetOrder+= id;
       return ifigure(id, fig1);
       }
       
IFigure _path(str id, Figure f,  IFigure fig = iemptyFigure(0)) {
       if (path(str transform, num scale, num x, num y, list[str] d):= f) {
          if (isEmpty(getFillColor(f))) f.fillColor= "white";
          num lw = f.lineWidth<0?1:f.lineWidth;
          f.lineWidth = -1;
          str begintag = "";
          begintag+=
             "\<svg id=\"<id>_svg\"\><visitDefs(id, true)><beginRotate(f)>\<path id=\"<id>\"/\>       
           ";
          str endtag="<endRotate(f)>"; 
          endtag += "\</svg\>"; 
          widget[id] = <getCallback(f.event), seq, id, begintag, endtag, 
          "
          'd3.select(\"#<id>\")
          '<on(getEvent(f.event), "doFunction(\"<id>\")")>
          '<attr("d", intercalate(",", d))> 
          '<style("marker-start", mS(f.startMarker, "url(#m_<id>_start)"))>
          '<style("marker-mid", mS(f.midMarker, "url(#m_<id>_mid)"))>
          '<style("marker-end",  mS(f.endMarker,"url(#m_<id>_end)"))>
          '<style("fill-rule", f.fillEvenOdd?"evenodd":"nonzero")>
          '<if(lw>=0){><style("stroke-width", lw/scale)><}>
          '<attr("width",  f.width)><attr("height",  f.height)>
          '// <attr("vector-effect", "non-scaling-stroke")>
          '<attr("transform", "translate(<x>, <y>) scale(<scale>)"+transform)>
          '<styleInsideSvgOverlay(id, f)>
          ",f.width, f.height, getAtX(f), getAtY(f), f.hshrink, f.vshrink, f.align, f.cellAlign,  getLineWidth(f), getLineColor(f)
          ,f.sizeFromParent, true >;
          addState(f);
          widgetOrder+= id;
          }
       return ifigure(id, [fig]);
       }
       
IFigure _shape(str id, Figure f,  IFigure fig = iemptyFigure(0)) {
       num bottom = 0, right = 0;
       if (isEmpty(getFillColor(f))) f.fillColor= "white";
       if (shape(list[Vertex] vs):= f && !isEmpty(vs)) {
           bottom = max([rescale(p.y, f.scaleY)|p<-vs]);
           right =  max([rescale(p.x, f.scaleX)|p<-vs]);
       }   
       if (f.height<0)
            f.height = toInt(bottom)+ 100;
       if (f.width<0) 
             f.width = toInt(right)+ 100;
       if (abs(f.scaleX[1][1]-f.scaleX[1][0])>f.width) 
            f.width = toInt(abs(f.scaleX[1][1]-f.scaleX[1][0]));
       if (abs(f.scaleY[1][1]-f.scaleY[1][0])>f.height)
           f.height = toInt(abs(f.scaleY[1][1]-f.scaleY[1][0]));
       if (f.yReverse && f.scaleY==<<0,1>,<0,1>> && f.height>0) f.scaleY = <<0, f.height>, <f.height, 0>>; 
       str begintag = "";
       begintag+=
         "\<svg id=\"<id>_svg\"\><visitDefs(id, true)><if(f.yReverse){>\<g id=\"<id>_mirror\"\><}><beginRotate(f)>\<path id=\"<id>\"/\>       
         ";
       str endtag="<endRotate(f)>"; 
       endtag += "<if(f.yReverse){>\</g\><}>\</svg\>"; 
       widget[id] = <getCallback(f.event), seq, id, begintag, endtag, 
        "
        'd3.select(\"#<id>\")
        '<on(getEvent(f.event), "doFunction(\"<id>\")")>
        '<attr("d", "<trVertices(f)>")> 
        '<style("marker-start", mS(f.startMarker, "url(#m_<id>_start)"))>
        '<style("marker-mid", mS(f.midMarker, "url(#m_<id>_mid)"))>
        '<style("marker-end",  mS(f.endMarker,"url(#m_<id>_end)"))>
        '<style("fill-rule", f.fillEvenOdd?"evenodd":"nonzero")>
        '<attr("width",  f.width)><attr("height",  f.height)>
        '<styleInsideSvgOverlay(id, f)>
        ", f.width, f.height, getAtX(f), getAtY(f), f.hshrink, f.vshrink, f.align, f.cellAlign,  getLineWidth(f), getLineColor(f)
         , f.sizeFromParent, true >;
       addState(f);
       widgetOrder+= id;
       return ifigure(id, [fig]);
       }
       
str beginRotateNgon(Figure f) {
    
    if (f.rotate[0]==0) return "";
    if (f.rotate[1]<0 && f.rotate[2]<0) {
        f.rotate[1] = f.width/2;
        f.rotate[2]=  f.height/2;
        return "\<g transform=\"rotate(<f.rotate[0]>,<f.rotate[1]>,<f.rotate[2]>)\" \>";
        }
    }
                 
IFigure _ngon(str id, bool fo, Figure f,  IFigure fig = iemptyFigure(0)) {
       int lw = getLineWidth(f);
       if (iemptyFigure(_):=fig) fo = false;
       // Alignment align = isAlign(getAlign(fig))?getAlign(fig):f.align;
       Alignment align = f.align;
       if (f.r<0 && f.height>0 &&f.width>0) {
             int d = min([f.height, f.width]);
             f.r = (d)/2;
             f.height = d;
             f.width = d;
             }
       else {
           if (f.width<0 && f.r>=0) f.width= round(2*f.r);
           if (f.height<0 && f.r>=0) f.height = round(2*f.r);
           }
       str begintag = "";
       begintag+=
         "\<svg <moveAt(fo, f)> id=\"<id>_svg\"\><beginScale(f)><beginRotateNgon(f)>\<polygon id=\"<id>\"/\>        
         '<beginTag("<id>", fo, fig, align, corner(f))>
         ";
       str endtag =  endTag(fo); 
       endtag += "<endRotate(f)><endScale(f)>\</svg\>"; 
       widget[id] = <getCallback(f.event), seq, id, begintag, endtag, 
        "     
        'd3.select(\"#<id>\")
        '<on(f)>
        '<f.width>=0?attr("points", translatePoints(f, f.scaleX, f.scaleY, toInt((f.width+lw)/2), toInt((f.height+lw)/2))):""> 
        '<attr("width", f.width)><attr("height", f.height)>
        '<styleInsideSvg(id, f, fig)>
        ", f.width, f.height, getAtX(f), getAtY(f),  f.hshrink, f.vshrink, f.align, f.cellAlign,  getLineWidth(f), getLineColor(f)
         , f.sizeFromParent, true >;
       addState(f);
       widgetOrder+= id;
       if (iemptyFigure(_)!:=fig && getResizable(f) && (getWidth(fig)<0 || getHeight(fig)<0)) {
          adjust+= fromOuterToInner(fig, id, getN(fig), getAngle(fig), getAtX(fig), getAtY(fig)); 
          }
       return ifigure(id, [fig]);
       }
       
str vAlign(Alignment align) {
       if (align == bottomLeft || align == bottomMid || align == bottomRight) return "valign=\"bottom\"";
       if (align == centerLeft || align ==centerMid || align ==centerRight)  return "valign=\"middle\"";
       if (align == topLeft || align == topMid || align == topRight) return "valign=\"top\"";
       return "";
       }
       
str hAlign(Alignment align) {
       if (align == bottomLeft || align == centerLeft || align == topLeft) return "align=\"left\"";
       if (align == bottomMid || align == centerMid || align == topMid) return "align=\"center\"";
       if (align == bottomRight || align == centerRight || align == topRight) return "align=\"right\""; 
       return "";   
       }
       
str _padding(tuple[int, int, int, int] p) {
       return stylePx("padding-left", p[0])+stylePx("padding-top", p[1])
             +stylePx("padding-right", p[2])+stylePx("padding-bottom", p[3]);     
       }
   
IFigure _overlay(str id, Figure f, IFigure fig1...) {
       int lw = getLineWidth(f)<0?0:getLineWidth(f); 
       if (f.width<0 && min([getWidth(g)|g<-fig1])>=0) f.width = max([getAtX(g)+getWidth(g)|g<-fig1]);
       if (f.height<0 && min([getHeight(g)|g<-fig1])>=0) f.height = max([getAtY(g)+getHeight(g)|g<-fig1]);
       str begintag =
         "\<svg id=\"<id>_svg\" \><beginScale(f)><beginRotate(f)>\<g id=\"<id>\"\>";
       str endtag="<endRotate(f)><endScale(f)>\</g\>\</svg\>";
       int width = f.width;
       int height = f.height;
        widget[id] = <getCallback(f.event), seq, id, begintag, endtag, 
        "
        'd3.select(\"#<id>\") 
        '<attr("width", width)><attr("height", height)>
        '<styleInsideSvgOverlay(id, f)>    
        ';
        '<for (q<-fig1){> 
        '    if (d3.select(\"#<getId(q)>_outer_fo\").empty())
        '    d3.select(\"#<getId(q)>_svg\")<attr1Px("x", getAtX(q))><attr1Px("y", getAtY(q))>
        '    <attr("pointer-events", "none")>
        '  else 
        '     d3.select(\"#<getId(q)>_outer_fo\")<attr1Px("x", getAtX(q))><attr1Px("y", getAtY(q))>
        '     <attr("pointer-events", "none")>        
        ';<}>     
         'd3.select(\"#<id>\")<style("stroke-width", 0)>
         '<attr("pointer-events", "none")> 
         ; 
         adjustOverlayFromCells("+figCalls(fig1)+", \"<id>\", <getLineWidth(f)<0?0:getLineWidth(f)>,   <-hPadding(f)>, <-vPadding(f)>);\n
         "
        , f.width, f.height, getAtX(f), getAtY(f), f.hshrink, f.vshrink, f.align, f.cellAlign,  getLineWidth(f), getLineColor(f), f.sizeFromParent, true >;
       addState(f);
       if (getResizable(f)) {
           // adjust+=  "
           adjust+= "adjustOverlayCells("+figCalls(fig1)+", \"<id>\", <getLineWidth(f)<0?0:-getLineWidth(f)>,   <-hPadding(f)>, <-vPadding(f)>);\n";
         }
       widgetOrder+= id;
       return ifigure(id ,fig1);
       }
       
IFigure _buttonInput(str id, Figure f, str txt, bool addSvgTag) {
       int width = f.width;
       int height = f.height;
       str cls = f.panel==emptyFigure()?"":"class=\"panelButton\"";
       str begintag = "";
       if (addSvgTag) {
          begintag+=
         "\<svg id=\"<id>_svg\"\> 
         '\<foreignObject id=\"<id>_fo\" x=0 y=0 width=\"<upperBound>px\" height=\"<upperBound>px\"\>";
         }
       begintag+="                    
            '\<button  id=\"<id>\" value=\"<txt>\" <cls>\>"
            ;
       str endtag="
            '\</button\>
            "
            ;
       if (addSvgTag) {
            endtag += "\</foreignObject\>\</svg\>"; 
          }
        widget[id] = <getCallback(f.event), seq, id, begintag, endtag, 
        "  
        'd3.select(\"#<id>\")
        '<if(f.panel==emptyFigure()){><on("click", "doFunction(\"click\",\"<id>\")")><}>
        '<stylePx("width", width)><stylePx("height", height)>
        '<attrPx("w", width)><attrPx("h", height)>   
        '<attr1("disabled", f.disabled?"true":"null")>
        '<debugStyle()>
        '<style("background-color", "<getFillColor(f)>")> 
        '.text(\"<txt>\")     
        ;
        var width =parseInt(d3.select(\"#<id>\").style(\"width\"))+4;
        var height = parseInt(d3.select(\"#<id>\").style(\"height\"))+4;
        d3.select(\"#<id>_svg\")<attr1("width", "width")>;
        d3.select(\"#<id>_svg\")<attr1("height", "height")>;
        d3.select(\"#<id>_fo\")<attr1("width", "width")>;
        d3.select(\"#<id>_fo\")<attr1("height", "height")>;
        "
        , width, height, getAtX(f), getAtY(f), f.hshrink, f.vshrink, f.align, f.cellAlign,  getLineWidth(f), getLineColor(f), f.sizeFromParent, false >;
       addState(f);
       widgetOrder+= id;
       return ifigure(id ,[]);
       }
       
IFigure _rangeInput(str id, Figure f, bool addSvgTag) {
       int width = f.width;
       int height = f.height; 
       str begintag = "";
       void nothing(str e, str n, str v) {;};
       if (f.event==noEvent()) f.event=on("change", nothing);
       if (addSvgTag) {
          begintag+=
         "\<svg id=\"<id>_svg\"\>  
         '\<foreignObject id=\"<id>_fo\" x=0 y=0 width=\"<upperBound>px\" height=\"<upperBound>px\"\>";
         }
       begintag+="                    
            '\<input type=\"range\" min=\"<f.low>\" max=\"<f.high>\" step=\"<f.step>\" id=\"<id>\"  class=\"form\" value= \"<f.\value>\"/\>
            "
            ;
       str endtag=""
            ;
       if (addSvgTag) {
            endtag += "\</foreignObject\>\</svg\>"; 
          }
        // println("id=<id>");
        widget[id] = <getCallback(f.event),seq, id, begintag, endtag, 
        "   
        'd3.select(\"#<id>\")<on(getEvent(f.event), "doFunction(\"change\", \"<id>\")")>
        '<stylePx("width", width)><stylePx("height", height)> 
        '<attrPx("w", width)><attrPx("h", height)>     
        '<debugStyle()>
        '<style("background-color", "<getFillColor(f)>")>   
        ;"
        , width, height, getAtX(f), getAtY(f), f.hshrink, f.vshrink, f.align, f.cellAlign,  getLineWidth(f), getLineColor(f), f.sizeFromParent, false >;
       addState(f);
       widgetOrder+= id;
       return ifigure(id ,[]);
       } 
       
IFigure _strInput(str id, Figure f, bool addSvgTag) {
       int width = f.width;
       int height = f.height; 
       str begintag = "";
       if (addSvgTag) {
          begintag+=
         "\<svg id=\"<id>_svg\"\>  
         '\<foreignObject id=\"<id>_fo\" x=0 y=0 width=\"<upperBound>px\" height=\"<upperBound>px\"\>";
         }
       begintag+="                    
            '\<input type=\"text\" size= \"<f.nchars>\" id=\"<id>\" class=\"form\" value= \"<f.\value>\"
            ' <if (f.keydown){>onkeydown=\"CR(event, \'keydown\', \'<id>\', this.value)\"<}>
            ' /\>
            "
            ;
       
       str endtag=""
            ;
       if (addSvgTag) {
            endtag += "\</foreignObject\>\</svg\>"; 
          }
        widget[id] = <getCallback(f.event), seq, id, begintag, endtag, 
        "   
        'd3.select(\"#<id>\")    
        '<stylePx("width", width)><stylePx("height", height)> 
        '<attrPx("w", width)><attrPx("h", height)>   
        '<debugStyle()>
        '<style("background-color", "<getFillColor(f)>")> 
        ;"
        , width, height, getAtX(f), getAtY(f), f.hshrink, f.vshrink, f.align, f.cellAlign,  getLineWidth(f), getLineColor(f), f.sizeFromParent, false >;
       addState(f);
       widgetOrder+= id;
       return ifigure(id ,[]);
       } 
       
       
IFigure _choiceInput(str id, Figure f, bool addSvgTag) {
       int width = f.width;
       int height = f.height; 
       str begintag = "";
       if (addSvgTag) {
          begintag+=
         "\<svg id=\"<id>_svg\"\> 
         '\<foreignObject id=\"<id>_fo\" x=0 y=0 width=\"<upperBound>px\" height=\"<upperBound>px\"\>
         "
         ;
         }
       begintag+=
       "\<form id = \"<id>\" class=\"form\" align = \"left\"\>
       "
       ;
       for (c<-f.choices) {
       begintag+="                
            '\<input type=\"radio\" name=\"<id>\"  class=\"<id>\" id=\"<id>_<c>_i\" value=\"<c>\"
            ' onclick=\"radioAsk(\'click\', \'<id>\', this.value)\"
            ' <c==f.\value?"checked":"">
            '/\>
            <c>\<br\>
            "
            ;
        }
       str endtag="
            '\</form\>
            "
            ;
       if (addSvgTag) {
            endtag += "\</foreignObject\>\</svg\>"; 
          }
        widget[id] = <getCallback(f.event), seq, id, begintag, endtag, 
        "     
        'd3.select(\"#<id>\")
        '<stylePx("width", width)><stylePx("height", height)> 
        '<attrPx("w", width)><attrPx("h", height)>   
        '<debugStyle()>
        '<style("background-color", "<getFillColor(f)>")>   
        ;
        'var width =parseInt(d3.select(\"#<id>\").style(\"width\"))+4;
        '// alert(width);
        'var height = parseInt(d3.select(\"#<id>\").style(\"height\"))+4;
        'd3.select(\"#<id>_svg\")<attr1("width", "width")>;
        'd3.select(\"#<id>_svg\")<attr1("height", "height")>;
        'd3.select(\"#<id>_fo\")<attr1("width", "width")>;
        'd3.select(\"#<id>_fo\")<attr1("height", "height")>
        ; 
        "
        , width, height, getAtX(f), getAtY(f), f.hshrink, f.vshrink, f.align, f.cellAlign,  getLineWidth(f), getLineColor(f), f.sizeFromParent, false >;
       addState(f);
       widgetOrder+= id;
       return ifigure(id ,[]);
       }
       
str flagsToString(list[bool] b, int l, int u) {
      str r = "<for(i<-[l,l+1..u]){><(b[i]?"1":"0")><}>";
      return r;
      }
       
 IFigure _checkboxInput(str id, Figure f, bool addSvgTag) {
       if (map[str, bool] checked := f.\value && map[str, str] labels := f.labels) {
       int width = f.width;
       int height = f.height; 
       str begintag = "";
       if (addSvgTag) {
          begintag+=
         "\<svg id=\"<id>_svg\"\> 
         '\<foreignObject id=\"<id>_fo\" x=0 y=0 width=\"<upperBound>px\" height=\"<upperBound>px\"\>";
         }
       begintag+="\<form id = \"<id>\"\>\<div align=\"left\"\>\<br\>";
       map[str, bool] choice2checked = (choice:(checked[choice]?)?checked[choice]:false|str choice<-f.choices);
       map[str, str] choice2label = (choice:(labels[choice]?)?labels[choice]:choice|str choice<-f.choices);
       int i = 0;
       for (str choice<-f.choices) {
       begintag+="                
            '\<input type=\"checkbox\" name=\"<id>_<choice>_i\"  class=\"<id>  form\" id=\"<id>_<choice>_i\" value=\"<choice>\"
            ' onclick=\"ask(\'click\', \'<id>\'
            ' ,(this.checked?\'<i+1>\':\'<-i-1>\'))\"
            ' <choice2checked[choice]?"checked":"">
            '/\>
            <choice2label[choice]>\<br\>
            "
            ;
        i=i+1;
        }
       str endtag="
            '\</div\>\</form\>
            "
            ;
       if (addSvgTag) {
            endtag += "\</foreignObject\>\</svg\>"; 
          }
        widget[id] = <getCallback(f.event), seq, id, begintag, endtag, 
        "      
        'd3.select(\"#<id>\")
        '<stylePx("width", width)><stylePx("height", height)> 
        '<attrPx("w", width)><attrPx("h", height)>   
        '<debugStyle()>
        '<style("background-color", "<getFillColor(f)>")>   
        ;"
        , width, height, getAtX(f), getAtY(f), 0, 0, f.align, f.cellAlign,  getLineWidth(f), getLineColor(f), f.sizeFromParent, false >;
       addState(f);
       widgetOrder+= id;     
       }
       return ifigure(id ,[]);
       }      
            
set[IFigure] getUndefCells(list[IFigure] fig1) {
     return {q|q<-fig1,(getWidth(q)<0 || getHeight(q)<0)};
     }
     
int widthDefCells(list[IFigure] fig1) {
     if (isEmpty(fig1)) return 0;
     return sum([0]+[getWidth(q)|q<-fig1,getWidth(q)>=0]);
     }

int heightDefCells(list[IFigure] fig1) {
     if (isEmpty(fig1)) return 0;
     return sum([0]+[getHeight(q)|q<-fig1,getHeight(q)>=0]);
     } 
                
IFigure _hcat(str id, Figure f, bool addSvgTag, IFigure fig1...) {
       int width = f.width;
       int height = f.height; 
       str begintag = "";
       if (addSvgTag) {
          begintag+=
         "\<svg id=\"<id>_svg\"\> 
          \<foreignObject id=\"<id>_outer_fo\" x=<getAtX(f)> y=<getAtY(f)> width=\"<upperBound>px\" height=\"<upperBound>px\"\>";
         }
       begintag+="                    
            '\<table id=\"<id>\" cellspacing=\"0\" cellpadding=\"0\"\>
            '\<tr\>"
            ;
       str endtag="
            '\</tr\>
            '\</table\>
            "
            ;
        if (f.form) {
            endtag += "\<div  class=\"<id>_div\"\>\<button id=\"<id>_cancel\"\>Cancel\</button\>\<button id=\"<id>_ok\"\>Ok\</button\>\<div\>";
            }
       if (addSvgTag) {
            endtag += "\</foreignObject\>\</svg\>"; 
            }
        widget[id] = <getCallback(f.event), seq, id, begintag, endtag, 
        "
        'd3.select(\"#<id>_cancel\")<on("click", "doAllFunction(\"cancel\",\"<id>\")")>;
        'd3.select(\"#<id>_ok\")<on("click", "doAllFunction(\"ok\",\"<id>\")")>;
        'd3.select(\"#<id>\") 
        '<on(f)>
        '<stylePx("width", width)><stylePx("height", height)>
        '<attrPx("w", width)><attrPx("h", height)>      
        ' <if(debug){><debugStyle()><} else {> <borderStyleF(f)> <}>   
        '<style("background-color", "<getFillColor(f)>")> 
        '<style("border-spacing", "<f.hgap> <f.vgap>")> 
        '<style("stroke-width",getLineWidth(f))>
        '<style("visibility", getVisibility(f))>
        '<attr("pointer-events","none")>
        '<_padding(f.padding)>;
        'adjustTableFromCells(\"<id>\", <figCalls(fig1)>)    
        ;   
        "
        , width, height, getAtX(f), getAtY(f), f.hshrink, f.vshrink, f.align, f.cellAlign,  getLineWidth(f), getLineColor(f)
        , f.sizeFromParent, false >;
       addState(f);
       adjust+=  "adjustHcatCells("+figCalls(fig1)+", \"<id>\", <getLineWidth(f)<0?0:-getLineWidth(f)>, 
               <-hPadding(f)>, <-vPadding(f)>,<f.hgap>, <f.vgap>);\n";
       IFigure r =  ifigure(id ,[td("<id>_<getSeq(g)>", f, g)| g<-fig1]);
       widgetOrder+= id;
       return r;
       }
       
 str toString(Alignment a) {
    str r = "";
    if (a[1]<0.25) r = "top";
    else
    if (a[1]>0.75) r = "bottom";
    else r = "center";
    if (a[0]<0.25) r += "Left";
    else
    if (a[0]>0.75) r += "Right";
    else r += "Mid";
    return "\"<r>\"";
    }
 
       
str figCall(IFigure f) {
   bool cellDefined = false;
   if (figMap[getId(f)]?) {
          Figure fig = figMap[getId(f)];
          cellDefined = (fig.rowspan?) || (fig.colspan?);
          }
   return 
   "figShrink(\"<getId(f)>\", <getHshrink(f)>, <getVshrink(f)>, <getLineWidth(f)>, <getN(getId(f))>, <getAngle(getId(f))>, <toString(getCellAlign(f))>,<cellDefined>)";
}

str figCall(Figure f, int x, int y) = 
"figGrow(\"<f.id>\", <f.hgrow>, <f.vgrow>, <getLineWidth(f)>, <getN(f)>, <getAngle(f)>, <toString(f.cellAlign)>, <x>, <y>)";

str figCalls(list[IFigure] fs) {
       if (isEmpty(fs)) return "[]";
       return "[<figCall(head(fs))><for(f<-tail(fs)){>,<figCall(f)><}>]";
       }
       
str figCallArray(list[list[IFigure]] fs) {
       if (isEmpty(fs)) return "[]";
       return "[<figCalls(head(fs))><for(f<-tail(fs)){>,<figCalls(f)><}>]";
       }
       
IFigure _vcat(str id, Figure f,  bool addSvgTag, IFigure fig1...) {
       int width = f.width;
       int height = f.height;
       str begintag = "";
       if (addSvgTag) {
          begintag+=
         "\<svg id=\"<id>_svg\"\> \<foreignObject id=\"<id>_outer_fo\"  x=<getAtX(f)> y=<getAtY(f)> width=\"<upperBound>px\" height=\"<upperBound>px\"\>";
         }
       begintag+="                 
            '\<table id=\"<id>\"  class=\"<id>_div\" cellspacing=\"0\" cellpadding=\"0\"\>"
           ;
       str endtag="\</table\>";
       if (f.form) {
            endtag += "\<div  class=\"<id>_div\"\>\<button id=\"<id>_cancel\"\>Cancel\</button\>\<button id=\"<id>_ok\"\>Ok\</button\>\<div\>";
            }
       if (addSvgTag) {
            endtag += "\</foreignObject\>\</svg\>"; 
            }
        widget[id] = <getCallback(f.event), seq, id, begintag, endtag, 
        "
        'd3.select(\"#<id>_cancel\")<on("click", "doAllFunction(\"cancel\",\"<id>\")")>;
        'd3.select(\"#<id>_ok\")<on("click", "doAllFunction(\"ok\",\"<id>\")")>;
        'd3.select(\"#<id>\") 
        '<stylePx("width", width)><stylePx("height", height)> 
        '<attrPx("w", width)><attrPx("h", height)>       
        '<attr("fill",getFillColor(f))><attr("stroke",getLineColor(f))>
        '<style("border-spacing", "<f.hgap> <f.vgap>")>
        '<style("stroke-width",getLineWidth(f))>
        '<if(debug){><debugStyle()><} else {> <borderStyleF(f)> <}>  
        '<style("background-color", "<getFillColor(f)>")> 
        '<style("border-spacing", "<f.hgap> <f.vgap>")> 
        '<style("stroke-width",getLineWidth(f))>
        '<style("visibility", getVisibility(f))>
        '<attr("pointer-events", "none")>
        '<_padding(f.padding)> ;
        'd3.selectAll(\".<id>_div\")<style("visibility", getVisibility(f))>;								
        'd3.select(\"#<id>_fo\")<attr("pointer-events", "none")>;
        'd3.select(\"#<id>_svg\")<attr("pointer-events", "none")>;
        'd3.select(\"#<id>_rect\")<attr("pointer-events", "none")>;
        'adjustTableFromCells(\"<id>\", <figCalls(fig1)>); 
        ", width, height, getAtX(f), getAtY(f), f.hshrink, f.vshrink, f.align, f.cellAlign,  getLineWidth(f), getLineColor(f)
         , f.sizeFromParent, false >;
       
       addState(f);
       adjust+=  "adjustVcatCells("+figCalls(fig1)+", \"<id>\", <getLineWidth(f)<0?0:-getLineWidth(f)>, 
          <-hPadding(f)>, <-vPadding(f)>,<f.hgap>, <f.vgap>);\n"; 
       IFigure r = ifigure(id, [td("<id>_<getSeq(g)>", f, g,   tr = true)| g<-fig1]);
       widgetOrder+= id;
       return r;
       }
      
list[list[IFigure]] transpose(list[list[IFigure]] f) {
       list[list[IFigure]] r = [[]|i<-[0..max([size(d)|d<-f])]];
       for (int i<-[0..size(f)]) {
            for (int j<-[0..size(f[i])]) {
                r[j] = r[j] + f[i][j];
            }
         } 
       return r; 
       }

IFigure _grid(str id, Figure f,  bool addSvgTag, list[list[IFigure]] figArray=[[]]) {
       list[list[IFigure]] figArray1 = isEmpty(figArray)?[]:transpose(figArray);
       str begintag = "";
       if (addSvgTag) {
          begintag+=
         "\<svg id=\"<id>_svg\"\>\<foreignObject id=\"<id>_outer_fo\" x=<getAtX(f)> y=<getAtY(f)> width=\"<upperBound>px\" height=\"<upperBound>px\"\>";
         }
       begintag+="                    
            '\<table id=\"<id>\" cellspacing=\"0\" cellpadding=\"0\"\>
            ";
       str endtag="
            '\</table\>
            ";
        if (f.form) {
            endtag += "\<div  class=\"<id>_div\"\>\<button id=\"<id>_cancel\"\>Cancel\</button\>\<button id=\"<id>_ok\"\>Ok\</button\>\<div\>";
            }
       if (addSvgTag) {
            endtag += "\</foreignObject\>\</svg\>"; 
            }
        widget[id] = <getCallback(f.event), seq, id, begintag, endtag, 
        "
        'd3.select(\"#<id>_cancel\")<on("click", "doAllFunction(\"cancel\",\"<id>\")")>;
        'd3.select(\"#<id>_ok\")<on("click", "doAllFunction(\"ok\",\"<id>\")")>;
        'd3.select(\"#<id>\")       
         '<if(debug){><debugStyle()><} else {> <borderStyleF(f)> <}>   
         '<on(f)>
         '<stylePx("width", f.width)><stylePx("height", f.height)> 
         '<attrPx("width", f.width)><attrPx("height", f.height)> 
         '<attrPx("w", f.width)><attrPx("h", f.height)>   
         '<style("background-color", "<getFillColor(f)>")>
         '<style("border-spacing", "<f.hgap> <f.vgap>")>
         '<style("stroke-width",getLineWidth(f))>
         '<style("visibility", getVisibility(f))>
         '<attr("pointer-events","none")>
         '<_padding(f.padding)> 
         '<debugStyle()>;
         'd3.selectAll(\".<id>_div\")<style("visibility", getVisibility(f))>;
		 'd3.select(\"#<id>_fo\")<attr("pointer-events", "none")>;
         'd3.select(\"#<id>_svg\")<attr("pointer-events", "none")>;
         'd3.select(\"#<id>_rect\")<attr("pointer-events", "none")>;
         'adjustGridTableFromCells(\"<id>\", <figCallArray(figArray)>);  
        ", f.width, f.height, getAtX(f), getAtY(f), f.hshrink, f.vshrink, f.align, f.cellAlign,  getLineWidth(f), getLineColor(f)
         , f.sizeFromParent, false >;      
       addState(f);
       list[tuple[list[IFigure] f, int idx]] fig1 = [<figArray[i], i>|int i<-[0..size(figArray)]];
       adjust+=  "adjustGridCells(<figCallArray(figArray)>, \"<id>\", <-getLineWidth(f)>, 
         <-hPadding(f)>, <-vPadding(f)>,<f.hgap>, <f.vgap>);\n";
       IFigure r = ifigure(id, [tr("<id>_r", f, f.width, f.height, g.f ) | g<-fig1]);
       widgetOrder+= id;
       return  r;     
       } 
       
 alias BorderStyle= tuple[str style, int width, str color];
       
 str borderTd(IFigure fig1) {
       BorderStyle normal=<"", -1, "">, top=<"", -1, "">, bottom=<"", -1, "">,
       left=<"", -1, "">, right=<"", -1, "">;
       if (figMap[getId(fig1)]?) {
          Figure fig = figMap[getId(fig1)];
          normal = <fig.borderStyle, fig.borderWidth, fig.borderColor>;
          top = <fig.borderTopStyle, fig.borderTopWidth, fig.borderTopColor>;
          bottom = <fig.borderBottomStyle, fig.borderBottomWidth, fig.borderBottomColor>;
          left = <fig.borderLeftStyle, fig.borderLeftWidth, fig.borderLeftColor>;
          right = <fig.borderRightStyle, fig.borderRightWidth, fig.borderRightColor>;
          }
      return 
          "
          '
          '<style("border-style", normal.style)> 
          '<style("border-color", normal.color)>  
          '<style("border-width", normal.width)> 
          '<style("border-top-style", top.style)> 
          '<style("border-top-color", top.color)>  
          '<style("border-top-width", top.width)>  
          '<style("border-bottom-style", bottom.style)> 
          '<style("border-bottom-color", bottom.color)>  
          '<style("border-bottom-width", bottom.width)>  
          '<style("border-left-style", left.style)> 
          '<style("border-left-color", left.color)>  
          '<style("border-left-width", left.width)>  
          '<style("border-right-style", right.style)> 
          '<style("border-right-color", right.color)>  
          '<style("border-right-width", right.width)>    
          ";
       }      
   
 IFigure td(str id, Figure f, IFigure fig1,  bool tr = false) {
    str begintag = tr?"\<tr\>":"";
    int rowspan = -1;
    int colspan = -1;
    tuple[int, int, int, int] padding = <0, 0, 0, 0>; // left, top, right, botton 
    if (figMap[getId(fig1)]?) {
          Figure fig = figMap[getId(fig1)];
          rowspan = fig.rowspan;
          colspan = fig.colspan;
          padding = fig.padding;
          }
    Alignment align = isAlignment(getCellAlign(fig1))?getCellAlign(fig1):f.align;
    begintag +=
    "\<td  id=\"<id>\" <vAlign(align)> <hAlign(align)> <
     rowspan>0?"rowspan=\"<rowspan>\"":""> <
     colspan>0?"colspan=\"<colspan>\"":"">
     \>";
    bool addSvgTag = (getAtX(fig1)!=0 ||  getAtY(fig1)!=0)&&f.width<0 &&f.height<0;
    if (addSvgTag) {
          begintag+=
         "\<svg id=\"<id>_svg\"\> 
          \<foreignObject id=\"<id>_outer_fo\" x=<getAtX(fig1)> y=<getAtY(fig1)> width=\"<upperBound>px\" height=\"<upperBound>px\"\>";
         } 
    str endtag="";
    if (addSvgTag) {
         endtag += "\</foreignObject\>\</svg\>"; 
         } 
    endtag += "\</td\>";
    if (tr) endtag+="\</tr\>";
    widget[id] = <null, seq, id, begintag, endtag,
        "
        'd3.select(\"#<id>\")
        '<borderTd(fig1)> 
        '<style("background-color", "<getFillColor(f)>")> 
        '<_padding(padding)>
        '<attr("pointer-events", "none")> ; 
        '<if(addSvgTag) {> 
        '      var q = \"<getId(fig1)>\";
        '      var w = getWidth(\"#\" + q + \"_svg\");
	    '      var h = getHeight(\"#\" + q + \"_svg\");
	    '      if (!isNaN(w) && !isNaN(h)) {
	    '        var x =  <getAtX(fig1)>;
	    '        var y =  <getAtY(fig1)>;
	    '        d3.select(\"#<id>_svg\")<attr1("width", "w+x")><attr1("height", "h+y")>;
	     '       d3.select(\"#<id>_outer_fo\")<attr1("width", "w")><attr1("height", "h")>;
	    '      }
	    '<}>
        ", f.width, f.height, getAtX(f), getAtY(f), 0, 0, align, align, getLineWidth(f), getLineColor(f)
         , f.sizeFromParent, false >;
       Figure g = (figMap[getId(fig1)]?)?figMap[getId(fig1)]:emptyFigure();
       addState(f);
       widgetOrder+= id;
    return ifigure(id, [fig1]);
    }
    
 IFigure tr(str id, Figure f, int width, int height, list[IFigure] figs) {
    str begintag = "\<tr\>";
    str endtag="\</tr\>";
    widget[id] = <null, seq, id, begintag, endtag,
        "
        ", width, height, width, height, 0, 0, f.align, f.cellAlign,  getLineWidth(f), getLineColor(f)
         , f.sizeFromParent, false >;
       addState(f);
       widgetOrder+= id;
    return ifigure(id, [td("<id>_<getSeq(g)>", f, g )| g<-figs]);
    }
    
 IFigure _img(str id, Figure f, bool addSvgTag) {
       int width = f.width;
       int height = f.height; 
       str begintag = "";
       if (addSvgTag) {
          begintag+=
         "\<svg id=\"<id>_svg\"\> \<rect id=\"<id>_rect\"/\> 
         '\<foreignObject id=\"<id>_fo\" x=0 y=0 width=\"<upperBound>px\" height=\"<upperBound>px\"\>";
         }
       begintag+="                    
            '\<img id=\"<id>\" src = \"<f.src>\" alt = \"Not found:<f.src>\"\>
            "
            ;
       str endtag="
            '\</img\>
            "
            ;
       if (addSvgTag) {
            endtag += "\</foreignObject\>\</svg\>"; 
            }
        widget[id] = <null, seq, id, begintag, endtag, 
        "
        'd3.select(\"#<id>\") 
        '<stylePx("width", width)><stylePx("height", height)>
        '<attrPx("width", width)><attrPx("height", height)>      
        '<debugStyle()>
        '<style("background-color", "<getFillColor(f)>")> 
        '<style("border-spacing", "<f.hgap> <f.vgap>")> 
        '<style("stroke-width",getLineWidth(f))>
        '<_padding(f.padding)>     
        ;   
        "
        , width, height, getAtX(f), getAtY(f), 0, 0, f.align, f.align, getLineWidth(f), getLineColor(f)
        , f.sizeFromParent, false >;
       addState(f);
       widgetOrder+= id;
       return ifigure(id ,[]);
       }

list[tuple[str, Figure]] addMarkers(Figure f, list[tuple[str, Figure]] ms) {
    list[tuple[str, Figure]] r = [];
    for (<str id, Figure g><-ms) {
        if (emptyFigure()!:=g) g = addMarker(f, "<g.id>", g);
        r+=<id, g>;
        }
    return r;
    }
    
Figure addPack(Figure f, Figure g) {
   if (emptyFigure()!:=g) {
     if (g.size != <0, 0>) {
       g.width = g.size[0];
       g.height = g.size[1];
       }
    if (circle():=g || ngon():=g) {
      if (g.width<0) g.width = round(2 * g.r);
      if (g.height<0) g.height = round(2 * g.r);
      }
    if (ellipse():=g) {
      if (g.width<0) g.width = round(2 * g.rx);
      if (g.height<0) g.height = round(2 * g.ry);
      }
    if (g.gap != <0, 0>) {
       g.hgap = g.gap[0];
       g.vgap = g.gap[1];
       }
     if (g.lineWidth<0) g.lineWidth = 1;
     if (g.lineOpacity<0) g.lineOpacity = 1.0;
     if (g.fillOpacity<0) g.fillOpacity = 1.0;
     if (isEmpty(g.fillColor)) g.fillColor="none";
     if (isEmpty(g.lineColor)) g.lineColor = "black";
     if (isEmpty(g.visibility)) g.visibility = "inherit";
     list[IFigure] fs = (defs[f.id]?)?defs[f.id]:[];
     buildParentTree(g);
     figMap[g.id] = g;
     fs +=_translate(g);
         defs[f.id] = fs;
       } 
     return g;
   }

Figure addMarker(Figure f, str id, Figure g) {
   if (emptyFigure()!:=g) {
     if (g.size != <0, 0>) {
       g.width = g.size[0];
       g.height = g.size[1];
       }
    if (circle():=g || ngon():=g) {
      if (g.width<0) g.width = round(2 * g.r);
      if (g.height<0) g.height = round(2 * g.r);
      }
    if (ellipse():=g) {
      if (g.width<0) g.width = round(2 * g.rx);
      if (g.height<0) g.height = round(2 * g.ry);
      }
    if (g.gap != <0, 0>) {
       g.hgap = g.gap[0];
       g.vgap = g.gap[1];
       }
     g.id = "<id>";
     if (g.lineWidth<0) g.lineWidth = 1;
     if (g.lineOpacity<0) g.lineOpacity = 1.0;
     if (g.fillOpacity<0) g.fillOpacity = 1.0;
     if (isEmpty(g.fillColor)) g.fillColor="none";
     if (isEmpty(g.lineColor)) g.lineColor = "black";
     if (isEmpty(g.visibility)) g.visibility = "inherit";
     list[IFigure] fs = (defs[f.id]?)?defs[f.id]:[];
     buildParentTree(g);
     figMap[g.id] = g;
     fs +=_translate(g);
         defs[f.id] = fs;
       } 
     return g;
   }
    
     
Figure cL(Figure parent, Figure child) { 
    if (!isEmpty(child.id)) parentMap[child.id] = parent.id; 
    value v = parent.tooltip; 
    if (Figure h:=v && h!=emptyFigure()) parentMap[h.id] = parent.id;
    v = parent.panel;
    if (Figure h:=v && h!=emptyFigure()) parentMap[h.id] = parent.id;
    return child;
    }
    
Figure addSuffix(str id, Figure g, str suffix) {
    if (g==emptyFigure()) return g;
    if (atXY(int x, int y, Figure h):=g) {
           h.id = "<id><suffix>";
           figMap[h.id] = h; 
           g = atXY(x, y, h, id  = g.id, width=g.width);
           }
    else
    if (atXY(tuple[int x, int y] z, Figure h):=g) {
           h.id = "<id><suffix>";
           figMap[h.id] = h; 
           g = atXY(z.x,z.y, h, id  = g.id, width=g.width);
           }
    else
    if (atX(int x, Figure h):=g) {
          h.id = "<id><suffix>";
           figMap[h.id] = h; 
           g = atXY(x, 0, h, id  = g.id, width=g.width);
           }
    else
    if (atY(int y, Figure h):=g) {
         h.id = "<id><suffix>";
         figMap[h.id] = h; 
         g = atXY(0, y, h, id  = g.id, width=g.width);
         }
    else {
       g.id = "<id><suffix>";
       figMap[g.id] = g;
       } 
    return g;   
    }

Figure idToFigure(Figure f) {
         if (emptyFigure():=f) {
             f.id="emptyFigure"; 
             f.seq= occur; 
             occur = occur+1; 
             return f;
             }
         if (isEmpty(f.id)) {
              f.id = "i<occur>";
              occur = occur + 1; 
              }
     value v = f.tooltip;
     if (Figure g:=v) {   
         f.tooltip = addSuffix(f.id, g, "_tooltip"); 
         }
     figMap[f.id] = f;
     v =  f.panel;
     if (Figure g:=v && g!=emptyFigure()) figMap[g.id] = g;
     return f;
     }
     

Figure buildFigMap(Figure f) {  
    return  visit(f) {
       case Figure g => idToFigure(g)
    }  
   }
   
Figure getParentFig(Figure f) = figMap[parentMap[f.id]]; 

Figure getParentFig(str id) {
      Figure f = figMap[parentMap[id]];
      while (atXY(_, _, _):=f ||  atX(_, _):=f || atY(_, _):=f)
         f = figMap[parentMap[f.id]];
      return f;  
      }

void buildParentTree(Figure f) {
    // println(f);
    visit(f) {
        case g:box(): cL(g, g.fig);
        case g:ellipse():cL(g, g.fig);
        case g:circle():cL(g, g.fig);
        case g:ngon():cL(g, g.fig);
        case g:hcat(): for (q<-g.figs) cL(g, q);
        case g:vcat(): for (q<-g.figs) cL(g, q);
        case g:grid(): for (e<-g.figArray) for (q<-e) cL(g, q);    
        case g:atXY(_, _, fg):  cL(g, fg); 
        case g:atXY(_, fg):  cL(g, fg); 
        case g:atX(_, fg):  cL(g, fg); 
        case g:atY(_, fg):  cL(g, fg);
        case g:overlay(): for (q<-g.figs) cL(g, q); 
        case g:graph():  for (q<-g.nodes) cL(g, q[1]);
        case g:tree(Figure root, Figures figs): {cL(g,root); for (q<-figs) cL(g, q);}
        case g:rotateDeg(_, fg):  cL(g, fg); 
        case g:rotateDeg(_, _, _, fg):  cL(g, fg); 
        case g:d3Tree(root):cL(g, root);
        case g:buttonInput(_):cL(g, emptyFigure());
        case g:strInput():cL(g, emptyFigure());
        case g:rangeInput():cL(g, emptyFigure());
        case g:choice():cL(g, emptyFigure());
        }  
        return; 
    } 
 
Figure hide(Figure f) { f.visibility = "hidden"; return f;} 

Figure withoutAt(Figure f) {
       switch(f) {
            case atXY(_, _, Figure g): return g;
            case atXY(_, Figure g): return g;
            case atX(_, Figure g): return g;
            case atY(_, Figure g): return g;
            }
       return f;
       }
       
 tuple[int, int] fromAt(Figure f) {
       switch(f) {
            case atXY(int x,int y , _): return <x+toInt(f.at[0]), y+toInt(f.at[1])>;
            case atXY(tuple[int x, int y] z, _): return <z.x+toInt(f.at[0]), z.y+toInt(f.at[1])>;
            case atX(int x, _): return <x+toInt(f.at[0]),toInt(f.at[1])>;
            case atY(int y, _): return <toInt(f.at[0]), y+toInt(f.at[1])>;
            }
       return <toInt(f.at[0]), toInt(f.at[1])>;
       }
       
Figure cellAlignDefault(Figure f, Figure g) {if (!isCellAlign(g)) g.cellAlign = isAlign(f)?f.align:topLeft; return g;}
               
IFigure _translate(Figure f,  bool addSvgTag = false,
    bool inHtml = true) {
    if (f.size != <0, 0>) {
       if (f.width<0) f.width = f.size[0];
       if (f.height<0) f.height = f.size[1];
       }
    if (f.gap != <0, 0>) {
       f.hgap = f.gap[0];
       f.vgap = f.gap[1];
       }
    if (f.shrink?) {
            f.hshrink = f.shrink;
            f.vshrink = f.shrink;
            }
    if (f.grow?) {
            f.hgrow = f.grow;
            f.vgrow = f.grow;
            }
    value v = f.tooltip;
    if (Figure g:=v && emptyFigure()!:=g) {tooltips +=  _translate(g, addSvgTag=true); }
    v = f.panel;
    if (Figure g:=v && emptyFigure()!=g) {panels +=  _translate(g, addSvgTag=true); }
    switch(f) {   
        case box(): {
                  return _rect(f.id, true, f, fig = _translate(f.fig,  inHtml = true));
                  }
        case emptyFigure(): return iemptyFigure(f.seq);
        case ellipse():  return _ellipse(f.id, true, f, fig = 
             _translate(f.fig)
             );
        case circle():  return _ellipse(f.id, true, f, fig = _translate(f.fig,  inHtml=true));
        case polygon():  return _polygon(f.id,  f);
        case pack(Figures fs): return _pack(f.id, f, [_translate(q, addSvgTag = true)|q<-fs]);
        case shape(list[Vertex] _):  {
                       addMarker(f, "<f.id>_start", f.startMarker);
                       addMarker(f, "<f.id>_mid", f.midMarker);
                       addMarker(f, "<f.id>_end", f.endMarker);
                       return _shape(f.id, f);
                       }
        case path(str _, num _, num _, num _, list[str] _):  {
                       addMarker(f, "<f.id>_start", f.startMarker);
                       addMarker(f, "<f.id>_mid", f.midMarker);
                       addMarker(f, "<f.id>_end", f.endMarker);
                       return _path(f.id, f);
                       }
        case ngon():  return _ngon(f.id, true, f, fig = _translate(f.fig,  inHtml=true));
        case htmlText(value s): {if (str t:=s) return _text(f.id, inHtml, f, t, f.overflow, addSvgTag);
                            return iemptyFigure(0);
                            } 
        case svgText(value s): {if (str t:=s) return _text(f.id, inHtml, f, t, f.overflow, addSvgTag);
                            return iemptyFigure(0);
                            } 
        case text(value s): {if (str t:=s) return _text(f.id, inHtml, f, t, f.overflow, addSvgTag);
                            return iemptyFigure(0);
                            } 
        case image():  return _img(f.id,   f, addSvgTag);                
        case hcat(): return _hcat(f.id, f, addSvgTag, [_translate(q)|q<-f.figs]
            );
        case vcat(): return _vcat(f.id, f, addSvgTag, [_translate(q)|q<-f.figs]
         );
         
        case overlay(): { 
              IFigure r = _overlay(f.id, f,  [_translate(cellAlignDefault(f, q), addSvgTag = true, inHtml=false )|q<-f.figs]);   
              return r;
              }
              
        case grid(): return _grid(f.id, f, addSvgTag, figArray= [[_translate(q)|q<-e]|e<-f.figArray]
        );
        case atXY(int x, int y, Figure fig): {
                     fig.rotate = f.rotate;
                     fig.at = <x, y>; 
                     return _translate(fig, inHtml=true, addSvgTag = true);
                     }
        case atXY(tuple[int x, int y] z, Figure fig): {
                     fig.rotate = f.rotate;
                     fig.at = <z.x, z.y>; 
                     return _translate(fig, inHtml=true, addSvgTag = true);
                     }
        case atX(int x, Figure fig):	{
                    fig.rotate = f.rotate;
                    fig.at = <x, 0>; 
                    return _translate(fig, inHtml=true, addSvgTag = true);
                    }			
        case atY(int y, Figure fig):	{
                    fig.rotate = f.rotate;
                    fig.at = <0, y>; 
                    return _translate(fig, inHtml=true, addSvgTag = true);
                    }
        case rotateDeg(num angle, int x, int y, Figure fig): {
             fig.rotate = <angle, x, y>; return _translate(fig, inHtml=true);}
        case rotateDeg(num angle,  Figure fig): {
           fig.rotate = <angle, -1, -1>; 
           fig.at = f.at;
           return _translate(fig, inHtml=true);
           }		
        case buttonInput(str txt):  return _buttonInput(f.id, f,  txt, f.panel==emptyFigure()?addSvgTag:true);
        case rangeInput():  return _rangeInput(f.id, f, addSvgTag);
        case strInput():  return _strInput(f.id, f, addSvgTag);
        case choiceInput():  return _choiceInput(f.id, f, addSvgTag);
        case checkboxInput():  return _checkboxInput(f.id, f, addSvgTag);
        case comboChart():  return _googlechart("ComboChart", f.id, f, addSvgTag);
        case pieChart():  return _googlechart("PieChart", f.id, f, addSvgTag );
        case candlestickChart():  return _googlechart("CandlestickChart", f.id, f, addSvgTag);
        case lineChart():  return _googlechart("LineChart", f.id, f, addSvgTag);
        case scatterChart():  return _googlechart("ScatterChart", f.id, f, addSvgTag);
        case areaChart():  return _googlechart("AreaChart", f.id, f, addSvgTag);
        case graph(): {
              if (f.width<0) f.width = 800;
              if (f.height<0) f.height = 800;
              Figures figs = [n[1]|n<-f.nodes];
              list[IFigure] ifs = [_translate(q, addSvgTag = true)|q<-figs];
              extraGraphData[f.id]  = (n[0]:getId(i)| <tuple[str, Figure] n, IFigure i> <-zip(f.nodes, ifs));
              IFigure r =
               _overlay("<f.id>", f 
                , 
                [_graph("<f.id>_graph", f)] 
                +ifs
                );
               return r;        
        }
        case tree(Figure root, Figures figs): {  
              list[Figure] fs = treeToList(f);
              list[IFigure] ifs =  [_translate(q, addSvgTag = true)|Figure q<-fs];      
              map[str, tuple[int, int]] m = (getId(g): <getWidth(g), getHeight(g)>|IFigure g<-ifs);
              list[Vertex] vs  = treeLayout(f, m,  1, f.refinement, f.rasterHeight, f.manhattan,
              xSeparation=f.xSep, ySeparation=f.ySep);
              tuple[int ,int] dim = computeDim(fs, m);
              vs  = vertexUpdate(vs, f.orientation, dim[0], dim[1]);
              fs = treeUpdate(fs, m, f.orientation, dim[0], dim[1]); 
              for (Figure g<-fs) {
                  widget[g.id].x =  toInt(g.at[0]);
                  widget[g.id].y =  toInt(g.at[1]);
                  }
              if (f.width<0 && min([g.width|g<-fs])>=0) f.width = max([toInt(g.at[0])+g.width|g<-fs]);
              if (f.height<0 && min([g.height|g<-fs])>=0) f.height = max([toInt(g.at[1])+g.height|g<-fs]);
              f.fillColor = "red";
              IFigure r =
               _overlay("<f.id>", f
                , [_shape("<f.id>_shape", shape(vs, id = "<f.id>_shape", width = f.width, height = f.height, yReverse = false
                   ,lineColor=f.pathColor, lineWidth = f.lineWidth, fillColor="none"
                   , visibility = f.visibility))]
                 + 
                ifs
                );
               return r;        
        }
        case d3Pack(): {
             str w  = toJSON(toMap(f.d),true); 
             IFigure r = _d3Pack(f.id, f, w);
             return r;
             }
        case d3Treemap(): {
             str w  = toJSON(toMap(f.d),true); 
             IFigure r = _d3Treemap(f.id, f, w);
             return r;
             }
        case d3Tree(): {
             str w  = toJSON(toMap(f.d),true); 
             // println(w);
             IFigure r = _d3Tree(f.id, f, [], [], w);
             return r;
             }
       case d3Tree(Figure root): {
             DDD d = treeToDDD(root);
             list[Figure] fs = treeToList(root);
             list[IFigure] ifs =  [_translate(q, addSvgTag = true)|Figure q<-fs]; 
             list[str] ids = [q.id|q<-fs]; 
             str w  = toJSON(toMap(d),true); 
             // println(w);  
             IFigure r = _d3Tree(f.id, f, ids, ifs, w);
             return r;
             }
       }
    }

list[Figure] treeToList(Figure f) {
    if (tree(Figure root, Figures figs):=f) {
       list[Figure] r= [root];
       r+= [*treeToList(b)|Figure b<-figs];
       return r;
       }
    return [f];
    }
    
DDD treeToDDD(Figure f) {
    if (tree(Figure root, Figures figs):=f) {
       DDD r= ddd(name=root.id, children = [treeToDDD(b)|Figure b<-figs]);
       return r;
       }
    return ddd(name=f.id);
    }
    
 bool isEmpty(Figure f) {
    switch (f) {
        case g:box(): return g.fig == emptyFigure();
        case g:ellipse():return  g.fig == emptyFigure();
        case g:circle():return  g.fig == emptyFigure();
        case g:ngon(): return  g.fig == emptyFigure();
        case g:hcat(): return isEmpty(g.figs);
        case g:vcat(): return isEmpty(g.figs);
        case g:grid(): return isEmpty(g.figArray);   
        case g:atXY(_, _, fg):  return isEmpty(fg);
        case g:atXY(_, fg):  return isEmpty(fg);
        case g:atX(_, fg):  return isEmpty(fg);
        case g:atY(_, fg):  return isEmpty(fg);
        case g:rotateDeg(_, fg):   isEmpty(fg);
        case g:rotateDeg(_, _, _, fg):  isEmpty(fg);
        }
        return false;
     } 
 
     
public void _render(Figure f..., int width = -1, int height = -1, 
     Alignment align = centerMid, tuple[int, int] size = <0, 0>,
     str fillColor = "white", str lineColor = "black", 
     int lineWidth = 1, bool display = true, real lineOpacity = 1.0, real fillOpacity = 1.0
     , Event event = noEvent(), int borderWidth = -1, str borderStyle= "", str borderColor = ""
     , bool resizable = true,
     bool defined = false, str cssFile = "")
     {    
        id = 0;
        if (size != <0, 0>) {
            width = size[0];
            height = size[1];
         }
        clearWidget();  
        Figure h = emptyFigure();
        h.lineWidth = lineWidth<0?1:lineWidth;
        h.fillColor = fillColor;
        h.lineColor = lineColor;
        h.lineOpacity = lineOpacity;
        h.fillOpacity = fillOpacity;
        h.visibility = "inherit";
        h.resizable = resizable;
        h.align = align;
        h.id = "figureArea";
        figMap[h.id] = h;
        fig=[];
        int i = 0;  
        screen.width = width; screen.height = height;
      for (Figure fig1<-f) {
        if (atXY(_, _, _):= fig1 || atX(_,_):=fig1 || atY(_,_):=fig1){
             align = topLeft; 
             fig1=overlay(figs=[fig1]);
             }  
        if (fig1.size != <0, 0>) {
            fig1.width = fig1.size[0];
            fig1.height = fig1.size[1];
            }     
        if (fig1.shrink?) {
            fig1.hshrink = fig1.shrink;
            fig1.vshrink = fig1.shrink;
            }
        if (fig1.grow?) {
            fig1.hgrow = fig1.grow;
            fig1.vgrow = fig1.grow;
            }
        str qid = "<h.id><i>";
        fig1= buildFigMap(fig1);
        parentMap[fig1.id] = h.id; 
        buildParentTree(fig1);
        IFigure z = _translate(fig1);
        figMap[qid] = emptyFigure();
        figMap[qid].print =  fig1.print;
        addState(fig1);
        _render(qid, z , align = align, fillColor = fillColor, lineColor = lineColor,
        borderWidth = borderWidth, borderStyle = borderStyle, borderColor = borderColor, display = display, event = event
        , resizable = resizable,
        defined = defined, cssFile = cssFile, print = fig1.print);
        i = i +1;
       }
     }
     
  //public void main() {
 //   clearWidget();
 //   IFigure fig0 = _rect("asbak",  emptyFigure(), fillColor = "antiquewhite", width = 50, height = 50, align = centerMid);
 //   _render(fig0);
 //   }
    
