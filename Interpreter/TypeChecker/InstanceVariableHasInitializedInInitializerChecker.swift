class InstanceVariableHasInitializedInInitializerChecker: StmtVisitor, ExprVisitor {
    private var hasInitializedDict: [String : Bool] = [:]
    private var totalUninitialized: Int = 0
    private var symbolTable: SymbolTables
    private var reportErrorForStatement: ((_ statement: Stmt, _ message: String) -> Void)
    private var reportErrorForExpression: ((_ expression: Expr, _ message: String) -> Void)
    private var isInControlFlow: Bool = false
    private var withinClass: Int = 0
    
    internal init(reportErrorForStatement: @escaping ((Stmt, String) -> Void), reportErrorForExpression: @escaping ((Expr, String) -> Void), symbolTable: SymbolTables) {
        self.reportErrorForStatement = reportErrorForStatement
        self.reportErrorForExpression = reportErrorForExpression
        self.symbolTable = symbolTable
    }
    
    private func reportError(_ statement: Stmt, message: String) {
        reportErrorForStatement(statement, message)
    }
    private func reportError(_ expression: Expr, message: String) {
        reportErrorForExpression(expression, message)
    }
    
    private func getUninitialized() -> [String] {
        var uninitializedVariables: [String] = []
        for element in hasInitializedDict {
            if element.value == false {
                uninitializedVariables.append(element.key)
            }
        }
        return uninitializedVariables
    }
    
    internal func visitClassStmt(stmt: ClassStmt) {
        // there shouldn't be any
    }
    
    internal func visitMethodStmt(stmt: MethodStmt) {
        // there shouldn't be any
    }
    
    internal func visitFunctionStmt(stmt: FunctionStmt) {
        // there shouldn't be any
    }
    
    internal func visitExpressionStmt(stmt: ExpressionStmt) {
        markVariables(stmt.expression)
    }
    
    internal func visitIfStmt(stmt: IfStmt) {
        markVariables(stmt.condition)
        let previousIsInControlFlow = isInControlFlow
        isInControlFlow = true
        
        markVariables(stmt.thenBranch)
        markVariables(stmt.elseIfBranches)
        if stmt.elseBranch != nil {
            markVariables(stmt.elseBranch!)
        }
        
        isInControlFlow = previousIsInControlFlow
    }
    
    internal func visitOutputStmt(stmt: OutputStmt) {
        markVariables(stmt.expressions)
    }
    
    internal func visitInputStmt(stmt: InputStmt) {
        markVariables(stmt.expressions)
        markAsInitialized(stmt.expressions)
    }
    
    internal func visitReturnStmt(stmt: ReturnStmt) {
        if stmt.value != nil {
            markVariables(stmt.value!)
        }
        // check and report errors
        if !finishedInitialization() {
            reportError(stmt, message: "Return from initializer without initializing all stored properties")
        }
    }
    
    internal func visitLoopFromStmt(stmt: LoopFromStmt) {
        markVariables(stmt.lRange)
        markVariables(stmt.rRange)
        markVariables(stmt.body)
    }
    
    internal func visitWhileStmt(stmt: WhileStmt) {
        markVariables(stmt.expression)
        markVariables(stmt.body)
    }
    
    internal func visitBreakStmt(stmt: BreakStmt) {
        // do nothing
    }
    
    internal func visitContinueStmt(stmt: ContinueStmt) {
        // do nothing
    }
    
    internal func visitBlockStmt(stmt: BlockStmt) {
        let previousIsInControlFlow = isInControlFlow
        isInControlFlow = true
        if stmt.scopeIndex != nil {
            symbolTable.gotoTable(stmt.scopeIndex!)
            markVariables(stmt.statements)
            symbolTable.exitScope()
        }
        isInControlFlow = previousIsInControlFlow
    }
    
    internal func visitGroupingExpr(expr: GroupingExpr) {
        markVariables(expr.expression)
    }
    
    internal func visitLiteralExpr(expr: LiteralExpr) {
        // do nothing
    }
    
    internal func visitArrayLiteralExpr(expr: ArrayLiteralExpr) {
        markVariables(expr.values)
    }
    
    internal func visitStaticClassExpr(expr: StaticClassExpr) {
        // do nothing
    }
    
    internal func visitThisExpr(expr: ThisExpr) {
        // do nothing
    }
    
    internal func visitSuperExpr(expr: SuperExpr) {
        // do nothing
    }
    
    internal func visitVariableExpr(expr: VariableExpr) {
        let index = expr.symbolTableIndex
        if index != nil {
            let symbol = symbolTable.getSymbol(id: index!) as! VariableSymbol
            if symbol.variableType == .local {
                if hasInitializedDict[symbol.name] == false {
                    reportError(expr, message: "Variable 'this.\(symbol.name)' used before being initialized")
                }
            }
        }
    }
    
    internal func visitSubscriptExpr(expr: SubscriptExpr) {
        markVariables(expr.expression)
        markVariables(expr.index)
    }
    
    internal func visitCallExpr(expr: CallExpr) {
        if expr.object != nil {
            markVariables(expr.object!)
        }
        markVariables(expr.arguments)
        if expr.uniqueFunctionCall != nil {
            let symbol = symbolTable.getSymbol(id: expr.uniqueFunctionCall!)
            if symbol is MethodSymbol {
                let symbol = symbol as! MethodSymbol
                
//                if symbol
                reportError(expr, message: "Methods cannot be called before all stored properties are initialized")
            }
        } else if expr.polymorphicCallClassIdToIdDict != nil {
            // its definitely a method call
        }
    }
    
    internal func visitGetExpr(expr: GetExpr) {
        markVariables(expr.object)
        if expr.object is ThisExpr {
            expr.accessingInstanceVariable = symbolTable.getSymbolIndex(name: "this")
        } else if expr.object is VariableExpr {
            let object = expr.object as! VariableExpr
            if object.symbolTableIndex != nil {
                expr.accessingInstanceVariable = object.symbolTableIndex
            }
        } else if expr.object is GetExpr {
            let object = expr.object as! GetExpr
            expr.accessingInstanceVariable = object.accessingInstanceVariable
        } else if expr.object is SubscriptExpr {
            let object = expr.object as! SubscriptExpr
            expr.accessingInstanceVariable = object.accessingInstanceVariable
        }
    }
    
    internal func visitUnaryExpr(expr: UnaryExpr) {
        markVariables(expr.right)
    }
    
    internal func visitCastExpr(expr: CastExpr) {
        markVariables(expr.value)
    }
    
    internal func visitArrayAllocationExpr(expr: ArrayAllocationExpr) {
        markVariables(expr.capacity)
    }
    
    internal func visitClassAllocationExpr(expr: ClassAllocationExpr) {
        markVariables(expr.arguments)
    }
    
    internal func visitBinaryExpr(expr: BinaryExpr) {
        markVariables(expr.left)
        markVariables(expr.right)
    }
    
    internal func visitLogicalExpr(expr: LogicalExpr) {
        markVariables(expr.left)
        // the right might not always be executed because logical operators are short-circuited
        let previousIsInControlFlow = isInControlFlow
        isInControlFlow = true
        markVariables(expr.right)
        isInControlFlow = previousIsInControlFlow
    }
    
    internal func visitSetExpr(expr: SetExpr) {
        markVariables(expr.value)
        // the only exception should be : set object is this.?
        if expr.to is GetExpr {
            let to = expr.to as! GetExpr
            if to.object is ThisExpr {
                markAsInitialized(to.property.lexeme)
            } else {
                markVariables(expr.to)
            }
        } else {
            markVariables(expr.to)
        }
    }
    
    internal func visitAssignExpr(expr: AssignExpr) {
        markVariables(expr.value)
        if expr.to.symbolTableIndex != nil {
            let symbol = symbolTable.getSymbol(id: expr.to.symbolTableIndex!) as! VariableSymbol
            if symbol.variableType == .instance {
                markAsInitialized(symbol.name)
            }
        }
    }
    
    internal func visitIsTypeExpr(expr: IsTypeExpr) {
        markVariables(expr.left)
    }
    
    internal func visitImplicitCastExpr(expr: ImplicitCastExpr) {
        markVariables(expr.expression)
    }
    
    private func markAsInitialized(_ exprs: [Expr]) {
        for expr in exprs {
            markAsInitialized(expr)
        }
    }
    private func markAsInitialized(_ expr: Expr) {
        
    }
    private func markAsInitialized(_ variable: String) {
        if hasInitializedDict[variable] == false {
            hasInitializedDict[variable] = true
            totalUninitialized -= 1
        }
    }
    private func markVariables(_ expr: Expr) {
        expr.accept(visitor: self)
    }
    private func markVariables(_ exprs: [Expr]) {
        for expr in exprs {
            expr.accept(visitor: self)
        }
    }
    private func markVariables(_ statement: Stmt) {
        statement.accept(visitor: self)
    }
    private func markVariables(_ statements: [Stmt]) {
        for statement in statements {
            statement.accept(visitor: self)
        }
    }
    
    private func finishedInitialization() -> Bool {
        return totalUninitialized == 0
    }
    
    public func trackVariable(_ name: String) {
        if hasInitializedDict[name] == nil {
            totalUninitialized+=1
        }
        hasInitializedDict[name] = false
    }
    
    public func checkStatements(_ statements: [Stmt], withinClass: Int) {
        isInControlFlow = false
        self.withinClass = withinClass
    }
}
