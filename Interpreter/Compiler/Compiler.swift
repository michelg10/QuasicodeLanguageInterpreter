class Compiler: ExprVisitor, StmtVisitor {
    var compilingChunk: UnsafeMutablePointer<Chunk>!
    
    internal func currentChunk() -> UnsafeMutablePointer<Chunk>! {
        return compilingChunk
    }
    
    internal func visitGroupingExpr(expr: GroupingExpr) {
        
    }
    
    internal func visitLiteralExpr(expr: LiteralExpr) {
        
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
        writeInstructionToChunk(chunk: currentChunk(), op: .OP_return, line: -1)
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
