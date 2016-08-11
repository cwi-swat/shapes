module shapes::examples::Shapes
import shapes::FigureServer;
import shapes::Figure;
import shapes::Render;
import Prelude;



public Figure diamond(int width, int height, str txt, str color) = 
overlay(width=width, height = height, figs=[
   // box(fig=
   polygon(lineWidth = 1, width = width, height = height, points=[<0, 0.5>, <0.5, 0>, <1, 0.5>, <0.5, 1>], scaleX=<<0, 1>, <0, width>>, scaleY=<<0, 1>, <0, height>>, fillColor=color)
   // )
     ,box(width = width, height = height, lineWidth = 0, fig = text(txt), fillColor="none")
   ])
   ;

public void tdiamond() = render(diamond(200, 100, "aap", "lightyellow"), lineWidth = 0);

public void fdiamond(loc l) = writeFile(l, toHtmlString(diamond(400, 200, "aap", "lightyellow")));


public Figure hArrow(int width, int height, str color)  {
    num d = 0.05;
    num x = 0.2;
    list[tuple[num, num]] p  = [<0, 0.5-d>, <0,0.5+d>, <1-x, 0.5+d>, <1-x, 1>, <1, 0.5>, <1-x, 0>, <1-x, 0.5-d>];
    return 
    // box(lineWidth = 0, fig=
    polygon(lineWidth = 0, width = width, height = height, points=p, scaleX=<<0, 1>, <0, width>>, scaleY=<<0, 1>, <0, height>>, fillColor=color)
    // )
    ;
    }
    
public Figure vArrow(int width, int height, str color)  {
    num d = 0.05;
    num x = 0.2;
    list[tuple[num, num]] p  = [<0.5-d, 0>, <0.5+d, 0>, <0.5+d, 1-x>, <1, 1-x>, <0.5, 1>, <0, 1-x>, <0.5-d, 1-x>];
    return // box(lineWidth = 0, fig=
    polygon(lineWidth = 0, width = width, height = height, points=p, scaleX=<<0, 1>, <0, width>>, scaleY=<<0, 1>, <0, height>>, fillColor=color)
    // )
    ;
    }

public void thArrow() = render(hArrow(100, 25, "lime"), lineWidth = 0);

public void tvArrow() = render(vArrow(25, 100, "brown"), lineWidth = 0);

public Figure action(str lab) = box(grow=1.2, fig = text(lab), fillColor = "lightgreen", rounded=<10, 10>, lineWidth = 0);

public Figure begin(int width, int height, str lab) = box(size=<width, height>, fig = htmlText(lab), fillColor = "lightpink", rounded=<10, 10>, lineWidth = 0);

public Figure end(int width, int height, str lab) = box(size=<width, height>, fig = text(lab), fillColor = "lightgreen", rounded=<10, 10>, lineWidth = 0);

public Figure decision() {
   int width = 150;
   int height = 100;
   int h = 20;
   int w = 50;
   int h1 =50;
   int w1 = 20; 
   int h0 = 40;
   int offs = h0+h1;
   return overlay(size=<400, 600>, figs=[
                        begin(width, h0, "Lamp doesn\'t work")
                      , atXY((width-w1)/2, h0, vArrow(w1, h1, "brown"))
                      , atXY(0, offs, diamond(width, height, "Lamp\<br\> plugged in?", "lightyellow"))
                      , atXY(width, offs+(height-h)/2, hArrow(w, h, "brown"))
                      , atXY((width-w1)/2,offs+height, vArrow(w1, h1, "brown"))
                      , atXY(0, offs+height+h1, diamond(width, height, "Bulb\<br\>burned out?", "lightyellow"))
                      , atXY(width, offs+height+ h1 + (height-h)/2, hArrow(w, h, "brown"))
                      , atXY((width-w1)/2, offs+2*height+ h1, vArrow(w1, h1, "brown"))
                      , atXY(width+w, offs+(height-h)/2, action("Plugin lamp"))
                      , atXY(width+w, offs+height+h1+(height-h)/2, action("Replace bulb"))
                      , atXY(0,  offs+2*height+ 2*h1, end(width, h0, "Repair Lamp"))
                      ]);
   }

public void tdecision() = render(decision());

Figure triangle(int alpha) = rotateDeg(alpha, 100, 100,  
         shape([move(25, 34), line(25, -34), line(17, -38.2), line(17, 20), line(-17.6, 0)]
          ,scaleX=<<-50, 50>, <0, 200>>, scaleY=<<-50, 50>, <0, 200>>
         )
         )
         ;
         
Figure triangle() = overlay(figs=[triangle(0), triangle(120), triangle(-120)], size=<200, 200>);
         
void ttriangle() = render(triangle());

void ftriangle(loc f) = writeFile(f, toHtmlString(triangle(0)));  

Figure n1 = box(fillColor = "palegreen", grow = 1.2, lineWidth=2, fig=text("Solve (sub)problem"));

Figure n2 = box(fillColor = "palegreen", grow = 1.2, lineWidth=2, fig=text("Validate results"));

Figure n3 = diamond(120, 70, "acceptable?", "lightskyblue");

Figure n4 = ellipse(grow=1.5, fig= text("Improve"), fillColor = "lightyellow");

list[tuple[str, Figure]] dnodes = [<"A", n1>, <"B", n2>, <"C", n3>, <"D", n4>];

list[Edge] dedges = [edge("A", "B"), edge("B", "C"),  edge("C", "D"), edge("D", "A")];

Figure dgram() = box(grow=1.2, fig=graph(nodes=dnodes, edges=dedges, size=<300, 300>));

void tdgram() = render(dgram());

void fdgram(loc f) = writeFile(f, toHtmlString(dgram())); 
