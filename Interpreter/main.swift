import Foundation

let DEBUG = true
let INCLUDE_STRING = true
let INCLUDE_BUILTIN_CLASSES = false

//let toInterpret = try! String.init(contentsOfFile: "/Users/michel/Desktop/test.qs")
//let toInterpret = try! String.init(contentsOfFile: "/Users/michel/Desktop/Quasicode/Tests/full/ParseTest.qsc")
//let toInterpret = try! String.init(contentsOfFile: "/Users/michel/Desktop/Quasicode/LilTests/test8.qs")
//let toInterpret = try! String.init(contentsOfFile: "/Users/michel/Desktop/Quasicode/ClassImplementations.qs")
let toInterpret = try! String.init(contentsOfFile: "/Users/michel/Desktop/Quasicode/LilTests/test10.qs")
//let toInterpret = try! String.init(contentsOfFile: "/Users/michel/Desktop/triad_test.qs")

let start = DispatchTime.now()

let scanner = Scanner(source: toInterpret)
let (tokens, scanErrors) = scanner.scanTokens()
print("----- Scanner -----")
if DEBUG {
    print("Scanned tokens")
    debugPrintTokens(tokens: tokens)
}
print("\nErrors")
print(scanErrors)

// initialize the symbol table and put in all the default classes
var symbolTable: SymbolTables = .init()
if INCLUDE_STRING {
    addStringClassToSymbolTable(symbolTable)
}
let stringClassIndex = INCLUDE_STRING ? symbolTable.queryAtGlobalOnly("String<>")!.id : 0

print("----- Parser -----")
let parser = Parser(tokens: tokens, stringClassIndex: stringClassIndex)
let (stmts, parseErrors) = parser.parse()
var ast = stmts
if INCLUDE_BUILTIN_CLASSES {
    ast = addBuiltinClassesToAst(ast)
}
let astPrinter = AstPrinter()
if DEBUG {
    print("Parsed AST")
    print(astPrinter.printAst(ast, printWithTypes: false))
}
print("\nErrors")
print(parseErrors)

print("----- Templater -----")
let templater = Templater()
let (templatedStmts, templateErrors) = templater.expandClasses(statements: ast)
ast = templatedStmts
if DEBUG {
    print("Templated AST")
    print(astPrinter.printAst(templatedStmts, printWithTypes: false))
}
print("\nErrors")
print(templateErrors)

print("----- Resolver -----")
let resolver = Resolver()
let resolveErrors = resolver.resolveAST(statements: &ast, symbolTable: &symbolTable)
if DEBUG {
    print("Resolved AST")
    print(astPrinter.printAst(ast, printWithTypes: false))
    print("Symbol table")
    symbolTable.printTable()
}
print("\nErrors")
print(resolveErrors)

print("----- Type Checker -----")
let typeChecker = TypeChecker()
let typeCheckerErrors = typeChecker.typeCheckAst(statements: ast, symbolTables: &symbolTable)
if DEBUG {
    print("Type checked AST")
    print(astPrinter.printAst(ast, printWithTypes: true))
    print("Symbol table")
    symbolTable.printTable()
}
print("\nErrors")
print(typeCheckerErrors)

print("----- Compiler -----")
let compiler = Compiler()
let chunk = compiler.compileAst(stmts: ast)
if DEBUG {
    disassembleChunk(chunk, "main")
}

print("----- VM -----")
let vmInterface = VMInterface()
vmInterface.run(chunk: chunk)


let end = DispatchTime.now()
let nanoTime = end.uptimeNanoseconds - start.uptimeNanoseconds
let timeInterval = Double(nanoTime) / 1_000_000

//print("Execution time \(timeInterval) ms")
