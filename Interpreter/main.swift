import Foundation

let toInterpret = try! String.init(contentsOfFile: "/Users/michel/Desktop/test.qs")

let scanner = Scanner(source: toInterpret)
let (tokens, scanErrors) = scanner.scanTokens()
print("----- Scanner -----")
print("Tokens")
debugPrintTokens(tokens: tokens)
print("\nErrors")
print(scanErrors)

print("----- Parser -----")
let parser = Parser(tokens: tokens)
let (stmts, parseErrors) = parser.parse()
print("Parsed AST")
let astPrinter = AstPrinter()
print(astPrinter.printAst(stmts))
print("\nErrors")
print(parseErrors)

print("----- Templater -----")
let templater = Templater()
let (templatedStmts, templateErrors) = templater.expandClasses(statements: stmts)
print("Templated AST")
print(astPrinter.printAst(templatedStmts))
print("\nErrors")
print(templateErrors)
