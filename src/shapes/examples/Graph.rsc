module shapes::examples::Graph
import shapes::FigureServer;
import shapes::Figure; 
import shapes::examples::Steden; 
import Prelude;
import shapes::Render;


public Figure fsm(){
	Figure b(str label) =  box( fig=text(label, fontWeight="bold"), fillColor="whitesmoke", rounded=<5,5>, padding=<0,6, 0, 6>, tooltip = label
	                                          ,id = newName()
	                                          );	                                          
    list[tuple[str, Figure]] states = [ 	
                <"CLOSED", 		ngon(n=6, r = 40, fig=text("CLOSED", fontWeight="bold"), fillColor="#f77", rounded=<5,5>, padding=<0, 5,0, 5>, tooltip = "CLOSED", id = newName())>, 
    			<"LISTEN", 		b("LISTEN")>,
    			<"SYN RCVD", 	b("SYN RCVD")>,
				<"SYN SENT", 	b("SYN SENT")>,
                <"ESTAB",	 	box(size=<100, 30>, fig=text("ESTAB",fontWeight="bold"), fillColor="#7f7", rounded=<5,5>, padding=<0, 5,0, 5>, tooltip = "ESTAB", id = newName())>,
                <"FINWAIT-1", 	b("FINWAIT-1")>,
                <"CLOSE WAIT", 	box(size=<120, 30>, fig=text("CLOSE WAIT",fontWeight="bold"), fillColor="antiquewhite", lineDashing=[1,1,1,1],  rounded=<5,5>, padding=<0, 5,0, 5>, tooltip = "CLOSE_WAIT"
                , id = newName())>,
                <"FINWAIT-2", 	b("FINWAIT-2")>,    
                <"CLOSING", b("CLOSING")>,
                <"LAST-ACK", b("LAST-ACK")>,
                <"TIME WAIT", b("TIME WAIT")>
                ];
 	
    list[Edge] edges = [	edge("CLOSED", 		"LISTEN",  	 label="open", labelStyle="font-style:italic", id = newName()), 
    			edge("LISTEN",		"SYN RCVD",  label="rcv SYN", labelStyle="font-style:italic", id = newName()),
    			edge("LISTEN",		"SYN SENT",  label="send", labelStyle="font-style:italic", id = newName()),
    			edge("LISTEN",		"CLOSED",    label="close", labelStyle="font-style:italic", id = newName()),
    			edge("SYN RCVD", 	"FINWAIT-1", label="close", labelStyle="font-style:italic", id = newName()),
    			edge("SYN RCVD", 	"ESTAB",     label="rcv ACK of SYN", labelStyle="font-style:italic", id = newName()),
    			edge("SYN SENT",   	"SYN RCVD",  label="rcv SYN", labelStyle="font-style:italic", id = newName()),
   				edge("SYN SENT",   	"ESTAB",     label="rcv SYN, ACK", labelStyle="font-style:italic", id = newName()),
    			edge("SYN SENT",   	"CLOSED",    label="close", labelStyle="font-style:italic", id = newName()),
    			edge("ESTAB", 		"FINWAIT-1", label="close", labelStyle="font-style:italic", id = newName()),
    			edge("ESTAB", 		"CLOSE WAIT",label= "rcv FIN", labelStyle="font-style:italic", id = newName()),
    			edge("FINWAIT-1",  	"FINWAIT-2",  label="rcv ACK of FIN", labelStyle="font-style:italic", id = newName()),
    			edge("FINWAIT-1",  	"CLOSING",    label="rcv FIN", labelStyle="font-style:italic", id = newName()),
    			edge("CLOSE WAIT", 	"LAST-ACK",  label="close", labelStyle="font-style:italic", id = newName()),
    			edge("FINWAIT-2",  	"TIME WAIT",  label="rcv FIN", labelStyle="font-style:italic", id = newName()),
    			edge("CLOSING",    	"TIME WAIT",  label="rcv ACK of FIN", labelStyle="font-style:italic", id = newName()),
    			edge("LAST-ACK",   	"CLOSED",     label="rcv ACK of FIN", lineColor="green", labelStyle="font-style:italic", id = newName()),
    			edge("TIME WAIT",  	"CLOSED",     label="timeout=2MSL", labelStyle="font-style:italic", id = newName())
  			];
  	return graph(nodes=states, edges=edges, width = 700, height = 900);
}



  
Figure _bfsm() {Figure f = fsm(); return finalStateMachine(f, f.nodes[0][0]);}


public void bfsm() = render(_bfsm());

public void ffsm(loc l) = writeFile(l, toHtmlString(fsm()));

public Figure tree1() = tree(box(fillColor="red", size=<10, 10>), [box(size=<10, 10>, fillColor="green")]);
/*

public Figure shape1() = 
svg(shape([line(100,100), line(100,200), line(200,200)], 
    shapeClosed=true, startMarker=box(lineWidth=1, size=<50, 50>, fig = circle(r=3, fillColor="red"), fillColor="antiqueWhite")));
void tshape1(){	render(shape1()); }
void ftshape1(loc f){writeFile(f, toHtmlString(shape1()));}

Figure gbox1()= overlay(figs=[
          box(id="touch", fillColor="whitesmoke", lineWidth = 1, size=<60, 60>
               //,tooltip = tree(box(fillColor="red", size=<15, 15>),
               //     [box(fillColor="blue", size=<10, 10>)])
               , tooltip = box(fillColor = "red", size=<20, 20>)
               )
          ,box(id="inner", fillColor="yellow", size=<25, 25>)]
        )
        ;

void tgbox1() = render(gbox1());

Figure grap() = graph(nodes=[
<"a", gbox1()>
, <"b"
     // , overlay(figs=[
         , box(id = "ttip", size=<60, 60> 
         //  ,tooltip= tree1() 
           , tooltip=vcat(figs=[box(size=<50, 50>, fillColor="blue"), box(size=<50, 50>, fillColor="antiquewhite")])
          , fig = text("Hallo")
       ,  rounded=<15, 15>, fillColor = "antiquewhite")
        >
, <"c", box(id=  "ap"// , fig = text("HALLO")
, fillColor = "pink", size=<50, 50>
      // , tooltip=vcat(figs=[box(size=<50, 50>, fillColor="blue")])
        , tooltip = steden()
)>
// , <"d", ngon(n=3, r= 30, size=<50, 50>, fillColor = "lightgreen")>
]
, edges=[edge("a", "b"/*
// , lineInterpolate="basis")
, edge("b","c", lineInterpolate="basis"), edge("c", "a", lineInterpolate="basis")

// , edge("d", "a")
], width = 150, height = 300);

void tgrap() = render(grap());

void fgrap(loc l) = writeFile(l, toHtmlString(grap()));


void tgraph()= render(hcat(hgap=5, figs = [gbox1(), box(grow=1.0,  fig=grap())
   , rangeInput(low = 0.0, val = 1.0, high = 2.0, step=0.1, event=on("change", void(str e, str n, real v)
            {
               println(v);
                attr("aap", grow = v);
            }))
   ], align = centerMid), align = centerMid);
// render(overlay(figs=[grap(), box(size=<40, 40>)]));

void fgraph(loc l) = writeFile(l, toHtmlString(hcat(hgap=5, figs = [gbox1(), grap()])));

// Figure tri(bool tt) = tt?vcat(figs=[text("aap"), text("noot")]):box(fig=text("noot", fontColor="black"));

Figure tri(bool tt) = //box(fig=
hcat(figs=[box(fig=text("aap"))])
// )
;

// Figure tri(bool tt) = box(fig=text("aap"));

Figure mbox(str txt, bool tt) =box(fig=
vcat(figs=[box(fillColor="yellow", grow = 3.0, lineWidth = 2, fig=text(txt)
   
  )]) , tooltip = tri(tt)
)
;

Figure model() = graph([<"a", mbox("Figure", false)>                    
                       , <"b",mbox("This", true)>
                       , <"c", mbox("Widget", true)>                 
                       ]
                       , [edge("a", "b"), edge("b", "c")]
                       , width = 250, height = 300, lineWidth = 0, align = centerMid);
                        
void tmodel()= render(model(), align = centerMid);

Figure t(str s) = box(fig=text(s, fontSize=20, fontColor="green"), fillColor = "yellow");


Figure g() = box(size=<1000, 1000>, align = centerRight, fig=
   graph(nodeProperty=(),width=1000,height=1000,nodes=
   [<"Exception",box(tooltip=t("Exception"), fig = text("Exception", fontColor="blue", fontSize=20))>
   ,<"experiments::Compiler::Examples::RascalExtraction",box(tooltip=t("experiments::Compiler::Examples::RascalExtraction"),fig=text("RascalExtraction",fontSize=12))>
   ,<"IO",box(tooltip=t("IO"),fig=text("IO",fontSize=12))>
   ,<"Message",box(tooltip=t("Message"),fig=text("Message",fontSize=12))>
   ,<"Type",box(tooltip=t("Type"),fig=text("Type",fontSize=12))>
   ,<"Map",box(tooltip=t("Map"),fig=text("Map",fontSize=12))>
  ,<"ParseTree",box(tooltip=t("ParseTree"),fig=text("ParseTree",fontSize=12))>
   ,<"util::Benchmark",box(tooltip=t("util::Benchmark"),fig=text("Benchmark",fontSize=12))>
  ,<"util::Reflective",box(tooltip=t("util::Reflective"),fig=text("Reflective",fontSize=12))>
  ,<"ValueIO",box(tooltip=t("ValueIO"),fig=text("ValueIO",fontSize=12))>
  ,<"List",box(tooltip=t("List"),fig=text("List",fontSize=12))>
  ,<"lang::rascal::syntax::Rascal",box(tooltip=t("lang::rascal::syntax::Rascal"),fig=text("Rascal",fontSize=12))>
    ]
   ,lineWidth=1
   ,edges=[
    edge("util::Reflective","Exception")
   ,edge("experiments::Compiler::Examples::RascalExtraction","util::Reflective")
   ,edge("experiments::Compiler::Examples::RascalExtraction","util::Benchmark")
   ,edge("IO","Exception"),edge("List","IO")
   ,edge("List","Map"),edge("ValueIO","Type"),edge("ValueIO","Exception")
   ,edge("ParseTree","Type"),edge("ParseTree","Exception")
   ,edge("util::Benchmark","Exception"),edge("experiments::Compiler::Examples::RascalExtraction","ParseTree")
   ,edge("experiments::Compiler::Examples::RascalExtraction","ValueIO")
   ,edge("experiments::Compiler::Examples::RascalExtraction","IO")
   ,edge("Map","Exception"),edge("util::Reflective","lang::rascal::syntax::Rascal")
   ,edge("lang::rascal::syntax::Rascal","Exception"),edge("util::Reflective","Message")
   ,edge("List","Exception"),edge("ParseTree","Message"),edge("Type","Exception")
   ,edge("util::Benchmark","IO"),edge("experiments::Compiler::Examples::RascalExtraction","Exception")
   ,edge("Message","Exception"),edge("Type","List"),edge("util::Reflective","ParseTree")
   ,edge("util::Reflective","IO"),edge("experiments::Compiler::Examples::RascalExtraction","lang::rascal::syntax::Rascal")
   ,edge("ParseTree","List")
   ],options=graphOptions()),align=<0.0,0.0>,lineWidth=0); 

   void tg()= render(g(), size=<1000, 1000>, align = centerMid);
   
   Figure k33() {
        list[tuple[str, Figure]] nodes = [<"<i>", circle(r=15, fig=text("<i>"))>|int i<-[0..6]];
        list[Edge] edges = [edge("0","3", lineInterpolate="step-after"), edge("0", "4"), edge("0", "5")
                           ,edge("1","3"), edge("1", "4"),  edge("1", "5")
                           ,edge("2","3"), edge("2", "4"), edge("2", "5")
                           ];
       return graph(nodes=nodes, edges=edges, size=<500, 500>);                        
       }
  
 void tk33()= render(k33(), size=<1000, 1000>, align = centerMid); 
 
 void fk33(loc l) = writeFile(l, toHtmlString(k33())); 
 
 Figure  g1() = graph( [<"a",hcat(figs=[box(size=<25, 25>)])>, <"b",box("B", 14, "red", 1.2, "beige")>], [edge("a", "b")], size=<200, 200>);
 
 public void tg1() = render(g1());
 
 public void tsteden() = render(box(fillColor="beige", size=<1000, 1000>, fig = at(500, 500, steden())));
 */
 