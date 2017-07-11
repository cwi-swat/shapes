module org::rascalmpl::library::lang::javascript::m3::AST

extend analysis::m3::AST;
import IO;
import Set;
import String;
import List;
import Node;
import lang::json::IO;

value startBuild() {
   loc src = |file:///ufs/bertl/node/data.json|;
   node v = readJSON(#node, src, implicitConstructors = true, implicitNodes = true);
   // println(v);
   return build(v);
}

Program build(node file) {
   if (node program:=file.program) return buildProgram(file.program);
   }

Program buildProgram(node _program) {
    if (list[node] statements:=_program.body)
           return program([buildStatement(statement)|statement<-statements]);
    }
 //  block(list[Statement] stats)
 
// \if(Expression \test, Statement consequent, Statement alternate)
//   \if(Expression \test, Statement consequent)  
Statement buildStatement(node _statement) {
    switch(_statement.\type)  {
     case "VariableDeclaration": 
      if (list[node] variableDeclarators:=_statement.declarations 
         && str kind:= _statement.kind) 
        return 
         Statement::varDecl([buildVariableDeclarator(variableDeclarator)|variableDeclarator<-variableDeclarators], kind);
     case "ExpressionStatement": 
        if (node _expression:=_statement.expression)  return Statement::expression(buildExpression(_expression));
     case "EmptyStatement": return Statement::empty();
     case "BlockStatement": 
      if (list[node] stats:=_statement.body)
        return 
         Statement::block([buildStatement(stat)|stat<-stats]);   
     }     
    }
    
VariableDeclarator buildVariableDeclarator(node _variableDeclarator) {
    if (node id:=_variableDeclarator.id)
    return variableDeclarator(buildIdentifier(id), buildInit(_variableDeclarator)); 
    }
    
Identifier buildIdentifier(node id) {
    if (str name:=id.name)
    return identifier(name);
    }
    
Init buildInit(node _variableDeclarator) {
    if (_variableDeclarator.init?) return Init::expression(buildExpression(_variableDeclarator.init));
    return Init::none();
    }
    
tuple[LitOrId key, Expression \value, str kind]  buildObjectProperty(node _objectProperty) {
    if (node key:=_objectProperty.key && node val := _objectProperty.\value) {
        //println(key.\type);
        // if (key.\type=="StringLiteral")  println(val.\value);
        if (key.\type=="Identifier" && str name := key.name)
                 return <LitOrId::id(name), buildExpression(val), "">; 
        if (key.\type=="StringLiteral" && str name := key.\value)  
                 return <LitOrId::lit(string(name)), buildExpression(val), "">; 
        }      
    }

Expression buildExpression(node _expression) {
    switch(_expression.\type)  {
        case "BinaryExpression": 
            if (node left:=_expression.left 
             && node right:=_expression.right 
             && str operator:=_expression.operator)
              return binaryExpression(buildExpression(left), buildBinaryOperator(operator), buildExpression(right));
        case "LogicalExpression": 
            if (node left:=_expression.left 
             && node right:=_expression.right 
             && str operator:=_expression.operator)
              return logical(buildExpression(left), buildLogicalOperator(operator), buildExpression(right));
        case "ConditionalExpression": 
            if (node consequent:=_expression.consequent 
             && node alternate:=_expression.alternate 
             && node condition:=_expression.\test)
              return conditional(buildExpression(condition), buildExpression(consequent), buildExpression(alternate));
        case "UnaryExpression":
             if (bool prefix:=_expression.prefix && node argument:= _expression.argument 
                  && str operator:=_expression.operator)
                  return unary(buildUnaryOperator(operator), buildExpression(argument), prefix);
         case "UpdateExpression":
             if (bool prefix:=_expression.prefix && node argument:= _expression.argument 
                  && str operator:=_expression.operator)
                  return update(buildUpdateOperator(operator), buildExpression(argument), prefix);
        case "NumericLiteral": {
            if (num v := _expression.\value)
               return literal(number(v)); 
            }
        case "StringLiteral": {
            if (str v := _expression.\value)
               return literal(string(v)); 
            }
        case "Identifier": {
            if (str name:=_expression.name)
                 return Expression::variable(name);               
            } 
        case "AssignmentExpression": {
            if (node left := _expression.left &&  
                str operator := _expression.operator && node right:=_expression.right) {
                return assignment(buildExpression(left), buildAssignmentOperator(operator),  buildExpression(right));
                }
            }
        case "CallExpression":
             if (list[node] arguments:= _expression.arguments 
                  && node callee:=_expression.callee)
                  return call(buildExpression(callee), [buildExpression(argument)|node argument<-arguments]); 
        case "ArrayExpression":
             if (list[node] elements:= _expression.elements)
                  return array([buildExpression(element)|node element<-elements]);
        case "ObjectExpression":
             if (list[node] properties:= _expression.properties)
                  return object([buildObjectProperty(property)|node property<-properties]);                 
        }                        
    return literal(number(-1));
    }
    
 BinaryOperator buildBinaryOperator(str operator) {
   switch(operator) {
      case "==": return equals(); 
      case "!=":return notEquals();  
   case "===":return longEquals(); 
   case "!==":return longNotEquals();
   case "\<":return lt() ;
   case "\<=":return leq(); 
   case "\>":return gt(); 
   case "\>=":return geq();
   case "\<\<":return shiftLeft(); 
   case "\>\>":return shiftRight(); 
   case "\>\>\>":return longShiftRight();
   case "+":return BinaryOperator::plus(); 
   case "-":return BinaryOperator::min(); 
   case "*":return times();
   case "/": return div(); 
   case "%":return rem();
   case "|":return bitOr(); 
   case "^":return bitXor(); 
   case "&":return bitAnd() ;
   case "in":return \in();
   case "instanceof":return instanceOf();
    }
  }
  
  
AssignmentOperator buildAssignmentOperator(str operator) {
   switch(operator) {
      case "=": return assign();
      case "+=": return plusAssign();
      case "-=": return minAssign();
      case "*=": return  timesAssign() ;
      case  "/=": return divAssign();
      case  "%=": return remAssign();
      case "\<\<=": return shiftLeftAssign() ;
      case  "\>\>=": return iftRightAssign() ;
      case  "\>\>\>=": return longShiftRightAssign();
      case  "|=": return bitOrAssign();
      case  "^=": return bitXorAssign();
      case  "&=": return  bitAndAssign(); 
   }
}

/* "-" | "+" | "!" | "~" | "typeof" | "void" | "delete" */

/* min() | plus() | not() | bitNot() | typeOf() | \void() | delete();*/

UnaryOperator buildUnaryOperator(str operator) {
    switch(operator) {
       case "-": return UnaryOperator::min();
       case "+": return UnaryOperator::plus();
       case "!": return UnaryOperator::not();
       case "~": return UnaryOperator::bitNot();
       case "typeof": return UnaryOperator::typeOf();
       case "void": return UnaryOperator::\void();
       case "delete": return UnaryOperator::delete();
       }
    }
    
UpdateOperator buildUpdateOperator(str operator) {
    switch(operator) {
      case "++": return inc();
      case "--": return dec();
      }
   }

LogicalOperator buildUpdateOperator(str operator) {
    switch(operator) {
      case "&&": return LogicalOperator::and();
      case "||": return LogicalOperator::or();
      }
   }
 

data ErrorNode = errorNode(str error);

data Program
  = program(list[Statement] stats)
  ;

data ForInit
  = varDecl(list[VariableDeclarator] declarations, str kind)
  | expression(Expression exp)
  | none()
  ;

data Init
  = expression(Expression exp)
  | none()
  ;

data Statement
  = empty()
  | block(list[Statement] stats)
  | expression(Expression exp)
  | \if(Expression \test, Statement consequent, Statement alternate)
  | \if(Expression \test, Statement consequent)
  | labeled(str label, Statement stat)
  | \break()
  | \continue()
  | \break(str label)
  | \continue(str label)
  | with(Expression object, Statement stat)
  | \switch(Expression discriminant, list[SwitchCase] cases)
  | \return(Expression argument)
  | \return()
  | \throw(Expression argument)
  | \try(list[Statement] block, CatchClause handler, list[Statement]
finalizer)
  | \try(list[Statement] block, CatchClause handler)
  | \try(list[Statement] block, CatchClause handler, list[CatchClause]
guardedHandlers, list[Statement] finalizer)
  | \try(list[Statement] block, list[CatchClause] guardedHandlers,
list[Statement] finalizer)
  | \try(list[Statement] block,//tutor.rascal-mpl.org/Errors/Static/UndeclaredVariable/UndeclaredVariable.html|
   CatchClause handler, list[CatchClause]
guardedHandlers)
  | \try(list[Statement] block, list[CatchClause] guardedHandlers)
  | \while(Expression \test, Statement body)
  | doWhile(Statement body, Expression \test)
  | \for(ForInit init, list[Expression] exps, Statement body) // exps contains test, update
  | forIn(list[VariableDeclarator] decls, str kind, Expression right,Statement body)
  | forIn(Expression left, Expression right, Statement body)
  | forOf(list[VariableDeclarator] decls, str kind, Expression right, Statement body)
  | forOf(Expression left, Expression right, Statement body)
  | let(list[tuple[Pattern id, Init init]] inits, Statement body)
  | debugger()
  | functionDecl(str id, list[Pattern] params,
  list[Expression] defaults,
  str rest, // "" = null
  list[Statement] statBody,
  bool generator)
  | functionDecl(str id, list[Pattern] params,
  list[Expression] defaults,
  str rest, // "" = null
  Expression expBody,
  bool generator)
  | varDecl(list[VariableDeclarator] declarations, str kind)
  ;



data VariableDeclarator
  = variableDeclarator(Identifier id, Init init)
  ;

data LitOrId
  = id(str name)
  | lit(Literal \value)
  ;

data Expression
  = this()
  | array(list[Expression] elements)
  | object(list[tuple[LitOrId key, Expression \value, str kind]]
properties)
  | function(str name, // "" = null
            list[Pattern] params,
            list[Expression] defaults,
            str rest, // "" = null
            list[Statement] statBody) // ,
            //bool generator = false)
  | function(str name, // "" = null
            list[Pattern] params,
            list[Expression] defaults,
            str rest, // "" = null
            Expression expBody)
            //,
            //bool generator = false)
  | arrow(list[Pattern] params,
  list[Expression] defaults,
            str rest, // "" = null
            list[Statement] statBody)
  | arrow(list[Pattern] params,
  list[Expression] defaults,
            str rest, // "" = null
            Expression expBody)
  | sequence(list[Expression] expressions)
  | unary(UnaryOperator operator, Expression argument, bool prefix)
  | binaryExpression(Expression left, BinaryOperator binaryOp, Expression right)
  | assignment(Expression left, AssignmentOperator assignOp,  Expression right)
  | update(UpdateOperator updateOp, Expression argument, bool prefix)
  | logical(Expression left, LogicalOperator logicalOp,  Expression right)
  | conditional(Expression \test, Expression consequent, Expression
alternate)
  | new(Expression callee, list[Expression] arguments)
  | call(Expression callee, list[Expression] arguments)
  | member(Expression object, str strProperty)
  | member(Expression object, Expression expProperty)
  | yield(Expression argument)
  | yield()
  | comprehension(Expression expBody, list[ComprehensionBlock] blocks,
Expression \filter)
  | comprehension(Expression expBody, list[ComprehensionBlock] blocks)
  | generator(Expression expBody, list[ComprehensionBlock] blocks,
Expression \filter)
  | generator(Expression expBody, list[ComprehensionBlock] blocks)
  | graph(int index, Literal expression)
  | graphIndex(int index)
  | let(list[tuple[Pattern id, Init init]] inits, Expression expBody)
  // not in Spidermonkey's AST API?
  | variable(str name)
  | literal(Literal lit)
  | undefined()
  ;

data Pattern
  = object(list[tuple[LitOrId key, Pattern \value]] properties)
  | array(list[Pattern] elements) // elts contain null!
  | variable(str name)
  ;

data SwitchCase
  = switchCase(Expression \test, list[Statement] consequent)
  | switchCase(list[Statement] consequent)
  ;

data CatchClause
  = catchClause(Pattern param, Expression guard, list[Statement] statBody)
// blockstatement
  | catchClause(Pattern param, list[Statement] statBody) // blockstatement
  ;

data ComprehensionBlock
  = comprehensionBlock(Pattern left, Expression right, bool each = false);

data Literal
  = string(str strValue)
  | boolean(bool boolValue)
  | null()
  | number(num numValue)
  | regExp(str regexp)
  ;
  
data Identifier = identifier(str strValue);     

data UnaryOperator
  = min() | plus() | not() | bitNot() | typeOf() | \void() | delete();

data BinaryOperator
  = equals() | notEquals() | longEquals() | longNotEquals()
  | lt() | leq() | gt() | geq()
  | shiftLeft() | shiftRight() | longShiftRight()
  | plus() | min() | times() | div() | rem()
  | bitOr() | bitXor() | bitAnd() | \in()
  | instanceOf() | range()
  ;

data LogicalOperator
  = or() | and()
  ;

data AssignmentOperator
  = assign() | plusAssign() | minAssign() | timesAssign() | divAssign() |
remAssign()
  | shiftLeftAssign() | shiftRightAssign() | longShiftRightAssign()
  | bitOrAssign() | bitXorAssign() | bitAndAssign();

data UpdateOperator
  = inc() | dec()
  ;

/*
data Program
    = \program(list[Statement] statement, loc sourceLocation=|file://|)
    ;
    
data SourceLocation = sourceLocation(loc locValue);

data Expression 
    = \booleanLiteral(bool boolValue, loc sourceLocation=|file://|)
    | \stringLiteral(str stringValue, loc sourceLocation=|file://|)
    | \variable(str name, loc sourceLocation=|file://|)
    |  number(str numberValue, loc sourceLocation=|file://|)
    | \infix(Expression lhs, str operator, Expression rhs)
    ;                       
  
data Statement  = \expressionStatement(Expression expression)
    |declaration(variableDeclaration)
    ; 
    
data VariableDeclaration =   variableDeclaration(list[VariableDeclarator] variableDeclarators, str kind, loc sourceLocation=|file://|); 

data VariableDeclarator  =   variableDeclarator(Identifier identifier, loc sourceLocation=|file://|);  


*/  
