class Resolver: ExprThrowVisitor, StmtVisitor {
    private enum FunctionType {
        case none, function, method, initializer
    }
    private enum ResolverError: Error {
        case error(String)
    }
    private enum ClassType {
        case Class, Subclass
    }
    private struct ClassStatus {
        var classType: ClassType
        var name: String
    }
    
    // include functions and classes in the symbol table and resolve them like everything else
    private var isInLoop = false
    private var currentClassStatus: ClassStatus? = nil
    private var currentFunction: FunctionType = .none
    private var problems: [InterpreterProblem] = []
    private var symbolTable: SymbolTables = .init()
    private var isInGlobalScope = false
    
    internal func visitGroupingExpr(expr: GroupingExpr) throws {
        try resolve(expr.expression)
    }
    
    internal func visitLiteralExpr(expr: LiteralExpr) {
        // nothing
    }
    
    internal func visitArrayLiteralExpr(expr: ArrayLiteralExpr) throws {
        for value in expr.values {
            try resolve(value)
        }
    }
    
    internal func visitStaticClassExpr(expr: StaticClassExpr) throws {
        // nothing
    }
    
    internal func visitThisExpr(expr: ThisExpr) throws {
        if currentClassStatus == nil {
            throw error(message: "Can't use 'this' outside of a class", token: expr.keyword)
        }
        do {
            expr.symbolTableIndex = symbolTable.query("this")!.id
        } catch {
            assertionFailure("'this' is undefined")
        }
    }
    
    internal func visitSuperExpr(expr: SuperExpr) throws {
        if currentClassStatus?.classType != .Subclass {
            throw error(message: "Can't use 'super' outside of a subclass", token: expr.keyword)
        }
    }
    
    internal func visitVariableExpr(expr: VariableExpr) {
        if let existingSymbol = symbolTable.query(expr.name.lexeme) {
            if let symbol = existingSymbol as? VariableSymbol {
                // uninit -> is a global, init it
                // initing -> use of variable within its own declaration
                // globalIniting -> global circular reference
                // finishedInit -> no problem
                switch symbol.variableStatus {
                case .uninit:
                    // is a global, init it
                    initGlobal(index: symbol.id)
                case .initing:
                    // use of variable within its own declaration
                    error(message: "Use of variable within its own declaration", token: expr.name)
                case .globalIniting:
                    // global circular reference
                    error(message: "Circular reference", start: expr.startLocation, end: expr.endLocation)
                case .finishedInit:
                    // no problem
                    break
                }
            }
            expr.symbolTableIndex = existingSymbol.id
        } else {
            error(message: "Use of unknown identifier \(expr.name.lexeme)", start: expr.startLocation, end: expr.endLocation)
        }
    }
    
    internal func visitSubscriptExpr(expr: SubscriptExpr) throws {
        try resolve(expr.expression)
        try resolve(expr.index)
    }
    
    internal func visitCallExpr(expr: CallExpr) throws {
        try resolve(expr.callee)
        for argument in expr.arguments {
            try resolve(argument)
        }
    }
    
    internal func visitGetExpr(expr: GetExpr) throws {
        try resolve(expr.object)
    }
    
    internal func visitUnaryExpr(expr: UnaryExpr) throws {
        try resolve(expr.right)
    }
    
    internal func visitCastExpr(expr: CastExpr) throws {
        try resolve(expr.value)
    }
    
    internal func visitArrayAllocationExpr(expr: ArrayAllocationExpr) throws {
        for expression in expr.capacity {
            try resolve(expression)
        }
    }
    
    internal func visitClassAllocationExpr(expr: ClassAllocationExpr) throws {
        for expression in expr.arguments {
            try resolve(expression)
        }
    }
    
    internal func visitBinaryExpr(expr: BinaryExpr) throws {
        try resolve(expr.left)
        try resolve(expr.right)
    }
    
    internal func visitLogicalExpr(expr: LogicalExpr) throws {
        try resolve(expr.left)
        try resolve(expr.right)
    }
    
    internal func visitSetExpr(expr: SetExpr) throws {
        try resolve(expr.to)
        try resolve(expr.value)
    }
    
    internal func visitAssignExpr(expr: AssignExpr) throws {
        // first figure out if it is a variable declaration (is first assignment)
        
        // isFirstAssignment being nil means that it needs to be computed.
        // true means that its already been computed and that the value must've already been resolved
        // false means that its already been computed, but the value might've not been resolved.
        if expr.isFirstAssignment == nil {
            if let existingSymbol = symbolTable.query(expr.to.name.lexeme) {
                if !(existingSymbol is VariableSymbol) {
                    // error! cannot assign
                    if existingSymbol is FunctionNameSymbol {
                        error(message: "Cannot assign to value: '\(expr.to.name.lexeme) is a function", token: expr.to.name)
                    } else if existingSymbol is ClassNameSymbol {
                        error(message: "Cannot assign to value: '\(expr.to.name.lexeme) is a class", token: expr.to.name)
                    } else {
                        assertionFailure("Unexpected symbol type!")
                        error(message: "Cannot assign to value", token: expr.to.name)
                    }
                    
                    try resolve(expr.value)
                    return
                }
                expr.isFirstAssignment = false
            } else {
                expr.isFirstAssignment = true
            }
            
            if expr.isFirstAssignment! {
                // define the variable but set it as unusable
                
                let associatedSymbol = VariableSymbol(id: -1, name: expr.to.name.lexeme, variableStatus: .initing)
                expr.to.symbolTableIndex = symbolTable.addToSymbolTable(symbol: associatedSymbol)
                defer {
                    associatedSymbol.variableStatus = .finishedInit
                }
                try resolve(expr.value)
            } else {
                if expr.annotation != nil {
                    error(message: "Cannot retype variable after first assignment", token: expr.annotationColon!)
                }
                try resolve(expr.to)
                try resolve(expr.value)
            }
        } else if expr.isFirstAssignment == false {
            try resolve(expr.value)
        }
    }
    
    func visitImplicitCastExpr(expr: ImplicitCastExpr) throws {
        assertionFailure("Implicit cast expression present in Resolver")
    }
    
    func defineVariableWithInitializer(name: Token, initializer: Expr?) -> Int? {
        // use this with class fields, function parameters, etc.
        if symbolTable.queryAtScopeOnly(name.lexeme) != nil {
            error(message: "Invalid redeclaration of \(name.lexeme)", token: name)
            return nil
        }
        let symbol = VariableSymbol(id: -1, name: name.lexeme, variableStatus: .initing)
        let symbolTableIndex = symbolTable.addToSymbolTable(symbol: symbol)
        if initializer != nil {
            catchErrorClosure {
                try resolve(initializer!)
            }
        }
        symbol.variableStatus = .finishedInit
        return symbolTableIndex
    }
    
    internal func visitClassStmt(stmt: ClassStmt) {
        let previousIsInGlobalScope = isInGlobalScope
        isInGlobalScope = false
        // add template names, method names
        var classScope: [String : Int] = [:]
        if stmt.templateParameters != nil {
            for templateParameters in stmt.templateParameters! {
                classScope[templateParameters.lexeme] = -1
            }
        }
        
        let currentClassName = stmt.name.lexeme
        stmt.scopeIndex = symbolTable.createAndEnterScope()
        stmt.thisSymbolTableIndex = symbolTable.addToSymbolTable(symbol: VariableSymbol(id: -1, name: "this", variableStatus: .finishedInit))
        let previousClassStatus = currentClassStatus
        var currentClassType = ClassType.Class
        if stmt.superclass != nil {
            currentClassType = .Subclass
        } else {
            currentClassType = .Class
        }
        currentClassStatus = .init(classType: currentClassType, name: currentClassName)
        
        guard let classSymbol = symbolTable.getSymbol(id: stmt.symbolTableIndex!) as? ClassSymbol else {
            assertionFailure("Symbol at class statement is not a class symbol")
            return
        }
        
        for method in stmt.staticMethods {
            catchErrorClosure {
                try defineFunction(stmt: method.function, methodStmt: method, withinClass: classSymbol.classId)
            }
        }
        for method in stmt.methods {
            catchErrorClosure {
                try defineFunction(stmt: method.function, methodStmt: method, withinClass: classSymbol.classId)
            }
        }
        
        for i in 0..<stmt.fields.count {
            stmt.fields[i].symbolTableIndex = defineVariableWithInitializer(name: stmt.fields[i].name, initializer: stmt.fields[i].initializer)
        }
        for i in 0..<stmt.staticFields.count {
            stmt.staticFields[i].symbolTableIndex = defineVariableWithInitializer(name: stmt.fields[i].name, initializer: stmt.fields[i].initializer)
        }
        
        for method in stmt.staticMethods {
            resolve(method)
        }
        for method in stmt.methods {
            resolve(method)
        }
        symbolTable.exitScope()
        currentClassStatus = previousClassStatus
        isInGlobalScope = previousIsInGlobalScope
    }
    
    internal func visitMethodStmt(stmt: MethodStmt) {
        let previousFunctionStatus = currentFunction
        if stmt.function.name.lexeme == currentClassStatus?.name {
            currentFunction = .initializer
            if stmt.isStatic {
                error(message: "Initializer declaration cannot be marked 'static'", token: stmt.staticKeyword!)
            }
        } else {
            currentFunction = .method
        }
        resolveFunction(stmt: stmt.function)
        currentFunction = previousFunctionStatus
    }
    
    private func resolveFunction(stmt: FunctionStmt) {
        let previousIsInGlobalScope = isInGlobalScope
        isInGlobalScope = false
        stmt.scopeIndex = symbolTable.createAndEnterScope()
        for i in 0..<stmt.params.count {
            stmt.params[i].symbolTableIndex = defineVariableWithInitializer(name: stmt.params[i].name, initializer: stmt.params[i].initializer)
        }
        for stmt in stmt.body {
            resolve(stmt)
        }
        symbolTable.exitScope()
        isInGlobalScope = previousIsInGlobalScope
    }
    
    private func defineFunction(stmt: FunctionStmt) throws -> Int {
        try defineFunction(stmt: stmt, methodStmt: nil, withinClass: nil)
    }
    
    private func defineFunction(stmt: FunctionStmt, methodStmt: MethodStmt?, withinClass: Int?) throws -> Int {
        var paramsName = ""
        for param in stmt.params {
            if paramsName != "" {
                paramsName = paramsName+", "
            }
            let astPrinter = AstPrinter()
            paramsName+=astPrinter.printAst(param.astType ?? AstAnyType(startLocation: .dub(), endLocation: .dub()))
        }
        let functionSignature = "\(stmt.name.lexeme)(\(paramsName))"
        if symbolTable.queryAtScopeOnly(functionSignature) != nil {
            throw error(message: "Invalid redeclaration of '\(stmt.name.lexeme)'", token: stmt.name)
        }
        var symbolTableIndex = -1
        if withinClass == nil {
            symbolTableIndex = symbolTable.addToSymbolTable(symbol: FunctionSymbol(id: -1, name: functionSignature, functionStmt: stmt, returnType: QsAnyType(assignable: false)))
        } else {
            symbolTableIndex = symbolTable.addToSymbolTable(symbol: MethodSymbol(id: -1, name: functionSignature, withinClass: withinClass!, overridedBy: [], methodStmt: methodStmt!, returnType: QsAnyType(assignable: false)))
        }
        stmt.symbolTableIndex = symbolTableIndex
        if let existingNameSymbolInfo = symbolTable.queryAtScopeOnly(stmt.name.lexeme) {
            guard let functionNameSymbolInfo = existingNameSymbolInfo as? FunctionNameSymbol else {
                throw error(message: "Invalid redeclaration of '\(stmt.name.lexeme)'", token: stmt.name)
            }
            stmt.nameSymbolTableIndex = functionNameSymbolInfo.id
            functionNameSymbolInfo.belongingFunctions.append(symbolTableIndex)
        } else {
            stmt.nameSymbolTableIndex = symbolTable.addToSymbolTable(symbol: FunctionNameSymbol(id: -1, name: stmt.name.lexeme, belongingFunctions: [symbolTableIndex]))
        }
        
        return symbolTableIndex
    }
    
    internal func visitFunctionStmt(stmt: FunctionStmt) {
        let previousFunction = currentFunction
        currentFunction = .function
        resolveFunction(stmt: stmt)
        currentFunction = previousFunction
    }
    
    internal func visitExpressionStmt(stmt: ExpressionStmt) {
        catchErrorClosure {
            try resolve(stmt.expression)
        }
    }
    
    internal func visitIfStmt(stmt: IfStmt) {
        catchErrorClosure {
            try resolve(stmt.condition)
        }
        
        resolve(stmt.thenBranch)
        
        resolve(stmt.elseIfBranches)
        
        if stmt.elseBranch != nil {
            resolve(stmt.elseBranch!)
        }
    }
    
    internal func visitOutputStmt(stmt: OutputStmt) {
        for expression in stmt.expressions {
            catchErrorClosure {
                try resolve(expression)
            }
        }
    }
    
    internal func visitInputStmt(stmt: InputStmt) {
        for expression in stmt.expressions {
            catchErrorClosure {
                try resolve(expression)
            }
        }
    }
    
    internal func visitReturnStmt(stmt: ReturnStmt) {
        if currentFunction == .none {
            error(message: "Can't return from top-level code.", token: stmt.keyword)
        }
        
        if stmt.value != nil {
            if currentFunction == .initializer {
                error(message: "Can't return a value from an initializer", token: stmt.keyword)
            }
            catchErrorClosure {
                try resolve(stmt.value!)
            }
        }
    }
    
    internal func visitLoopFromStmt(stmt: LoopFromStmt) {
        let previousLoopState = isInLoop
        catchErrorClosure {
            try resolve(stmt.variable)
        }
        catchErrorClosure {
            try resolve(stmt.lRange)
        }
        catchErrorClosure {
            try resolve(stmt.rRange)
        }
        
        isInLoop = true
        resolve(stmt.body)
        
        isInLoop = previousLoopState
    }
    
    internal func visitWhileStmt(stmt: WhileStmt) {
        let previousLoopState = isInLoop
        
        catchErrorClosure {
            try resolve(stmt.expression)
        }
        
        isInLoop = true
        resolve(stmt.body)
        
        isInLoop = previousLoopState
    }
    
    internal func visitBreakStmt(stmt: BreakStmt) {
        if !isInLoop {
            error(message: "Can't use 'break' outside of loop", token: stmt.keyword)
        }
    }
    
    internal func visitContinueStmt(stmt: ContinueStmt) {
        if !isInLoop {
            error(message: "Can't use 'continue' outside of loop", token: stmt.keyword)
        }
    }
    
    internal func visitBlockStmt(stmt: BlockStmt) {
        stmt.scopeIndex = symbolTable.createAndEnterScope()
        let previousInGlobalScope = isInGlobalScope
        isInGlobalScope = false
        resolve(stmt.statements)
        isInGlobalScope = previousInGlobalScope
        symbolTable.exitScope()
    }
    
    private func error(message: String, token: Token) -> ResolverError {
        problems.append(.init(message: message, token: token))
        return ResolverError.error(message)
    }
    private func error(message: String, start: InterpreterLocation, end: InterpreterLocation) -> ResolverError {
        problems.append(.init(message: message, start: start, end: end))
        return ResolverError.error(message)
    }
    
    private func resolve(_ expression: Expr) throws {
        try expression.accept(visitor: self)
    }
    
    private func resolve(_ statement: Stmt) {
        statement.accept(visitor: self)
    }
    
    private func resolve(_ statements: [Stmt]) {
        for statement in statements {
            resolve(statement)
        }
    }
    
    private func defineClass(stmt: ClassStmt, classId: Int) throws -> Int {
        let classSignature = generateClassSignature(className: stmt.name.lexeme, templateAstTypes: stmt.expandedTemplateParameters)
        if symbolTable.queryAtScopeOnly(classSignature) != nil {
            throw error(message: "Invalid redeclaration of '\(stmt.name.lexeme)'", token: stmt.name)
        }
        
        let symbolTableIndex = symbolTable.addToSymbolTable(symbol: ClassSymbol(id: -1, name: classSignature, classId: classId, classChain: nil))
        stmt.symbolTableIndex = symbolTableIndex
        if let existingNameSymbolInfo = symbolTable.queryAtScopeOnly(stmt.name.lexeme) {
            guard existingNameSymbolInfo is ClassNameSymbol else {
                throw error(message: "Invalid redeclaration of '\(stmt.name.lexeme)'", token: stmt.name)
            }
            // do nothing about it
        } else {
            symbolTable.addToSymbolTable(symbol: ClassNameSymbol(id: -1, name: stmt.name.lexeme))
        }
        
        return symbolTableIndex
    }
    
    private func eagerDefineClassesAndFunctions(statements: [Stmt]) {
        // add all class and function names into the undefinables list
        var classIdCounter = 0
        for statement in statements {
            if let classStmt = statement as? ClassStmt {
                catchErrorClosure {
                    try defineClass(stmt: classStmt, classId: classIdCounter)
                }
                classIdCounter+=1
            }
            
            if let functionStmt = statement as? FunctionStmt {
                catchErrorClosure {
                    try defineFunction(stmt: functionStmt)
                }
            }
        }
    }
    
    private func initGlobal(index: Int) {
        let symbol = symbolTable.getSymbol(id: index) as! GlobalVariableSymbol
        symbol.variableStatus = .globalIniting
        catchErrorClosure {
            try resolve(symbol.globalDefiningAssignExpr.value)
        }
        symbol.variableStatus = .finishedInit
    }
    
    private func eagerDefineGlobalVariables(statements: [Stmt]) {
        // two passes. one finding all the global defining set expressions and another traversal
        var globalVariableIndexes: [Int] = []
        for statement in statements {
            guard let expressionStmt = statement as? ExpressionStmt else {
                continue
            }
            guard let assignExpr = expressionStmt.expression as? AssignExpr else {
                continue
            }
            
            if let existingSymbol = symbolTable.query(assignExpr.to.name.lexeme) {
                assignExpr.isFirstAssignment = false
                if !(existingSymbol is VariableSymbol) {
                    error(message: "Invalid redeclaration of \(existingSymbol.name)", token: assignExpr.to.name)
                    continue
                }
                assignExpr.to.symbolTableIndex = existingSymbol.id
            } else {
                assignExpr.isFirstAssignment = true
                assignExpr.to.symbolTableIndex = symbolTable.addToSymbolTable(symbol: GlobalVariableSymbol(id: -1, name: assignExpr.to.name.lexeme, globalDefiningAssignExpr: assignExpr, variableStatus: .uninit))
                globalVariableIndexes.append(assignExpr.to.symbolTableIndex!)
            }
        }
        
        for globalVariableIndex in globalVariableIndexes {
            initGlobal(index: globalVariableIndex)
        }
    }
    
    func resolveAST(statements: inout [Stmt], symbolTable: inout SymbolTables) -> [InterpreterProblem] {
        self.symbolTable = symbolTable
        
        isInGlobalScope = true
        isInLoop = false
        currentFunction = .none
        currentClassStatus = nil
        problems = []
        
        eagerDefineClassesAndFunctions(statements: statements)
        eagerDefineGlobalVariables(statements: statements)
        resolve(statements)
        
        symbolTable = self.symbolTable
        return problems
    }
}
