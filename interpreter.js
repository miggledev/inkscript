const fs = require("fs");
const path = require("path");
const parser = require("./parser");

function evaluate(ast, env = {}) {
  switch (ast.type) {
    case "Program":
      ast.body.forEach(stmt => evaluate(stmt, env));
      break;

    case "VariableDeclaration":
      env[ast.id.name] = evaluate(ast.init, env);
      break;

    case "Assignment":
      if (!(ast.id.name in env)) throw new Error(`Undefined variable: ${ast.id.name}`);
      env[ast.id.name] = evaluate(ast.value, env);
      break;

    case "IfStatement":
      if (evaluate(ast.test, env)) {
        evaluate(ast.consequent, env);
      } else if (ast.alternate) {
        evaluate(ast.alternate, env);
      }
      break;

    case "WhileStatement":
      while (evaluate(ast.test, env)) {
        evaluate(ast.body, env);
      }
      break;

    case "BlockStatement":
      ast.body.forEach(stmt => evaluate(stmt, env));
      break;

    case "ExpressionStatement":
      evaluate(ast.expression, env);
      break;

    case "CallExpression":
      const fn = env[ast.callee.name];
      if (typeof fn !== "function") throw new Error(`Not a function: ${ast.callee.name}`);
      return fn(...ast.arguments.map(arg => evaluate(arg, env)));

    case "BinaryExpression":
      const left = evaluate(ast.left, env);
      const right = evaluate(ast.right, env);
      switch (ast.operator) {
        case "+": return left + right;
        case "-": return left - right;
        case "*": return left * right;
        case "/": return left / right;
        case "%": return left % right;
        case "==": return left == right;
        case "===": return left === right;
        case "!=": return left != right;
        case "<": return left < right;
        case "<=": return left <= right;
        case ">": return left > right;
        case ">=": return left >= right;
        case "&&": return left && right;
        case "||": return left || right;
      }
      break;

    case "Identifier":
      if (!(ast.name in env)) throw new Error(`Undefined variable: ${ast.name}`);
      return env[ast.name];

    case "Literal":
      return ast.value;

    case "Divert":
      console.log(`-> Divert to: ${ast.target.name}`);
      break;

    case "Tag":
      console.log(`~ Tag: ${ast.value}`);
      break;

    case "Comment":
      // skip
      break;

    default:
      throw new Error("Unknown node type: " + ast.type);
  }
}

// --------- Entry point ---------
const filePath = process.argv[2];
if (!filePath) {
  console.error("Usage: node interpreter.js <file.inkscript>");
  process.exit(1);
}

const source = fs.readFileSync(path.resolve(filePath), "utf8");
const ast = parser.parse(source);

const globalEnv = {
  say: (...args) => console.log("SAY:", ...args),
  print: (...args) => console.log(...args),
};

evaluate(ast, globalEnv);
