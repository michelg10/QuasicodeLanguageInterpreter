class Compiler: ExprVisitor, StmtVisitor {
    var compilingChunk: UnsafeMutablePointer<Chunk>!
    
    internal func currentChunk() -> UnsafeMutablePointer<Chunk>! {
        return compilingChunk
    }
    
    internal func visitGroupingExpr(expr: GroupingExpr) {
        compile(expr.expression)
    }
    
    private func writeInstructionToChunk(op: OpCode, expr: Expr) {
        Interpreter.writeInstructionToChunk(chunk: currentChunk(), op: op, line: expr.startLocation.line)
    }
    
    private func writeLongToChunk(data: UInt64, expr: Expr) {
        Interpreter.writeLongToChunk(chunk: currentChunk(), data: data, line: expr.startLocation.line)
    }
    
    internal func visitLiteralExpr(expr: LiteralExpr) {
        // TODO: Strings
        switch expr.type! {
        case is QsInt:
            writeInstructionToChunk(op: .OP_loadEmbeddedLongConstant, expr: expr)
            writeLongToChunk(data: UInt64(expr.value as! Int), expr: expr)
        case is QsDouble:
            writeInstructionToChunk(op: .OP_loadEmbeddedLongConstant, expr: expr)
            writeLongToChunk(data: (expr.value as! Double).bitPattern, expr: expr)
        case is QsBoolean:
            let value = expr.value as! Bool
            if value {
                writeInstructionToChunk(op: .OP_true, expr: expr)
            } else {
                writeInstructionToChunk(op: .OP_false, expr: expr)
            }
        default:
            assertionFailure("Unexpected literal type \(printType(expr.type))")
        }
    }
    
    internal func visitArrayLiteralExpr(expr: ArrayLiteralExpr) {
        
    }
    
    internal func visitStaticClassExpr(expr: StaticClassExpr) {
        
    }
    
    internal func visitThisExpr(expr: ThisExpr) {
        
    }
    
    internal func visitSuperExpr(expr: SuperExpr) {
        
    }
    
    internal func visitVariableExpr(expr: VariableExpr) {
        
    }
    
    internal func visitSubscriptExpr(expr: SubscriptExpr) {
        
    }
    
    internal func visitCallExpr(expr: CallExpr) {
        
    }
    
    internal func visitGetExpr(expr: GetExpr) {
        
    }
    
    internal func visitUnaryExpr(expr: UnaryExpr) {
        switch expr.opr.tokenType {
        case .NOT:
            writeInstructionToChunk(op: .OP_not, expr: <#T##Expr#>)
        case .MINUS:
        default:
        }
    }
    
    internal func visitCastExpr(expr: CastExpr) {
        
    }
    
    internal func visitArrayAllocationExpr(expr: ArrayAllocationExpr) {
        
    }
    
    internal func visitClassAllocationExpr(expr: ClassAllocationExpr) {
        
    }
    
    internal func visitBinaryExpr(expr: BinaryExpr) {
        
    }
    
    internal func visitLogicalExpr(expr: LogicalExpr) {
        
    }
    
    internal func visitSetExpr(expr: SetExpr) {
        
    }
    
    internal func visitAssignExpr(expr: AssignExpr) {
        
    }
    
    internal func visitIsTypeExpr(expr: IsTypeExpr) {
        
    }
    
    internal func visitImplicitCastExpr(expr: ImplicitCastExpr) {
        
    }
    
    internal func visitClassStmt(stmt: ClassStmt) {
        
    }
    
    internal func visitMethodStmt(stmt: MethodStmt) {
        
    }
    
    internal func visitFunctionStmt(stmt: FunctionStmt) {
        
    }
    
    internal func visitExpressionStmt(stmt: ExpressionStmt) {
        compile(stmt.expression)
    }
    
    internal func visitIfStmt(stmt: IfStmt) {
        
    }
    
    internal func visitOutputStmt(stmt: OutputStmt) {
        
    }
    
    internal func visitInputStmt(stmt: InputStmt) {
        
    }
    
    internal func visitReturnStmt(stmt: ReturnStmt) {
        
    }
    
    internal func visitLoopFromStmt(stmt: LoopFromStmt) {
        
    }
    
    internal func visitWhileStmt(stmt: WhileStmt) {
        
    }
    
    internal func visitBreakStmt(stmt: BreakStmt) {
        
    }
    
    internal func visitContinueStmt(stmt: ContinueStmt) {
        
    }
    
    internal func visitBlockStmt(stmt: BlockStmt) {
        
    }
    
    
    private func endCompiler() {
        Interpreter.writeInstructionToChunk(chunk: currentChunk(), op: .OP_return, line: 0)
    }
    
    private func compile(_ stmt: Stmt) {
        stmt.accept(visitor: self)
    }
    
    private func compile(_ expr: Expr) {
        expr.accept(visitor: self)
    }
    
    public func compileAst(stmts: [Stmt]) -> UnsafeMutablePointer<Chunk>! {
        compilingChunk = initChunk()
        
        for stmt in stmts {
            compile(stmt)
        }
        
        // end it off
        endCompiler()
        
        return compilingChunk
    }
}
