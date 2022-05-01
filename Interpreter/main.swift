import Foundation

let toInterpret = try! String.init(contentsOfFile: "/Users/michel/Desktop/test.qs")

let scanner = Scanner(source: toInterpret)
let (tokens, scanErrors) = scanner.scanTokens()
debugPrintTokens(tokens: tokens)
print(scanErrors)

let parser = Parser(tokens: tokens)
let (stmts, parseErrors) = parser.parse()
print(parseErrors)
print("AST")
let astPrinter = AstPrinter()
for stmt in stmts {
    print(astPrinter.printAst(stmt: stmt))
}
