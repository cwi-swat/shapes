module shapes::examples::Flower
import shapes::FigureServer;
import shapes::Figure;
import shapes::Render;
import util::Math;
import Prelude;

Vertices flowShape1(num d) = [line(x-d*x*(1-x), x+d*x*(1-x))| x<-[0.1,0.2..1.1]];
     
Vertices flowShape2(num d) = [line(x+d*x*(1-x), x-d*x*(1-x))| x<-[1,0.9..0]];

Figure leaf(int a) {
    int w = 50; int h = 50;
    num d = 0.5*sqrt(2);
    return 
           rotateDeg(a, 
           box(size=<w, h>, 
            fig = shape([move(0,0)]+flowShape1(0.5)+flowShape2(0.5)
           ,scaleX=<<0,1>,<(1-d)/2*w, (1+d)/2*w>>, scaleY=<<0,1>,<(1-d)/2*h,(1+d)/2*h>> , shapeCurved= false, fillColor= "red")
           ,align= centerMid, fillColor = "none", lineColor = "none")
           );
        }

Figure flower() {
    int n  = 16;
    int r = 40;
    list[Figure] fs = 
    [atXY(r+toInt(r*sin(p)), r+toInt(r*cos(p)), leaf(45-toInt((180*p)/PI())))|real p<-[0,2*PI()/n..2*PI()]]
    +atXY(25, 25, box(lineWidth =0, size=<2*r, 2*r>, align = centerMid, lineColor="none", fillColor="none", fig=circle(r=0.6*r
    , fillColor = "yellow", fillOpacity=0.7, fig = circle(r=0.1*r, lineColor="none", fillColor="green"))))
    ;
    return overlay(size=<150, 150>, lineWidth = 0, figs=fs);
    }
    
void tflower() = render(flower(), size=<400, 400>,  borderWidth = 1);

void tleaf()=render(overlay(figs=[leaf(0), atXY(100, 10, leaf(90))]));


Figure scheme() =  hcat(figs=[
             vcat(lineWidth=0, figs=[box(size=<200, 40>, align = centerMid, lineWidth = 0, fig=text("Figure",fontWeight= "bold"))
                     , box(lineWidth = 0, size=<200, 200>, fig=graph( [
                        <"a", box(fig=text("vcat"), lineWidth=1, rounded=<10, 10>)>
                        ,<"b", box(fig=text("box"), lineWidth=1, rounded=<10, 10>)>
                        ,<"c", box(fig=text("text"), lineWidth=1, rounded=<10, 10>)>
                        ,<"d", box(fig=text("graph"), lineWidth=1, rounded=<10, 10>)>
                        ], [edge("a", "b"), edge("b","c"),
                            edge("a", "d")
                           ] , size=<200, 200>, lineWidth = 0
                        ))])
             ,vcat(lineWidth=0, figs=[box(size=<200, 40>, align = centerMid, lineWidth = 0, fig=text("IFigure",fontWeight= "bold"))
                     , box(lineWidth = 0, size=<200, 200>, fig=graph( [
                        <"a", box(fig=text("id=i1"), lineWidth=1, rounded=<10, 10>)>
                        ,<"b", box(fig=text("id=i2"), lineWidth=1, rounded=<10, 10>)>
                        ,<"c", box(fig=text("id=i3"), lineWidth=1, rounded=<10, 10>)>
                        ,<"d", box(fig=text("id=i4"), lineWidth=1, rounded=<10, 10>)>
                        ], [edge("a", "b"), edge("b","c"),
                            edge("a", "d")
                           ] , size=<200, 200>, lineWidth = 0
                        ))])
              ,table()
                   ]);
                   
   Figure table() = vcat(vgap=0, borderStyle="ridge",  borderColor="grey", borderWidth = 1, figs = 
                        [box(size=<200, 40>, lineWidth = 0
                         , fig = text("Widget", fontWeight = "bold"))
                         ,hcat(hgap=0,borderStyle="ridge", borderWidth = 4, figs =
                            [text("id1", size=<30,15>)
                            ,text("align", size=<60,15>, fontStyle = "italic")
                            ,text("width", size=<60,15>, fontStyle = "italic")
                            ,text("height", size=<60,15>, fontStyle = "italic")
                            ,text("html", size=<65,15>, fontStyle = "italic")
                            ]
                            )
                        ,hcat(hgap=0, borderStyle="ridge",  borderWidth = 4, figs =
                            [text("id2", size=<30,15>)
                            ,text("align", size=<60,15>, fontStyle = "italic")
                            ,text("width", size=<60,15>, fontStyle = "italic")
                            ,text("height", size=<60,15>, fontStyle = "italic")
                            ,text("html", size=<65,15>, fontStyle = "italic")
                            ]
                            )
                        ,hcat(hgap=0,borderStyle="ridge",  borderWidth = 4, figs =
                            [text("id3", size=<30,15>)
                            ,text("align", size=<60,15>, fontStyle = "italic")
                            ,text("width", size=<60,15>, fontStyle = "italic")
                            ,text("height", size=<60,15>, fontStyle = "italic")
                            ,text("html", size=<65,15>, fontStyle = "italic")
                            ]
                            )
                         ,hcat(hgap=0, borderStyle="ridge",  borderWidth = 4, figs =
                            [text("id4", size=<30,15>)
                            ,text("align", size=<60,15>, fontStyle = "italic")
                            ,text("width", size=<60,15>, fontStyle = "italic")
                            ,text("height", size=<60,15>, fontStyle = "italic")
                            ,text("html", size=<65,15>, fontStyle = "italic")
                            ]
                            )
                         ]);
                        
void tscheme() = render(scheme(),  lineWidth = 0);  

void fscheme(loc f) = writeFile(f, toHtmlString(scheme()));               