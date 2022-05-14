class Resolver: ExprThrowVisitor, StmtVisitor {
    private enum FunctionType {
        case none, function, method, initializer
    }
    private enum ResolverError: Error {
        case error(String)
    }
    private enum ClassType {
        case None, Class, Subclass
    }
    
    // include functions and classes in the symbol table and resolve them like everything else
    private var isInLoop = false
    private var currentClassType = ClassType.None
    private var currentFunction: FunctionType = .none
    private var problems: [InterpreterProblem] = []
    private var scopes: [[String: Int]] = [] // maps variable names to indexes in the symbol table
    private var symbolTable: [SymbolInfo] = []
    private var currentLocation = SymbolLocation.Global
    
    func addToSymbolTableAtScope(symbol: SymbolInfo) -> Int {
        let newSymbolId = symbolTable.count
        var newSymbol = symbol
        newSymbol.id = newSymbolId
        symbolTable.append(newSymbol)
        scopes[scopes.count-1].updateValue(scopes[scopes.count-1].count, forKey: symbol.name)
        return newSymbolId
    }
    
    private func createVariableAtScope(variableName: String) -> Int {
        addToSymbolTableAtScope(symbol: VariableSymbolInfo.init(id: 0, type: nil, name: variableName, symbolLocation: currentLocation))
    }
    
    private func getOutermostScope() -> [String : Int] {
        return scopes[scopes.count-1]
    }
    
    private func getSymbolIndex(name: String) -> Int? {
        for i in 0..<scopes.count {
            let scope = scopes[scopes.count-i-1]
            if let result = scope[name] {
                return result
            }
        }
        return nil
    }
    
    private func defineOrGetVariable(name: Token, allowShadowing: Bool) throws -> (Int, Bool) {
        // returns a tuple with its symbol table index and whether or not it is a new variable
        if let variableIndex = getSymbolIndex(name: name.lexeme) {
            if !(symbolTable[variableIndex] is VariableSymbolInfo) {
                throw error(message: "Invalid redeclaration of '\(name.lexeme)'", token: name)
            }
            if variableIndex == -1 {
                // not allowed
                throw error(message: "Invalid use of identifier '\(name.lexeme)'", token: name)
            }
        }
        
        if allowShadowing {
            if let variableIndex = getOutermostScope()[name.lexeme] {
                return (variableIndex, false)
            }
        } else {
            if let variableIndex = getSymbolIndex(name: name.lexeme) {
                return (variableIndex, false)
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
    
    internal func visitThisExpr(expr: ThisExpr) throws {
        if currentClassType == .None {
            throw error(message: "Can't use 'this' outside of a class", token: expr.keyword)
        }
        do {
            (expr.symbolTableIndex, _) = try defineOrGetVariable(name: expr.keyword, allowShadowing: false)
        } catch {
            assertionFailure("'this' is undefined")
        }
    }
    
    internal func visitSuperExpr(expr: SuperExpr) throws {
        if currentClassType != .Subclass {
            throw error(message: "Can't use 'super' outside of a subclass", token: expr.keyword)
        }
        // nothing (for now)
    }
    
    internal func visitVariableExpr(expr: VariableExpr) {
        catchErrorClosure {
            (expr.symbolTableIndex, _) = try defineOrGetVariable(name: expr.name, allowShadowing: false)
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
        if expr.to is VariableExpr {
            // assignment to a variable. Define it
            let assignedVariable = expr.to as! VariableExpr
            
            do {
                (assignedVariable.symbolTableIndex, expr.isFirstAssignment) = try defineOrGetVariable(name: assignedVariable.name, allowShadowing: false)
                
                if !expr.isFirstAssignment! && expr.annotation != nil {
                    problems.append(.init(message: "Cannot retype variable after first assignment", token: expr.annotationColon!))
                }
            } catch {
                
            }
        } else {
            try resolve(expr.to)
        }
    }
    
    internal func visitClassStmt(stmt: ClassStmt) {
        // add template names, method names
        var classScope: [String : Int] = [:]
        if stmt.templateParameters != nil {
            for templateParameters in stmt.templateParameters! {
                classScope[templateParameters.lexeme] = -1
            }
        }
        scopes.append(classScope)
        
        for method in stmt.staticMethods {
            catchErrorClosure {
                try defineFunction(stmt: method.function)
            }
        }
        for method in stmt.methods {
            catchErrorClosure {
                try defineFunction(stmt: method.function)
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
    }
    
    internal func visitMethodStmt(stmt: MethodStmt) {
        resolveFunction(stmt: stmt.function)
    }
    
    private func resolveFunction(stmt: FunctionStmt) {
        
    }
    
    private func defineFunction(stmt: FunctionStmt) throws -> Int {
        if let existingId = getOutermostScope()[stmt.name.lexeme] {
            throw error(message: "Invalid redeclaration of '\(stmt.name.lexeme)'", token: stmt.name)
        }
        
        var paramsName = ""
        for param in stmt.params {
            if paramsName != "" {
                paramsName = paramsName+", "
            }
            let astPrinter = AstPrinter()
            paramsName+=astPrinter.printAst(param.astType)
        }
        let functionSignature = "\(stmt.name.lexeme)(\(paramsName))"
        if let existingId = getOutermostScope()[functionSignature] {
            throw error(message: "Invalid redeclaration of '\(stmt.name.lexeme)'", token: stmt.name)
        }
        
        let symbolTableIndex = addToSymbolTableAtScope(symbol: FunctionSymbolInfo(id: -1, name: functionSignature))
        stmt.symbolTableIndex = symbolTableIndex
        
        return symbolTableIndex
    }
    
    internal func visitFunctionStmt(stmt: FunctionStmt) {
        catchErrorClosure {
            try defineFunction(stmt: stmt)
        }
        resolveFunction(stmt: stmt)
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
        
        beginScope()
        resolve(stmt.thenBranch)
        endScope()
        
        resolve(stmt.elseIfBranches)
        
        if stmt.elseBranch != nil {
            beginScope()
            resolve(stmt.elseBranch!)
            endScope()
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
        beginScope()
        resolve(stmt.statements)
        endScope()
        
        isInLoop = previousLoopState
    }
    
    internal func visitWhileStmt(stmt: WhileStmt) {
        let previousLoopState = isInLoop
        
        catchErrorClosure {
            try resolve(stmt.expression)
        }
        
        isInLoop = true
        beginScope()
        resolve(stmt.statements)
        endScope()
        
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
    
    private func beginScope() {
        scopes.append([:])
    }
    
    private func endScope() {
        scopes.popLast()
    }
    
    private func error(message: String, token: Token) -> ResolverError {
        problems.append(.init(message: message, line: token.line, inlineLocation: .init(column: token.column, length: token.lexeme.count)))
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
    
    private func eagerDefineClassesAndFunctions(statements: [Stmt]) {
        // add all class and function names into the undefinables list
        for statement in statements {
            if let classStmt = statement as? ClassStmt {
                addToSymbolTableAtScope(symbol: ClassSymbolInfo.init(id: -1, name: classStmt.name.lexeme))
            }
            
            if let functionStmt = statement as? FunctionStmt {
                if getSymbolIndex(name: functionStmt.name.lexeme) == nil {
                    addToSymbolTableAtScope(symbol: FunctionSymbolInfo(id: -1, name: functionStmt.name.lexeme))
                }
            }
        }
    }
    
    func resolveAST(statements: [Stmt], symbolTable: inout [SymbolInfo]) {
        self.symbolTable = symbolTable
        
        isInLoop = false
        currentFunction = .none
        currentClassType = .None
        problems = []
        scopes = []
        scopes.append([:])
        
        eagerDefineClassesAndFunctions(statements: statements)
        resolve(statements)
        
        symbolTable = self.symbolTable
    }
}
