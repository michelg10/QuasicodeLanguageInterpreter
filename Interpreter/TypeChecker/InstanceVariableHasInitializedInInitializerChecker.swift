class InstanceVariableHasInitializedInInitializerChecker: StmtVisitor, ExprVisitor {
    private var hasInitializedDict: [Int : Bool] = [:]
    private var totalUninitialized: Int = 0
    private var symbolTable: SymbolTables
    private var reportErrorForReturnStatement: ((_ returnStatement: ReturnStmt, _ message: String) -> Void)
    private var reportErrorForExpression: ((_ expression: Expr, _ message: String) -> Void)
    private var reportEndingError: ((_ message: String) -> Void)
    private var withinClass: Int = 0
    
    typealias State = ([Int : Bool], Int, Int)
    private func saveState() -> State {
        return (hasInitializedDict, totalUninitialized, symbolTable.getCurrentTableId())
    }
    private func restoreState(state: State) {
        hasInitializedDict = state.0
        totalUninitialized = state.1
        symbolTable.gotoTable(state.2)
    }
    
    internal init(reportErrorForReturnStatement: @escaping ((ReturnStmt, String) -> Void), reportErrorForExpression: @escaping ((Expr, String) -> Void), reportEndingError: @escaping ((String) -> Void), symbolTable: SymbolTables) {
        self.reportErrorForReturnStatement = reportErrorForReturnStatement
        self.reportErrorForExpression = reportErrorForExpression
        self.reportEndingError = reportEndingError
        self.symbolTable = symbolTable
    }
    
    private func reportError(_ returnStatement: ReturnStmt, message: String) {
        reportErrorForReturnStatement(returnStatement, message)
    }
    private func reportError(_ expression: Expr, message: String) {
        reportErrorForExpression(expression, message)
    }
    private func reportEndingError(message: String) {
        reportEndingError(message)
    }
    
    private func getUninitialized() -> [Int] {
        var uninitializedVariables: [Int] = []
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
    
    private var branchingInitializedSetsStack: [Set<Int>] = []
    
    internal func visitIfStmt(stmt: IfStmt) {
        markVariables(stmt.condition)
        let previousTrackedState = saveState()
        var runningState = previousTrackedState
        branchingInitializedSetsStack.append(Set<Int>())
        markVariables(stmt.thenBranch)
        // else if conditions MUST be executed in the else branch. thus, after some on-paper derivations, i came up with this algorithm:
        for elseIfBranch in stmt.elseIfBranches {
            // restore
            restoreState(state: runningState)
            // execute
            branchingInitializedSetsStack.append(Set<Int>())
            markVariables(elseIfBranch.condition)
            // save state
            runningState = saveState()
            // execute
            branchingInitializedSetsStack.append(Set<Int>())
            markVariables(elseIfBranch.thenBranch)
        }
        // execute the else branch.
        restoreState(state: runningState)
        branchingInitializedSetsStack.append(Set<Int>())
        if stmt.elseBranch != nil {
            markVariables(stmt.elseBranch!)
        }
        
        // now union the last two
        var runningUnion = branchingInitializedSetsStack.popLast()!
        for _ in 0..<stmt.elseIfBranches.count {
            runningUnion = runningUnion.intersection(branchingInitializedSetsStack.popLast()!)
            runningUnion = runningUnion.union(branchingInitializedSetsStack.popLast()!)
        }
        runningUnion = runningUnion.intersection(branchingInitializedSetsStack.popLast()!)
        
        restoreState(state: previousTrackedState)
        for remaining in runningUnion {
            markAsInitialized(remaining)
        }
    }
    
    private func processNonbranchingBlockStmt(_ stmt: BlockStmt) {
        let state = saveState()
        markVariables(stmt)
        restoreState(state: state)
    }
    
    internal func visitOutputStmt(stmt: OutputStmt) {
        markVariables(stmt.expressions)
    }
    
    internal func visitInputStmt(stmt: InputStmt) {
        if stmt is GetExpr && (stmt as! GetExpr).object is VariableExpr && ((stmt as! GetExpr).object as! VariableExpr).name.lexeme == "this" {
            guard let id = (stmt as! GetExpr).propertyId else {
                return
            }
            markAsInitialized((stmt as! GetExpr).propertyId!)
            return
        }
        if stmt is VariableExpr {
            let stmt = stmt as! VariableExpr
            if stmt.symbolTableIndex != nil {
                let symbol = symbolTable.getSymbol(id: stmt.symbolTableIndex!) as! VariableSymbol
                if symbol.variableType == .instance {
                    markAsInitialized(symbol.id)
                }
            }
        }
        markVariables(stmt.expressions)
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
        processNonbranchingBlockStmt(stmt.body)
    }
    
    internal func visitWhileStmt(stmt: WhileStmt) {
        markVariables(stmt.expression)
        processNonbranchingBlockStmt(stmt.body)
    }
    
    internal func visitBreakStmt(stmt: BreakStmt) {
        // TODO
        // do nothing
    }
    
    internal func visitContinueStmt(stmt: ContinueStmt) {
        // do nothing
    }
    
    internal func visitBlockStmt(stmt: BlockStmt) {
        if stmt.scopeIndex != nil {
            let previousSymbolTablePosition = symbolTable.getCurrentTableId()
            symbolTable.gotoTable(stmt.scopeIndex!)
            defer {
                symbolTable.gotoTable(previousSymbolTablePosition)
            }
            markVariables(stmt.statements)
        }
    }
    
    func visitExitStmt(stmt: ExitStmt) {
        // TODO
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
        if !finishedInitialization() {
            reportError(expr, message: "'this' is unavailable until all stored properties are initialized")
        }
    }
    
    internal func visitSuperExpr(expr: SuperExpr) {
        // do nothing
    }
    
    internal func visitVariableExpr(expr: VariableExpr) {
        let index = expr.symbolTableIndex
        if index != nil {
            let symbol = symbolTable.getSymbol(id: index!) as! VariableSymbol
            if symbol.variableType == .instance {
                assertIsMarked(variableId: symbol.id, expr: expr)
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
        // polymorphic calls can't be on an instance method of the current class
        if expr.uniqueFunctionCall != nil {
            let symbol = symbolTable.getSymbol(id: expr.uniqueFunctionCall!) as! FunctionLikeSymbol
            if symbol is MethodSymbol {
                let symbol = symbol as! MethodSymbol
                if symbol.isStatic == false {
                    var isOnClassInstanceMethodCall = false
                    if expr.object == nil || expr.object is ThisExpr {
                        isOnClassInstanceMethodCall = true
                    }
                    if expr.object is VariableExpr && (expr.object as! VariableExpr).name.lexeme == "super" {
                        isOnClassInstanceMethodCall = true
                    }
                    if isOnClassInstanceMethodCall {
                        reportError(expr, message: "Instance methods cannot be called before all stored properties are initialized")
                    }
                }
            }
        }
    }
    
    internal func visitGetExpr(expr: GetExpr) {
        // as long as there is a get expression, as long as it's not on a ThisExpr, it *must* be marked!
        if expr.object is ThisExpr {
            if expr.propertyId != nil {
                assertIsMarked(variableId: expr.propertyId!, expr: expr)
                return
            }
        }
        markVariables(expr.object)
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
        let state = saveState()
        markVariables(expr.right)
        restoreState(state: state)
    }
    
    internal func visitSetExpr(expr: SetExpr) {
        markVariables(expr.value)
        // the only exception should be: set object is this.?
        if expr.to is GetExpr {
            let to = expr.to as! GetExpr
            if to.object is ThisExpr {
                markAsInitialized(to.propertyId!)
                return
            }
        }
        markVariables(expr.to)
    }
    
    internal func visitAssignExpr(expr: AssignExpr) {
        markVariables(expr.value)
        if expr.to.symbolTableIndex != nil {
            let symbol = symbolTable.getSymbol(id: expr.to.symbolTableIndex!) as! VariableSymbol
            if symbol.variableType == .instance {
                markAsInitialized(symbol.id)
            }
        }
    }
    
    internal func visitIsTypeExpr(expr: IsTypeExpr) {
        markVariables(expr.left)
    }
    
    internal func visitImplicitCastExpr(expr: ImplicitCastExpr) {
        markVariables(expr.expression)
    }
    
    private func markAsInitialized(_ variableId: Int) {
        if hasInitializedDict[variableId] == false {
            if !branchingInitializedSetsStack.isEmpty {
                var top = branchingInitializedSetsStack.popLast()!
                top.insert(variableId)
                branchingInitializedSetsStack.append(top)
            }
            hasInitializedDict[variableId] = true
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
    
    private func assertIsMarked(variableId: Int, expr: Expr) {
        if hasInitializedDict[variableId] == false {
            let symbolName = symbolTable.getSymbol(id: variableId).name
            reportError(expr, message: "Variable 'this.\(symbolName)' used before being initialized")
        }
    }
    
    public func trackVariable(variableId: Int) {
        if hasInitializedDict[variableId] == nil {
            totalUninitialized+=1
        }
        hasInitializedDict[variableId] = false
    }
    
    public func checkStatements(_ statements: [Stmt], withinClass: Int) {
        self.withinClass = withinClass
        for statement in statements {
            markVariables(statement)
        }
        if !finishedInitialization() {
            reportEndingError(message: "Implicit return from initializer without initializing all stored properties")
        }
    }
}
