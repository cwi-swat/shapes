module shapes::Poisson
import Prelude;
import shapes::FigureServer;
import shapes::Figure;
import shapes::Render;
import util::Math;

num sinI(int d) =  sin((toReal(d)/180)*PI());

num cosI(int d) =  cos((toReal(d)/180)*PI());


public list[Vertex] rline(int teta, int p, int n) {
    Vertex  p1 = move(-n*100*sinI(teta), n*100*cosI(teta));
    Vertex  p2 = line(n*100*sinI(teta), -n*100*cosI(teta));
    // println(teta);
    if (p!=0) {  
         if (teta==0) {
              p1 = move(p, -n*100);
              p2 = line(p, n*100);
              }
         else
         if (teta==90) {
              p1 = move(-n*100, p);
              p2 = line(n*100, p);
              }
         else {
            num x = p/sinI(teta);
            num y = p/cosI(teta);
            p1 = move(-n*x, (1+n)*y);  
            p2 = line((1+n)*x, -n*y); 
            }
         }
    return [p1, p2];
    }
    
bool flip() = arbInt(2)==0?true:false;

int flipInt() = flip()?1:-1;
    
int p  = 100;
    
public Figure rl() = overlay(figs=[circle(r=p, cx = 200, cy = 200, lineColor="red")
        , shape( rline(arbInt(180), flipInt()*p/*arbInt(p+1)*/, 500)
        , scaleX=<<-200, 200>, <0, 400>>
        , scaleY=<<-200, 200>, <0, 400>>
        , size=<400, 400>
        )|int i<-[0, 1 .. 500]]);

public void prl() {Figure f = rl(); render(f, borderWidth = 10, borderStyle = "ridge", borderColor = "grey", size=<400, 400>);}