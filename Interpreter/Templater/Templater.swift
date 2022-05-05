class Templater: StmtVisitor, ExprVisitor {
    private var isGlobal = true
    private var statements: [Stmt] = []
    private var problems: [InterpreterProblem] = []
    private var classes: [String : ClassStmt] = [:]
    
    func visitClassStmt(stmt: ClassStmt) {
        
    }
    
    func visitMethodStmt(stmt: MethodStmt) {
        
    }
    
    func visitFunctionStmt(stmt: FunctionStmt) {
        
    }
    
    func visitExpressionStmt(stmt: ExpressionStmt) {
        
    }
    
    func visitIfStmt(stmt: IfStmt) {
        
    }
    
    func visitOutputStmt(stmt: OutputStmt) {
        
    }
    
    func visitInputStmt(stmt: InputStmt) {
        
    }
    
    func visitReturnStmt(stmt: ReturnStmt) {
        
    }
    
    func visitLoopFromStmt(stmt: LoopFromStmt) {
        
    }
    
    func visitWhileStmt(stmt: WhileStmt) {
        
    }
    
    func visitBreakStmt(stmt: BreakStmt) {
        
    }
    
    func visitContinueStmt(stmt: ContinueStmt) {
        
    }
    
    func visitGroupingExpr(expr: GroupingExpr) {
        
    }
    
    func visitLiteralExpr(expr: LiteralExpr) {
        
    }
    
    func visitArrayLiteralExpr(expr: ArrayLiteralExpr) {
        
    }
    
    func visitThisExpr(expr: ThisExpr) {
        
    }
    
    func visitSuperExpr(expr: SuperExpr) {
        
    }
    
    func visitVariableExpr(expr: VariableExpr) {
        
    }
    
    func visitSubscriptExpr(expr: SubscriptExpr) {
        
    }
    
    func visitCallExpr(expr: CallExpr) {
        
    }
    
    func visitGetExpr(expr: GetExpr) {
        
    }
    
    func visitUnaryExpr(expr: UnaryExpr) {
        
    }
    
    func visitCastExpr(expr: CastExpr) {
        
    }
    
    func visitArrayAllocationExpr(expr: ArrayAllocationExpr) {
        
    }
    
    func visitClassAllocationExpr(expr: ClassAllocationExpr) {
        
    }
    
    func visitBinaryExpr(expr: BinaryExpr) {
        
    }
    
    func visitLogicalExpr(expr: LogicalExpr) {
        
    }
    
    func visitSetExpr(expr: SetExpr) {
        
    }
    
    private func expandClasses(_ expression: Expr) {
        expression.accept(visitor: self)
    }
    
    private func expandClasses(_ statement: Stmt) {
        statement.accept(visitor: self)
    }
    
    private func expandClasses(_ statements: [Stmt]) {
        for statement in statements {
            statement.accept(visitor: self)
        }
    }
    
    private func gatherClasses() {
        // gathers classes and puts them into the classes array (only for global classes)
        for statement in statements {
            if let classStmt = statement as? ClassStmt {
                if classes[classStmt.name.lexeme] != nil {
                    problems.append(.init(message: "Duplicate class name", token: classStmt.name))
                    continue
                }
                
                classes[classStmt.name.lexeme] = classStmt
                
                if classStmt.templateTypes != nil {
                    // now check if the template types clash
                    var templateTypes = Set<String>()
                    for templateType in classStmt.templateTypes! {
                        if templateTypes.contains(templateType.lexeme) {
                            problems.append(.init(message: "Duplicate template type name", token: templateType))
                        } else {
                            templateTypes.insert(templateType.lexeme)
                        }
                    }
                }
                
            }
        }
    }
    
    func expandClasses(statements: [Stmt]) -> ([Stmt], [InterpreterProblem]) {
        self.statements = statements
        problems = []
        classes = [:]
        isGlobal = true
        gatherClasses()
        
        
        
        return (self.statements, problems)
    }
}
