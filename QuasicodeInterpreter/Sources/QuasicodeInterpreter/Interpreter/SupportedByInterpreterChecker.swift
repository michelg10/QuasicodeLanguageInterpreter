/// The interpreter doesn't support many expressions and statements, such as classes. This class checks for that
public class SupportedByInterpreterChecker: ExprBoolVisitor, StmtBoolVisitor {
    public init() {
        
    }
    
    private var problems: [InterpreterProblem] = []
    private var stringClassId = -1
    private var symbolTable: SymbolTable = .init()
    
    private func getStringType() -> QsType {
        return QsClass(name: "String", id: stringClassId)
    }
    
    private func error(message: String, start: InterpreterLocation, end: InterpreterLocation) {
        problems.append(.init(message: message, start: start, end: end))
    }
    
    private func error(message: String, on expr: Expr) {
        error(message: message, start: expr.startLocation, end: expr.endLocation)
    }
    
    public func visitGroupingExprBool(expr: GroupingExpr) -> Bool {
        checkSupport(expr.expression)
    }
    
    public func visitLiteralExprBool(expr: LiteralExpr) -> Bool {
        return true
    }
    
    public func visitArrayLiteralExprBool(expr: ArrayLiteralExpr) -> Bool {
        var supported = true
        for value in expr.values {
            supported = supported && checkSupport(value)
        }
        return supported
    }
    
    public func visitStaticClassExprBool(expr: StaticClassExpr) -> Bool {
        return false
    }
    
    public func visitThisExprBool(expr: ThisExpr) -> Bool {
        return false
    }
    
    public func visitSuperExprBool(expr: SuperExpr) -> Bool {
        return false
    }
    
    public func visitVariableExprBool(expr: VariableExpr) -> Bool {
        return true
    }
    
    public func visitSubscriptExprBool(expr: SubscriptExpr) -> Bool {
        var supported = true
        supported = supported && checkSupport(expr.expression)
        supported = supported && checkSupport(expr.index)
        return supported
    }
    
    public func visitCallExprBool(expr: CallExpr) -> Bool {
        var supported = true
        if let object = expr.object {
            supported = supported && checkSupport(object)
        }
        if expr.polymorphicCallClassIdToIdDict != nil {
            error(message: "Polymorphic calls are not suppoorted", on: expr)
            supported = false
        }
        if expr.uniqueFunctionCall != nil {
            let uniqueCall = expr.uniqueFunctionCall!
            let callSymbol = symbolTable.getSymbol(id: uniqueCall)
            if callSymbol is MethodSymbol {
                error(message: "Calling methods are not supported", on: expr)
                supported = false
            }
        }
        return supported
    }
    
    public func visitGetExprBool(expr: GetExpr) -> Bool {
        var supported = true
        supported = checkSupport(expr.object)
        
        if !(expr.object.type is QsArray) {
            error(message: "Class-related property getters are not supported", on: expr)
            supported = false
        }
        
        return supported
    }
    
    public func visitUnaryExprBool(expr: UnaryExpr) -> Bool {
        return true
    }
    
    public func visitCastExprBool(expr: CastExpr) -> Bool {
        var supported = true
        
        supported = supported && checkSupport(expr.value)
        
        if expr.type is QsClass && !qsTypesEqual(expr.type!, getStringType(), anyEqAny: true) {
            error(message: "Classes are not supported", start: expr.toType.startLocation, end: expr.toType.endLocation)
            supported = false
        }
        
        return supported
    }
    
    public func visitArrayAllocationExprBool(expr: ArrayAllocationExpr) -> Bool {
        var supported = true
        for lengthExpr in expr.capacity {
            supported = supported && checkSupport(lengthExpr)
        }
        
        return supported
    }
    
    public func visitClassAllocationExprBool(expr: ClassAllocationExpr) -> Bool {
        return false
    }
    
    public func visitBinaryExprBool(expr: BinaryExpr) -> Bool {
        return true
    }
    
    public func visitLogicalExprBool(expr: LogicalExpr) -> Bool {
        return true
    }
    
    public func visitVariableToSetExprBool(expr: VariableToSetExpr) -> Bool {
        return true
    }
    
    public func visitIsTypeExprBool(expr: IsTypeExpr) -> Bool {
        return true
    }
    
    public func visitImplicitCastExprBool(expr: ImplicitCastExpr) -> Bool {
        return true
    }
    
    public func visitClassStmtBool(stmt: ClassStmt) -> Bool {
        error(message: "Classes are not supported", start: stmt.keyword.startLocation, end: stmt.keyword.endLocation)
        return false
    }
    
    public func visitMethodStmtBool(stmt: MethodStmt) -> Bool {
        error(message: "Methods are not supported", start: stmt.startLocation, end: stmt.endLocation)
        return false
    }
    
    public func visitFunctionStmtBool(stmt: FunctionStmt) -> Bool {
        return checkSupport(stmt.body)
    }
    
    public func visitExpressionStmtBool(stmt: ExpressionStmt) -> Bool {
        return checkSupport(stmt.expression)
    }
    
    public func visitIfStmtBool(stmt: IfStmt) -> Bool {
        var supported = true
        supported = supported && checkSupport(stmt.condition)
        supported = supported && checkSupport(stmt.thenBranch)
        supported = supported && checkSupport(stmt.elseIfBranches)
        if let elseBranch = stmt.elseBranch {
            supported = supported && checkSupport(elseBranch)
        }
        return supported
    }
    
    public func visitOutputStmtBool(stmt: OutputStmt) -> Bool {
        var supported = true
        for expression in stmt.expressions {
            supported = supported && checkSupport(expression)
        }
        return supported
    }
    
    public func visitInputStmtBool(stmt: InputStmt) -> Bool {
        var supported = true
        for expression in stmt.expressions {
            supported = supported && checkSupport(expression)
        }
        return supported
    }
    
    public func visitReturnStmtBool(stmt: ReturnStmt) -> Bool {
        if let value = stmt.value {
            return checkSupport(value)
        }
        return true
    }
    
    public func visitLoopFromStmtBool(stmt: LoopFromStmt) -> Bool {
        var supported = true
        supported = supported && checkSupport(stmt.lRange)
        supported = supported && checkSupport(stmt.rRange)
        supported = supported && checkSupport(stmt.body)
        return supported
    }
    
    public func visitWhileStmtBool(stmt: WhileStmt) -> Bool {
        var supported = true
        supported = supported && checkSupport(stmt.expression)
        supported = supported && checkSupport(stmt.body)
        return supported
    }
    
    public func visitBreakStmtBool(stmt: BreakStmt) -> Bool {
        return true
    }
    
    public func visitContinueStmtBool(stmt: ContinueStmt) -> Bool {
        return true
    }
    
    public func visitBlockStmtBool(stmt: BlockStmt) -> Bool {
        return checkSupport(stmt.statements)
    }
    
    public func visitExitStmtBool(stmt: ExitStmt) -> Bool {
        return true
    }
    
    public func visitMultiSetStmtBool(stmt: MultiSetStmt) -> Bool {
        return checkSupport(stmt.setStmts)
    }
    
    public func visitSetStmtBool(stmt: SetStmt) -> Bool {
        var supported = true
        supported = supported && checkSupport(stmt.left)
        for chain in stmt.chained {
            supported = supported && checkSupport(chain)
        }
        supported = supported && checkSupport(stmt.value)
        return supported
    }
    
    private func checkSupport(_ expr: Expr) -> Bool {
        return expr.accept(visitor: self)
    }
    
    private func checkSupport(_ stmt: Stmt) -> Bool {
        return stmt.accept(visitor: self)
    }
    
    private func checkSupport(_ stmts: [Stmt]) -> Bool {
        var supported = true
        for stmt in stmts {
            supported = supported && stmt.accept(visitor: self)
        }
        return supported
    }
    
    public func checkSupport(_ stmts: [Stmt], symbolTable: SymbolTable) -> (Bool, [InterpreterProblem]) {
        problems = []
        stringClassId = symbolTable.queryAtGlobalOnly("String<>")?.id ?? -1
        self.symbolTable = symbolTable
        return (checkSupport(stmts), problems)
    }
}
