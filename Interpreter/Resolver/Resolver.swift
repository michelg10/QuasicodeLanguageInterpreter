class Resolver: ExprVisitor, StmtVisitor {
    enum FunctionType {
        case none, function, method, initializer
    }
    
    private var isInLoop = false
    private var currentFunction: FunctionType = .none
    private var problems: [InterpreterProblem] = []
    private var scopes: [[String: Int]] = [] // maps variable names to indexes in the symbol table
    private var symbolTable: [SymbolInfo] = []
    private var classTable: [ClassInfo] = []
    
    internal func visitGroupingExpr(expr: GroupingExpr) {
        expr.expression.accept(visitor: self)
    }
    
    internal func visitLiteralExpr(expr: LiteralExpr) {
        // nothing
    }
    
    internal func visitArrayLiteralExpr(expr: ArrayLiteralExpr) {
        for value in expr.values {
            resolve(value)
        }
    }
    
    internal func visitThisExpr(expr: ThisExpr) {
        // TODO: this
    }
    
    internal func visitSuperExpr(expr: SuperExpr) {
        // TODO: this
    }
    
    internal func visitVariableExpr(expr: VariableExpr) {
        // TODO: this
    }
    
    internal func visitSubscriptExpr(expr: SubscriptExpr) {
        // TODO: this
    }
    
    internal func visitCallExpr(expr: CallExpr) {
        // TODO: this
    }
    
    internal func visitGetExpr(expr: GetExpr) {
        // TODO: this
    }
    
    internal func visitUnaryExpr(expr: UnaryExpr) {
        resolve(expr.right)
    }
    
    internal func visitCastExpr(expr: CastExpr) {
        resolve(expr.value)
    }
    
    internal func visitArrayAllocationExpr(expr: ArrayAllocationExpr) {
        for expression in expr.capacity {
            resolve(expression)
        }
    }
    
    internal func visitClassAllocationExpr(expr: ClassAllocationExpr) {
        for expression in expr.arguments {
            resolve(expression)
        }
    }
    
    internal func visitBinaryExpr(expr: BinaryExpr) {
        resolve(expr.left)
        resolve(expr.right)
    }
    
    internal func visitLogicalExpr(expr: LogicalExpr) {
        resolve(expr.left)
        resolve(expr.right)
    }
    
    internal func visitSetExpr(expr: SetExpr) {
        // TODO: this
    }
    
    internal func visitClassStmt(stmt: ClassStmt) {
        // TODO: this
    }
    
    internal func visitMethodStmt(stmt: MethodStmt) {
        handleFunction(stmt: stmt.function)
    }
    
    private func handleFunction(stmt: FunctionStmt) {
        // TODO: this
    }
    
    internal func visitFunctionStmt(stmt: FunctionStmt) {
        handleFunction(stmt: stmt)
    }
    
    internal func visitExpressionStmt(stmt: ExpressionStmt) {
        resolve(stmt.expression)
    }
    
    internal func visitIfStmt(stmt: IfStmt) {
        resolve(stmt.condition)
        
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
            resolve(expression)
        }
    }
    
    internal func visitInputStmt(stmt: InputStmt) {
        for expression in stmt.expressions {
            resolve(expression)
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
            resolve(stmt.value!)
        }
    }
    
    internal func visitLoopFromStmt(stmt: LoopFromStmt) {
        resolve(stmt.variable)
        resolve(stmt.lRange)
        resolve(stmt.rRange)
        
        beginScope()
        resolve(stmt.statements)
        endScope()
    }
    
    internal func visitWhileStmt(stmt: WhileStmt) {
        let previousLoopState = isInLoop
        
        isInLoop = true
        resolve(stmt.expression)
        
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
    
    private func error(message: String, token: Token) {
        problems.append(.init(message: message, line: token.line, inlineLocation: .init(column: token.column, length: token.lexeme.count)))
    }
    
    private func resolve(_ expression: Expr) {
        expression.accept(visitor: self)
    }
    
    private func resolve(_ statement: Stmt) {
        statement.accept(visitor: self)
    }
    
    private func resolve(_ statements: [Stmt]) {
        for statement in statements {
            resolve(statement)
        }
    }
    
    func resolveAST(statements: [Stmt], symbolTable: inout [SymbolInfo], classTable: inout [ClassInfo]) {
        self.symbolTable = symbolTable
        self.classTable = classTable
        
        isInLoop = false
        currentFunction = .none
        problems = []
        scopes = []
        scopes.append([:])
        resolve(statements)
        
        symbolTable = self.symbolTable
        classTable = self.classTable
    }
}
