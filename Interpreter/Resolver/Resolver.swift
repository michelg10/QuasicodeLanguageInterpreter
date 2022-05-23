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
    
    private func createVariableAtScope(variableName: String) -> Int {
        symbolTable.addToSymbolTable(symbol: VariableSymbolInfo.init(id: 0, type: nil, name: variableName))
    }
    
    private func defineOrGetVariable(name: Token, allowShadowing: Bool) throws -> (Int, Bool) {
        // returns a tuple with its symbol table index and whether or not it is a new variable
        if let variableIndex = symbolTable.getSymbolIndex(name: name.lexeme) {
            if !(symbolTable.getSymbol(id: variableIndex) is VariableSymbolInfo) {
                throw error(message: "Invalid redeclaration of '\(name.lexeme)'", token: name)
            }
        }
        
        if allowShadowing {
            // only return if there's a variable in the current scope
            if let variableInfo = symbolTable.queryAtScope(name.lexeme) {
                return (variableInfo.id, false)
            }
        } else {
            if let variableInfo = symbolTable.query(name.lexeme) {
                return (variableInfo.id, false)
            }
        }
        return (createVariableAtScope(variableName: name.lexeme), true)
    }
    
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
            (expr.symbolTableIndex, _) = try defineOrGetVariable(name: expr.keyword, allowShadowing: false)
        } catch {
            assertionFailure("'this' is undefined")
        }
    }
    
    internal func visitSuperExpr(expr: SuperExpr) throws {
        if currentClassStatus?.classType != .Subclass {
            throw error(message: "Can't use 'super' outside of a subclass", token: expr.keyword)
        }
    }
    
    private func defineIdentifierAsVariableOrGet(expr: VariableExpr) -> Bool {
        // returns whether or not something has been newly defined
        
        // check if its a function or a class
        if let symbolInfo = symbolTable.query(expr.name.lexeme) {
            if symbolInfo is FunctionNameSymbolInfo || symbolInfo is ClassSymbolInfo {
                expr.symbolTableIndex = symbolInfo.id
                return false
            }
        }
        var returnValue: Bool = false
        catchErrorClosure {
            (expr.symbolTableIndex, returnValue) = try defineOrGetVariable(name: expr.name, allowShadowing: false)
        }
        return returnValue
    }
    
    internal func visitVariableExpr(expr: VariableExpr) {
        defineIdentifierAsVariableOrGet(expr: expr)
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
        if expr.to is VariableExpr {
            // assignment to a variable. Define it
            let assignedVariable = expr.to as! VariableExpr
            
            do {
                expr.isFirstAssignment = defineIdentifierAsVariableOrGet(expr: assignedVariable)
                
                if !expr.isFirstAssignment! && expr.annotation != nil {
                    problems.append(.init(message: "Cannot retype variable after first assignment", token: expr.annotationColon!))
                }
            } catch {
                
            }
        } else {
            try resolve(expr.to)
        }
        try resolve(expr.value)
    }
    
    internal func visitClassStmt(stmt: ClassStmt) {
        // add template names, method names
        var classScope: [String : Int] = [:]
        if stmt.templateParameters != nil {
            for templateParameters in stmt.templateParameters! {
                classScope[templateParameters.lexeme] = -1
            }
        }
        
        let currentClassName = stmt.name.lexeme
        stmt.scopeIndex = symbolTable.createAndEnterScope()
        do {
            (stmt.thisSymbolTableIndex, _) = try defineOrGetVariable(name: .init(tokenType: .THIS, lexeme: "this", start: .dub(), end: .dub()), allowShadowing: true)
        } catch {
            assertionFailure("Failure while defining 'this'")
        }
        let previousClassStatus = currentClassStatus
        var currentClassType = ClassType.Class
        if stmt.superclass != nil {
            currentClassType = .Subclass
        } else {
            currentClassType = .Class
        }
        currentClassStatus = .init(classType: currentClassType, name: currentClassName)
        
        guard let classSymbol = symbolTable.getSymbol(id: stmt.symbolTableIndex!) as? ClassSymbolInfo else {
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
            catchErrorClosure {
                (stmt.fields[i].symbolTableIndex, _) = try defineOrGetVariable(name: stmt.fields[i].name, allowShadowing: true)
            }
            if stmt.fields[i].initializer != nil {
                catchErrorClosure {
                    try resolve(stmt.fields[i].initializer!)
                }
            }
        }
        for i in 0..<stmt.staticFields.count {
            catchErrorClosure {
                (stmt.staticFields[i].symbolTableIndex, _) = try defineOrGetVariable(name: stmt.staticFields[i].name, allowShadowing: true)
            }
            if stmt.staticFields[i].initializer != nil {
                catchErrorClosure {
                    try resolve(stmt.staticFields[i].initializer!)
                }
            }
        }
        
        for method in stmt.staticMethods {
            resolve(method)
        }
        for method in stmt.methods {
            resolve(method)
        }
        symbolTable.exitScope()
        currentClassStatus = previousClassStatus
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
        stmt.scopeIndex = symbolTable.createAndEnterScope()
        for i in 0..<stmt.params.count {
            stmt.params[i].symbolTableIndex = catchErrorClosure {
                try defineOrGetVariable(name: stmt.params[i].name, allowShadowing: true)
            }?.0
        }
        for stmt in stmt.body {
            resolve(stmt)
        }
        symbolTable.exitScope()
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
        if symbolTable.queryAtScope(functionSignature) != nil {
            throw error(message: "Invalid redeclaration of '\(stmt.name.lexeme)'", token: stmt.name)
        }
        var symbolTableIndex = -1
        if withinClass == nil {
            symbolTableIndex = symbolTable.addToSymbolTable(symbol: FunctionSymbolInfo(id: -1, name: functionSignature, functionStmt: stmt, returnType: QsAnyType()))
        } else {
            symbolTableIndex = symbolTable.addToSymbolTable(symbol: MethodSymbolInfo(id: -1, name: functionSignature, withinClass: withinClass!, overridedBy: [], methodStmt: methodStmt!, returnType: QsAnyType()))
        }
        stmt.symbolTableIndex = symbolTableIndex
        if let existingNameSymbolInfo = symbolTable.queryAtScope(stmt.name.lexeme) {
            guard let functionNameSymbolInfo = existingNameSymbolInfo as? FunctionNameSymbolInfo else {
                throw error(message: "Invalid redeclaration of '\(stmt.name.lexeme)'", token: stmt.name)
            }
            stmt.nameSymbolTableIndex = functionNameSymbolInfo.id
            functionNameSymbolInfo.belongingFunctions.append(symbolTableIndex)
        } else {
            stmt.nameSymbolTableIndex = symbolTable.addToSymbolTable(symbol: FunctionNameSymbolInfo(id: -1, name: stmt.name.lexeme, belongingFunctions: [symbolTableIndex]))
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
        resolve(stmt.statements)
        symbolTable.exitScope()
    }
    
    private func error(message: String, token: Token) -> ResolverError {
        problems.append(.init(message: message, token: token))
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
        let classSignature = classSignature(className: stmt.name.lexeme, templateAstTypes: stmt.expandedTemplateParameters)
        if symbolTable.queryAtScope(classSignature) != nil {
            throw error(message: "Invalid redeclaration of '\(stmt.name.lexeme)'", token: stmt.name)
        }
        
        let symbolTableIndex = symbolTable.addToSymbolTable(symbol: ClassSymbolInfo(id: -1, name: classSignature, classId: classId, classChain: nil))
        stmt.symbolTableIndex = symbolTableIndex
        if let existingNameSymbolInfo = symbolTable.queryAtScope(stmt.name.lexeme) {
            guard existingNameSymbolInfo is ClassNameSymbolInfo else {
                throw error(message: "Invalid redeclaration of '\(stmt.name.lexeme)'", token: stmt.name)
            }
            // do nothing about it
        } else {
            symbolTable.addToSymbolTable(symbol: ClassNameSymbolInfo(id: -1, name: stmt.name.lexeme))
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
    
    func resolveAST(statements: inout [Stmt], symbolTable: inout SymbolTables) -> [InterpreterProblem] {
        self.symbolTable = symbolTable
        
        isInLoop = false
        currentFunction = .none
        currentClassStatus = nil
        problems = []
        
        eagerDefineClassesAndFunctions(statements: statements)
        resolve(statements)
        
        symbolTable = self.symbolTable
        return problems
    }
}
