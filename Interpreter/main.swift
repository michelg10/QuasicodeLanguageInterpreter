import Foundation

let DEBUG = true

//let toInterpret = try! String.init(contentsOfFile: "/Users/michel/Desktop/test.qs")
//let toInterpret = try! String.init(contentsOfFile: "/Users/michel/Desktop/Quasicode/Tests/full/ParseTest.qsc")
let toInterpret = try! String.init(contentsOfFile: "/Users/michel/Desktop/Quasicode/LilTests/test5.qs")

let start = DispatchTime.now()

let scanner = Scanner(source: toInterpret)
let (tokens, scanErrors) = scanner.scanTokens()
print("----- Scanner -----")
print("Scanned tokens")
debugPrintTokens(tokens: tokens)
print("\nErrors")
print(scanErrors)

print("----- Parser -----")
let parser = Parser(tokens: tokens)
let (stmts, classStmts, parseErrors) = parser.parse()
var ast = stmts
print("Parsed AST")
let astPrinter = AstPrinter()
print(astPrinter.printAst(ast, printWithTypes: false))
print("\nErrors")
print(parseErrors)

print("----- Templater -----")
let templater = Templater()
let (templatedStmts, templateErrors) = templater.expandClasses(statements: ast, classStmts: classStmts)
ast = templatedStmts
print("Templated AST")
print(astPrinter.printAst(templatedStmts, printWithTypes: false))
print("\nErrors")
print(templateErrors)

print("----- Resolver -----")
var symbolTable: SymbolTables = .init()
let resolver = Resolver()
let resolveErrors = resolver.resolveAST(statements: &ast, symbolTable: &symbolTable)
print("Resolved AST")
print(astPrinter.printAst(ast, printWithTypes: false))
print("Symbol table")
symbolTable.printTable()
print("\nErrors")
print(resolveErrors)

print("----- Type Checker -----")
let typeChecker = TypeChecker()
let typeCheckerErrors = typeChecker.typeCheckAst(statements: ast, symbolTables: &symbolTable)
print("Type checked AST")
print(astPrinter.printAst(ast, printWithTypes: true))
print("Symbol table")
symbolTable.printTable()
print("\nErrors")
print(typeCheckerErrors)


let end = DispatchTime.now()
let nanoTime = end.uptimeNanoseconds - start.uptimeNanoseconds
let timeInterval = Double(nanoTime) / 1_000_000

print("Execution time \(timeInterval) ms")
