{
  function toBinaryExpr(left, rest) {
    return rest.reduce((acc, [op, right]) => ({
      type: "BinaryExpression",
      operator: op,
      left: acc,
      right
    }), left);
  }
}

Start
  = _ statements:StatementList? _ { return { type: "Program", body: statements || [] }; }

StatementList
  = head:Statement tail:(_ Statement)* {
      return [head, ...tail.map(([_, stmt]) => stmt)];
    }

Statement
  = VariableDeclaration
  / Assignment
  / IfStatement
  / WhileStatement
  / ExpressionStatement
  / InkDivert
  / InkTag
  / Comment

VariableDeclaration
  = "var" __ name:Identifier _ "=" _ value:Expression _ ";" {
      return { type: "VariableDeclaration", id: name, init: value };
    }

Assignment
  = name:Identifier _ "=" _ value:Expression _ ";" {
      return { type: "Assignment", id: name, value };
    }

IfStatement
  = "if" _ "(" _ test:Expression _ ")" _ "{" _ cons:StatementList? _ "}" _ elsePart:ElseClause? {
      return {
        type: "IfStatement",
        test,
        consequent: { type: "BlockStatement", body: cons || [] },
        alternate: elsePart || null
      };
    }

ElseClause
  = "else" _ "{" _ cons:StatementList? _ "}" {
      return { type: "BlockStatement", body: cons || [] };
    }

WhileStatement
  = "while" _ "(" _ test:Expression _ ")" _ "{" _ body:StatementList? _ "}" {
      return { type: "WhileStatement", test, body: { type: "BlockStatement", body: body || [] } };
    }

ExpressionStatement
  = expr:Expression _ ";" { return { type: "ExpressionStatement", expression: expr }; }

Expression
  = Logical

Logical
  = left:Comparison rest:(_ ("&&" / "||") _ Comparison)* {
      return toBinaryExpr(left, rest.map(([_, op, _, right]) => [op, right]));
    }

Comparison
  = left:Additive rest:(_ ("==" / "!=" / "<" / ">" / "<=" / ">=" / "===") _ Additive)* {
      return toBinaryExpr(left, rest.map(([_, op, _, right]) => [op, right]));
    }

Additive
  = left:Multiplicative rest:(_ ("+" / "-") _ Multiplicative)* {
      return toBinaryExpr(left, rest.map(([_, op, _, right]) => [op, right]));
    }

Multiplicative
  = left:Primary rest:(_ ("*" / "/" / "%") _ Primary)* {
      return toBinaryExpr(left, rest.map(([_, op, _, right]) => [op, right]));
    }

Primary
  = FunctionCall
  / Number
  / String
  / Boolean
  / Identifier
  / "(" _ expr:Expression _ ")" { return expr; }

FunctionCall
  = callee:Identifier _ "(" _ args:ArgumentList? _ ")" {
      return { type: "CallExpression", callee, arguments: args || [] };
    }

ArgumentList
  = first:Expression rest:(_ "," _ Expression)* {
      return [first, ...rest.map(([_, _, _, expr]) => expr)];
    }

InkDivert
  = "->" _ target:Identifier {
      return { type: "Divert", target };
    }

InkTag
  = "~" _ content:.* {
      return { type: "Tag", value: content.join("").trim() };
    }

Comment
  = "//" content:.* {
      return { type: "Comment", value: content.join("").trim() };
    }

Identifier
  = name:$(Letter (Letter / Digit)*) {
      return { type: "Identifier", name };
    }

Number
  = value:$([0-9]+ ("." [0-9]+)?) {
      return { type: "Literal", value: parseFloat(value) };
    }

String
  = "\"" chars:Char* "\"" {
      return { type: "Literal", value: chars.join("") };
    }

Char
  = !["\\] . / "\\" escapeChar:EscapeSequence { return escapeChar; }

EscapeSequence
  = "\"" { return "\"" }
  / "\\" { return "\\" }
  / "n"  { return "\n" }
  / "t"  { return "\t" }

Boolean
  = value:("true" / "false") {
      return { type: "Literal", value: value === "true" };
    }

Letter = [a-zA-Z_]
Digit = [0-9]

_  = [ \t\r\n]*
__ = [ \t\r\n]+
