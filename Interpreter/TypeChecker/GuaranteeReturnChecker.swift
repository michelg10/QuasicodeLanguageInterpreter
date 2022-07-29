class GaurenteeReturnChecker: StmtThrowVisitor {
    private var hasReturnedStack: [Bool] = []
    private var reportError: (() -> Void)
    
    init(reportError: @escaping (() -> Void)) {
        self.reportError = reportError
    }
    
    private enum AnalysisInterrupts: Error {
        case ProgramExitInterrupt // for exit
        case HasReturnedInterrupt
    }
    
    internal func visitClassStmt(stmt: ClassStmt) {
        // impossible
    }
    
    internal func visitMethodStmt(stmt: MethodStmt) {
        // impossible
    }
    
    internal func visitFunctionStmt(stmt: FunctionStmt) {
        // impossible
    }
    
    internal func visitExpressionStmt(stmt: ExpressionStmt) {
        // do nothing
    }
    
    internal func visitIfStmt(stmt: IfStmt) throws {
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
        for _ in 0..<stmt.elseIfBranches.count+2 {
            allPathsReturn = allPathsReturn && hasReturnedStack.popLast()!
        }
        
        if allPathsReturn {
            hasReturnedStack.popLast()
            hasReturnedStack.append(true)
            throw AnalysisInterrupts.HasReturnedInterrupt
        }
    }
    
    internal func visitOutputStmt(stmt: OutputStmt) {
        // do nothing
    }
    
    internal func visitInputStmt(stmt: InputStmt) {
        // do nothing
    }
    
    internal func visitReturnStmt(stmt: ReturnStmt) throws {
        hasReturnedStack.popLast()
        hasReturnedStack.append(true)
        throw AnalysisInterrupts.HasReturnedInterrupt
    }
    
    internal func visitLoopFromStmt(stmt: LoopFromStmt) {
        // do nothing
    }
    
    internal func visitWhileStmt(stmt: WhileStmt) {
        // do nothing
    }
    
    internal func visitBreakStmt(stmt: BreakStmt) {
        // do nothing
    }
    
    internal func visitContinueStmt(stmt: ContinueStmt) {
        // do nothing
    }
    
    internal func visitBlockStmt(stmt: BlockStmt) throws {
        try checkReturn(stmt.statements)
    }
    
    internal func visitExitStmt(stmt: ExitStmt) throws {
        // by all means, it has returned
        hasReturnedStack.popLast()
        hasReturnedStack.append(true)
        throw AnalysisInterrupts.ProgramExitInterrupt
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
