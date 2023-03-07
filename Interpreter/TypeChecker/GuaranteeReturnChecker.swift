internal class GaurenteeReturnChecker: StmtThrowVisitor {
    private var hasReturnedStack: [Bool] = []
    private var reportError: (() -> Void)
    
    init(reportError: @escaping (() -> Void)) {
        self.reportError = reportError
    }
    
    private enum AnalysisInterrupts: Error {
        case programExitInterrupt // for exit
        case hasReturnedInterrupt
    }
    
    func visitClassStmt(stmt: ClassStmt) {
        // impossible
    }
    
    func visitMethodStmt(stmt: MethodStmt) {
        // impossible
    }
    
    func visitFunctionStmt(stmt: FunctionStmt) {
        // impossible
    }
    
    func visitExpressionStmt(stmt: ExpressionStmt) {
        // do nothing
    }
    
    func visitMultiSetStmt(stmt: MultiSetStmt) throws {
        // do nothing
    }
    
    func visitSetStmt(stmt: SetStmt) throws {
        // do nothing
    }
    
    func visitIfStmt(stmt: IfStmt) throws {
        func processBranch(_ stmt: BlockStmt) {
            do {
                try checkReturn(stmt)
            } catch is AnalysisInterrupts {
                // do nothing
            } catch {
                // nothing else
            }
        }
        
        hasReturnedStack.append(false)
        processBranch(stmt.thenBranch)
        for elseIfBranch in stmt.elseIfBranches {
            hasReturnedStack.append(false)
            processBranch(elseIfBranch.thenBranch)
        }
        hasReturnedStack.append(false)
        if stmt.elseBranch != nil {
            processBranch(stmt.elseBranch!)
        }
        
        var allPathsReturn = true
        for _ in 0 ..< stmt.elseIfBranches.count + 2 {
            allPathsReturn = allPathsReturn && hasReturnedStack.popLast()!
        }
        
        if allPathsReturn {
            hasReturnedStack.popLast()
            hasReturnedStack.append(true)
            throw AnalysisInterrupts.hasReturnedInterrupt
        }
    }
    
    func visitOutputStmt(stmt: OutputStmt) {
        // do nothing
    }
    
    func visitInputStmt(stmt: InputStmt) {
        // do nothing
    }
    
    func visitReturnStmt(stmt: ReturnStmt) throws {
        hasReturnedStack.popLast()
        hasReturnedStack.append(true)
        throw AnalysisInterrupts.hasReturnedInterrupt
    }
    
    func visitLoopFromStmt(stmt: LoopFromStmt) {
        // do nothing
    }
    
    func visitWhileStmt(stmt: WhileStmt) {
        // do nothing
    }
    
    func visitBreakStmt(stmt: BreakStmt) {
        // do nothing
    }
    
    func visitContinueStmt(stmt: ContinueStmt) {
        // do nothing
    }
    
    func visitBlockStmt(stmt: BlockStmt) throws {
        try checkReturn(stmt.statements)
    }
    
    func visitExitStmt(stmt: ExitStmt) throws {
        // by all means, it has returned
        hasReturnedStack.popLast()
        hasReturnedStack.append(true)
        throw AnalysisInterrupts.programExitInterrupt
    }
    
    private func checkReturn(_ stmt: Stmt) throws {
        try stmt.accept(visitor: self)
    }
    
    private func checkReturn(_ stmt: [Stmt]) throws {
        for stmt in stmt {
            try checkReturn(stmt)
        }
    }
    
    public func checkStatements(_ statements: [Stmt]) {
        hasReturnedStack = [false]
        
        catchErrorClosure {
            for statement in statements {
                try checkReturn(statement)
            }
            if !hasReturnedStack[0] {
                reportError()
            }
        }
    }
}
