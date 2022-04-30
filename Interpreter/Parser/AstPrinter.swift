class AstPrinter: ExprStringVisitor, StmtStringVisitor {
    func visitGroupingExprString(expr: GroupingExpr) -> String {
        return ""
    }
    
    func visitLiteralExprString(expr: LiteralExpr) -> String {
        return ""
    }
    
    func visitThisExprString(expr: ThisExpr) -> String {
        return ""
    }
    
    func visitSuperExprString(expr: SuperExpr) -> String {
        return ""
    }
    
    func visitVariableExprString(expr: VariableExpr) -> String {
        return ""
    }
    
    func visitSubscriptExprString(expr: SubscriptExpr) -> String {
        return ""
    }
    
    func visitCallExprString(expr: CallExpr) -> String {
        return ""
    }
    
    func visitGetExprString(expr: GetExpr) -> String {
        return ""
    }
    
    func visitUnaryExprString(expr: UnaryExpr) -> String {
        return ""
    }
    
    func visitCastExprString(expr: CastExpr) -> String {
        return ""
    }
    
    func visitArrayAllocationExprString(expr: ArrayAllocationExpr) -> String {
        return ""
    }
    
    func visitClassAllocationExprString(expr: ClassAllocationExpr) -> String {
        return ""
    }
    
    func visitBinaryExprString(expr: BinaryExpr) -> String {
        return ""
    }
    
    func visitLogicalExprString(expr: LogicalExpr) -> String {
        return ""
    }
    
    func visitSetExprString(expr: SetExpr) -> String {
        return ""
    }
    
    func visitClassStmtString(stmt: ClassStmt) -> String {
        return ""
    }
    
    func visitMethodStmtString(stmt: MethodStmt) -> String {
        return ""
    }
    
    func visitFunctionStmtString(stmt: FunctionStmt) -> String {
        return ""
    }
    
    func visitExpressionStmtString(stmt: ExpressionStmt) -> String {
        return ""
    }
    
    func visitIfStmtString(stmt: IfStmt) -> String {
        return ""
    }
    
    func visitOutputStmtString(stmt: OutputStmt) -> String {
        return ""
    }
    
    func visitInputStmtString(stmt: InputStmt) -> String {
        return ""
    }
    
    func visitReturnStmtString(stmt: ReturnStmt) -> String {
        return ""
    }
    
    func visitLoopFromStmtString(stmt: LoopFromStmt) -> String {
        return ""
    }
    
    func visitWhileStmtString(stmt: WhileStmt) -> String {
        return ""
    }
    
    func visitBreakStmtString(stmt: BreakStmt) -> String {
        return ""
    }
    
    func visitContinueStmtString(stmt: ContinueStmt) -> String {
        return ""
    }
    
    func printAst(expr: Expr) -> String {
        expr.accept(visitor: self)
    }
}
