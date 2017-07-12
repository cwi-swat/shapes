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
    
//  | doWhile(Statement body, Expression \test)
// functionDecl(str id, list[Identifier] params, list[Statement] statBody, bool generator)
// forIn(list[VariableDeclarator] decls, str kind, Expression right,Statement body)
// forIn(Expression left, Expression right, Statement body)

Statement buildStatement(node _statement) {
    switch(_statement.\type)  {
     case "VariableDeclaration": 
      if (list[node] variableDeclarators:=_statement.declarations 
         && str kind:= _statement.kind) 
        return 
         Statement::varDecl([buildVariableDeclarator(variableDeclarator)|variableDeclarator<-variableDeclarators], kind);
     case "FunctionDeclaration":
         if (node id := _statement.id && list[node] params := _statement.params && node body :=  _statement.body
             && bool generator := _statement.generator && list[node] stats:=body.body && str name := id.name) {
               return functionDecl(name, [buildIdentifier(v)|node v<-params], [buildStatement(stat)|stat<-stats], generator);
               }
     case "ExpressionStatement": 
        if (node _expression:=_statement.expression)  return Statement::expression(buildExpression(_expression));
     case "EmptyStatement": return Statement::empty();
     case "BlockStatement": 
      if (list[node] stats:=_statement.body)
        return 
         Statement::block([buildStatement(stat)|stat<-stats]);  
     case "IfStatement":  
        if (node condition:=_statement.\test && node consequent:=_statement.consequent)
          if (_statement.alternate?) {
               if (node alternate :=_statement.alternate)
                  return Statement::\if(buildExpression(condition), buildStatement(consequent), buildStatement(alternate));
            }
          else 
            return Statement::\if(buildExpression(condition), buildStatement(consequent)); 
     case "ForStatement": {
        ForInit forInit = ForInit::none(); 
        if (_statement.init? && node init := _statement.init) {
              if (init.\type=="VariableDeclaration" && list[node] variableDeclarators:= init.declarations 
                     && str kind:= init.kind) {
              forInit = 
              ForInit::varDecl([buildVariableDeclarator(variableDeclarator)|variableDeclarator<-variableDeclarators], kind);
              }
              else forInit = ForInit::expression(buildExpression(init));
              } 
        Expression condition = undefined();
        if (_statement.\test? && node _condition := _statement.\test) {
           condition = buildExpression(_condition);
           }
        Expression update = undefined();
        if (_statement.\update? && node _update := _statement.\update) {
           update = buildExpression(_update);
           }
        if (node body := _statement.body) {
           return \for(forInit, condition, buildStatement(body), update);
           }  
        }
     case "ForInStatement": {
        if (node _right := _statement.right && node body := _statement.body)
        if (node _left := _statement.left) {
              if (_left.\type=="VariableDeclaration" && list[node] variableDeclarators:= _left.declarations 
                     && str kind:= _left.kind) {
                return forIn([buildVariableDeclarator(variableDeclarator)|variableDeclarator<-variableDeclarators], kind 
                ,buildExpression(_right), buildStatement(body));
              }
            return forIn(buildExpression(_left),buildExpression(_right),buildStatement(body));
            } 
        }
     case "WhileStatement": {
        if( node condition := _statement.\test && node body:=_statement.body)
           return \while(buildExpression(condition), buildStatement(body));
        }
     case "DoWhileStatement": {
        if( node condition := _statement.\test && node body:=_statement.body)
           return dowhile(buildExpression(condition), buildStatement(body));
        }  
     case "ReturnStatement": {
        if (_statement.argument? && node argument := _statement.argument)
          return \return(buildExpression(argument));
        return(\return());
        }
     case "BreakStatement": {
        if (_statement.label? && node label := _statement.label && str name:=label.name)
          return \break(name);
        return(\break());
        }
      case "ContinueStatement": {
        if (_statement.label? && node label := _statement.label && str name:=label.name)
          return \continue(name);
        return(\continue());
        }
      }
     println(_statement.\type);      
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
//member(Expression object, str strProperty)
//  member(Expression object, Expression expProperty)
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
         case "BooleanLiteral": {
            if (bool v := _expression.\value)
               return literal(boolean(v)); 
            }
        case "NullLiteral": return literal(null()); 
        case "StringLiteral": {
            if (str v := _expression.\value)
               return literal(string(v)); 
            }
        case "ThisExpression": return this();
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
                  return Expression::array([buildExpression(element)|node element<-elements]);
        case "ObjectExpression":
             if (list[node] properties:= _expression.properties)
                  return object([buildObjectProperty(property)|node property<-properties]);   
        case "FunctionExpression":
         if (list[node] params := _expression.params && node body :=  _expression.body
             && bool generator := _expression.generator && list[node] stats:=body.body) {
             if (_expression.id? && node id := _expression.id && id.name? && str name := id.name)
               return Expression::function(name, [buildIdentifier(v)|node v<-params], [buildStatement(stat)|stat<-stats], generator);
             return Expression::function("", [buildIdentifier(v)|node v<-params], [buildStatement(stat)|stat<-stats], generator);
              } 
         case "MemberExpression": {
            if (node object:=_expression.object 
             && node property:=_expression.property 
             && bool computed:=_expression.computed) {
             if (computed) {
                return member(buildExpression(object), buildExpression(property));
                }
              if (str name:=property.name) return member(buildExpression(object), name); 
              } 
             }           
        } 
    println(_expression.\type);                       
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

LogicalOperator buildLogicalOperator(str operator) {
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
  | \for(ForInit init, Expression condition, Statement body, Expression update) // exps contains test, update
  | forIn(list[VariableDeclarator] decls, str kind, Expression right,Statement body)
  | forIn(Expression left, Expression right, Statement body)
  | forOf(list[VariableDeclarator] decls, str kind, Expression right, Statement body)
  | forOf(Expression left, Expression right, Statement body)
  | let(list[tuple[Pattern id, Init init]] inits, Statement body)
  | debugger()
  | functionDecl(str id, list[Identifier] params, list[Statement] statBody, bool generator)
 //  | functionDecl(str id, list[Pattern] params, list[Expression] defaults, str rest, Expression expBody, bool generator)
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
  | function(str id, list[Identifier] params, list[Statement] statBody, bool generator)
            //bool generator = false)
  //| function(str name, // "" = null
  //          list[Pattern] params,
  //          list[Expression] defaults,
  //          str rest, // "" = null
  //          Expression expBody)
            //,
            //bool generator = false)
  //| arrow(list[Pattern] params,
  //list[Expression] defaults,
  //          str rest, // "" = null
  //          list[Statement] statBody)
  //| arrow(list[Pattern] params,
  //list[Expression] defaults,
  //          str rest, // "" = null
  //          Expression expBody)
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
