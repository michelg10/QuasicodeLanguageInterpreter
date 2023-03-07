class InstanceVariableInitializedInInitializerChecker: StmtThrowVisitor, ExprVisitor {
    private var hasInitializedDict: [Int : Bool] = [:]
    private var totalUninitialized: Int = 0
    private var symbolTable: SymbolTables
    private var reportErrorForReturnStatement: ((_ returnStatement: ReturnStmt, _ message: String) -> Void)
    private var reportErrorForExpression: ((_ expression: Expr, _ message: String) -> Void)
    private var reportEndingError: ((_ message: String) -> Void)
    private var withinClass: Int = 0
    
    private enum AnalysisInterrupts: Error {
        case loopExecutionFlowInterrupt // for break and continue
        case programExitInterrupt // for exit
    }
    
    private struct State {
        var hasInitializedDict: [Int : Bool]
        var totalUninitialized: Int
        var symbolTableId: Int
    }
    
    private func saveState() -> State {
        .init(hasInitializedDict: hasInitializedDict, totalUninitialized: totalUninitialized, symbolTableId: symbolTable.getCurrentTableId())
    }
    private func restoreState(state: State) {
        hasInitializedDict = state.hasInitializedDict
        totalUninitialized = state.totalUninitialized
        symbolTable.gotoTable(state.symbolTableId)
    }
    
    init(
        reportErrorForReturnStatement: @escaping ((ReturnStmt, String) -> Void),
        reportErrorForExpression: @escaping ((Expr, String) -> Void),
        reportEndingError: @escaping ((String) -> Void),
        symbolTable: SymbolTables
    ) {
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
        for element in hasInitializedDict where element.value == false {
            uninitializedVariables.append(element.key)
        }
        return uninitializedVariables
    }
    
    func visitClassStmt(stmt: ClassStmt) {
        // there shouldn't be any
    }
    
    func visitMethodStmt(stmt: MethodStmt) {
        // there shouldn't be any
    }
    
    func visitFunctionStmt(stmt: FunctionStmt) {
        // there shouldn't be any
    }
    
    func visitExpressionStmt(stmt: ExpressionStmt) {
        markVariables(stmt.expression)
    }
    
    private var branchingInitializedSetsStack: [Set<Int>] = []
    
    func visitIfStmt(stmt: IfStmt) throws {
        markVariables(stmt.condition)
        let previousTrackedState = saveState()
        var runningState = previousTrackedState
        branchingInitializedSetsStack.append(Set<Int>())
        let executionTerminatedSet = Set([-1])
        func processBranch(_ stmt: BlockStmt) {
            do {
                try markVariables(stmt)
            } catch AnalysisInterrupts.programExitInterrupt {
                branchingInitializedSetsStack.popLast()
                branchingInitializedSetsStack.append(executionTerminatedSet)
            } catch {
                // do nothing
            }
        }
        processBranch(stmt.thenBranch)
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
            processBranch(elseIfBranch.thenBranch)
        }
        // execute the else branch.
        restoreState(state: runningState)
        branchingInitializedSetsStack.append(Set<Int>())
        if stmt.elseBranch != nil {
            processBranch(stmt.elseBranch!)
        }
        
        // now union the last two
        var runningUnion = branchingInitializedSetsStack.popLast()!
        for _ in 0..<stmt.elseIfBranches.count {
            // intersect with the other branch, as only variables initialized by all branches must be initialized
            if runningUnion == executionTerminatedSet {
                runningUnion = branchingInitializedSetsStack.popLast()!
            } else {
                runningUnion = runningUnion.intersection(branchingInitializedSetsStack.popLast()!)
            }
            // union with the condition, which both cases execute
            if runningUnion != executionTerminatedSet {
                // if both branches result in program termination, then the condition really doesn't matter. so only union the condition if there is no program termination
                runningUnion = runningUnion.union(branchingInitializedSetsStack.popLast()!)
            }
        }
        if runningUnion == executionTerminatedSet {
            runningUnion = branchingInitializedSetsStack.popLast()!
        } else {
            runningUnion = runningUnion.intersection(branchingInitializedSetsStack.popLast()!)
        }
        
        restoreState(state: previousTrackedState)
        if runningUnion == executionTerminatedSet {
            throw AnalysisInterrupts.programExitInterrupt
        } else {
            for remaining in runningUnion {
                markAsInitialized(remaining)
            }
        }
    }
    
    private func processLoopBlockStmt(_ stmt: BlockStmt) {
        let state = saveState()
        catchErrorClosure {
            try markVariables(stmt)
        }
        restoreState(state: state)
    }
    
    func visitOutputStmt(stmt: OutputStmt) {
        markVariables(stmt.expressions)
    }
    
    func visitInputStmt(stmt: InputStmt) {
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
    
    func visitReturnStmt(stmt: ReturnStmt) {
        if stmt.value != nil {
            markVariables(stmt.value!)
        }
        // check and report errors
        if !finishedInitialization() {
            reportError(stmt, message: "Return from initializer without initializing all stored properties")
        }
    }
    
    func visitLoopFromStmt(stmt: LoopFromStmt) {
        markVariables(stmt.lRange)
        markVariables(stmt.rRange)
        processLoopBlockStmt(stmt.body)
    }
    
    func visitWhileStmt(stmt: WhileStmt) {
        markVariables(stmt.expression)
        processLoopBlockStmt(stmt.body)
    }
    
    func visitBreakStmt(stmt: BreakStmt) throws {
        // do not analyze anything after this
        throw AnalysisInterrupts.loopExecutionFlowInterrupt
    }
    
    func visitContinueStmt(stmt: ContinueStmt) throws {
        // like the break statement
        throw AnalysisInterrupts.loopExecutionFlowInterrupt
    }
    
    func visitBlockStmt(stmt: BlockStmt) throws {
        if stmt.scopeIndex != nil {
            let previousSymbolTablePosition = symbolTable.getCurrentTableId()
            symbolTable.gotoTable(stmt.scopeIndex!)
            defer {
                symbolTable.gotoTable(previousSymbolTablePosition)
            }
            try markVariables(stmt.statements)
        }
    }
    
    func visitExitStmt(stmt: ExitStmt) throws {
        // behavior when an exit statement is seen: just ignore this branch of code entirely. it doesn't matter if anything happens anyway
        throw AnalysisInterrupts.programExitInterrupt
    }
    
    func visitMultiSetStmt(stmt: MultiSetStmt) throws {
        for setStmt in stmt.setStmts {
            try markVariables(setStmt)
        }
    }
    
    func visitSetStmt(stmt: SetStmt) throws {
        // possible expressions to set to: VariableToSetExpr, GetExpr, SubscriptExpr, SuperExpr
        // TODO: Implement this for SuperExprs because these are *super* (haha) messed up right now
        
        func markSet(expr: Expr) {
            if expr is VariableToSetExpr {
                let expr = expr as! VariableToSetExpr
                markSet(expr: expr.to)
            } else if expr is VariableExpr {
                let expr = expr as! VariableExpr
                if expr.symbolTableIndex != nil {
                    let symbol = symbolTable.getSymbol(id: expr.symbolTableIndex!) as! VariableSymbol
                    if symbol.variableType == .instance {
                        markAsInitialized(symbol.id)
                    }
                }
            } else if expr is GetExpr {
                let expr = expr as! GetExpr
                if expr.object is ThisExpr {
                    markAsInitialized(expr.propertyId!)
                } else {
                    markVariables(expr.object)
                }
            } else if expr is SubscriptExpr {
                markVariables(expr)
            } else if expr is SuperExpr {
                // TODO: Implement this
            } else {
                preconditionFailure("Expected SetStmt to set to an expression of type VariableToSetExpr, VariableExpr, GetExpr, SubscriptExpr, or SuperExpr, instead got \(type(of: expr)).")
            }
        }
        
        markVariables(stmt.value)
        
        for chained in stmt.chained {
            markSet(expr: chained)
        }
        markSet(expr: stmt.left)
    }
    
    
    func visitGroupingExpr(expr: GroupingExpr) {
        markVariables(expr.expression)
    }
    
    func visitLiteralExpr(expr: LiteralExpr) {
        // do nothing
    }
    
    func visitArrayLiteralExpr(expr: ArrayLiteralExpr) {
        markVariables(expr.values)
    }
    
    func visitStaticClassExpr(expr: StaticClassExpr) {
        // do nothing
    }
    
    func visitThisExpr(expr: ThisExpr) {
        if !finishedInitialization() {
            reportError(expr, message: "'this' is unavailable until all stored properties are initialized")
        }
    }
    
    func visitSuperExpr(expr: SuperExpr) {
        // do nothing
    }
    
    func visitVariableExpr(expr: VariableExpr) {
        let index = expr.symbolTableIndex
        if index != nil {
            let symbol = symbolTable.getSymbol(id: index!) as! VariableSymbol
            if symbol.variableType == .instance {
                assertIsMarked(variableId: symbol.id, expr: expr)
            }
        }
    }
    
    func visitSubscriptExpr(expr: SubscriptExpr) {
        markVariables(expr.expression)
        markVariables(expr.index)
    }
    
    func visitCallExpr(expr: CallExpr) {
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
    
    func visitGetExpr(expr: GetExpr) {
        // as long as there is a get expression, as long as it's not on a ThisExpr, it *must* be marked!
        if expr.object is ThisExpr {
            if expr.propertyId != nil {
                assertIsMarked(variableId: expr.propertyId!, expr: expr)
                return
            }
        }
        markVariables(expr.object)
    }
    
    func visitUnaryExpr(expr: UnaryExpr) {
        markVariables(expr.right)
    }
    
    func visitCastExpr(expr: CastExpr) {
        markVariables(expr.value)
    }
    
    func visitArrayAllocationExpr(expr: ArrayAllocationExpr) {
        markVariables(expr.capacity)
    }
    
    func visitClassAllocationExpr(expr: ClassAllocationExpr) {
        markVariables(expr.arguments)
    }
    
    func visitBinaryExpr(expr: BinaryExpr) {
        markVariables(expr.left)
        markVariables(expr.right)
    }
    
    func visitLogicalExpr(expr: LogicalExpr) {
        markVariables(expr.left)
        // the right might not always be executed because logical operators are short-circuited
        let state = saveState()
        markVariables(expr.right)
        restoreState(state: state)
    }
    
    func visitVariableToSetExpr(expr: VariableToSetExpr) {
        // this shouldn't happen because everything should be handled by the SetExpr
        preconditionFailure("VariableToSetExpr should not be visited: Should've been handled by the SetExpr!")
    }
    
    func visitIsTypeExpr(expr: IsTypeExpr) {
        markVariables(expr.left)
    }
    
    func visitImplicitCastExpr(expr: ImplicitCastExpr) {
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
    private func markVariables(_ statement: Stmt) throws {
        try statement.accept(visitor: self)
    }
    private func markVariables(_ statements: [Stmt]) throws {
        for statement in statements {
            try statement.accept(visitor: self)
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
            totalUninitialized += 1
        }
        hasInitializedDict[variableId] = false
    }
    
    public func checkStatements(_ statements: [Stmt], withinClass: Int) {
        self.withinClass = withinClass
        // this is for exit statements
        catchErrorClosure {
            for statement in statements {
                try markVariables(statement)
            }
            if !finishedInitialization() {
                reportEndingError(message: "Implicit return from initializer without initializing all stored properties")
            }
        }
    }
}
