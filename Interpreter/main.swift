import Foundation
import QuasicodeInterpreter

// swiftlint:disable identifier_name
let INCLUDE_STRING = true
let INCLUDE_BUILTIN_CLASSES = false
// swiftlint:enable identifier_name
enum ExecutionMode {
    case compilerAndVM
    case interpreter
}
let executionMode = ExecutionMode.interpreter

if true {
//    let toInterpret = try! String.init(contentsOfFile: "/Users/michel/Desktop/test.qs")
//    let toInterpret = try! String.init(contentsOfFile: "/Users/michel/Desktop/Quasicode/Tests/full/ParseTest.qsc")
    // swiftlint:disable:next all
    let toInterpret = try! String.init(contentsOfFile: "/Users/michel/Desktop/Quasicode/Tests/full/countPrimes.qsc")
//    let toInterpret = try! String.init(contentsOfFile: "/Users/michel/Desktop/Quasicode/LilTests/test13.qs")
//    let toInterpret = try! String.init(contentsOfFile: "/Users/michel/Desktop/Quasicode/ClassImplementations.qs")
//    let toInterpret = try! String.init(contentsOfFile: "/Users/michel/Desktop/Quasicode/LilTests/test11.qs")
//    let toInterpret = try! String.init(contentsOfFile: "/Users/michel/Desktop/Quasicode/Tests/line continuations/4.qsc")
//    let toInterpret = try! String.init(contentsOfFile: "/Users/michel/Desktop/triad_test.qs")
    
    let start = DispatchTime.now()
    
    let scanner = QuasicodeInterpreter.Scanner(source: toInterpret)
    let (tokens, scanErrors) = scanner.scanTokens(debugPrint: true)
    
    // initialize the symbol table and put in all the default classes
    var symbolTable: SymbolTables = .init()
    if INCLUDE_STRING {
        Builtins.addStringClassToSymbolTable(symbolTable)
    }
    let stringClassIndex = INCLUDE_STRING ? symbolTable.queryAtGlobalOnly("String<>")!.id : 0

    let parser = Parser(tokens: tokens, stringClassIndex: stringClassIndex, builtinClasses: INCLUDE_BUILTIN_CLASSES ? builtinClassNames : [])
    var ast: [Stmt]
    let parseErrors: [InterpreterProblem]
    (ast, parseErrors) = parser.parse(addBuiltinclassesToAst: INCLUDE_BUILTIN_CLASSES, debugPrint: true)


    let templater = Templater()
    let (templatedStmts, templateErrors) = templater.expandClasses(statements: ast)
    ast = templatedStmts
    print("templateErrors", templateErrors)

    let resolver = Resolver()
    let resolveErrors = resolver.resolveAST(statements: &ast, symbolTable: &symbolTable)
    print("resolveErrors", resolveErrors)


    let typeChecker = TypeChecker()
    let typeCheckerErrors = typeChecker.typeCheckAst(statements: ast, symbolTables: &symbolTable, debugPrint: true)

    symbolTable.printTable()
    
    let interpreter = Interpreter()
    interpreter.execute(ast, symbolTable: symbolTable, debugPrint: false)
    
//    if executionMode == .compilerAndVM {
//        /*
//        print("----- Compiler -----")
//        let compiler = Compiler()
//        let chunk = compiler.compileAst(stmts: ast, symbolTable: symbolTable)
//        if DEBUG {
//            var classNamesArray = symbolTable.getClassesRuntimeIdToClassNameArray().map {
//                UnsafePointer<Int8>(strdup($0))
//            }
//            classNamesArray.withUnsafeMutableBufferPointer { unsafePointer in
//                disassembleChunk(unsafePointer.baseAddress, chunk, "main")
//            }
//            for ptr in classNamesArray {
//                free(UnsafeMutablePointer(mutating: ptr))
//            }
//        }
//
//        print("----- VM -----")
//        let vmInterface = VMInterface()
//        vmInterface.run(chunk: chunk, classesRuntimeIdToClassNameArray: symbolTable.getClassesRuntimeIdToClassNameArray())
//
//        let end = DispatchTime.now()
//        let nanoTime = end.uptimeNanoseconds - start.uptimeNanoseconds
//        let timeInterval = Double(nanoTime) / 1_000_000
//
////        print("Execution time \(timeInterval) ms")
//         */
//    }
}
