class TypeChecker: ExprThrowVisitor, StmtVisitor {
    private enum TypeCheckerError: Error {
        case error(String)
    }
    private func error(message: String, token: Token) -> TypeCheckerError {
        problems.append(.init(message: message, token: token))
        return TypeCheckerError.error(message)
    }
    private class ClassChain {
        init(upperClass: Int, classStmt: ClassStmt) {
            self.upperClass = upperClass
            self.classStmt = classStmt
        }
        
        var upperClass: Int
        var classStmt: ClassStmt
    }
    private struct AstClassTypeWrapper: Hashable {
        static func == (lhs: TypeChecker.AstClassTypeWrapper, rhs: TypeChecker.AstClassTypeWrapper) -> Bool {
            return typesIsEqual(lhs.val, rhs.val)
        }
        
        func hash(into hasher: inout Hasher) {
            hashTypeIntoHasher(val, &hasher)
        }
        
        var val: AstClassType
    }
    
    private var problems: [InterpreterProblem] = []
    private var idToChain: [Int : ClassChain] = [:] // their symbol table IDs
    private var astClassTypeToId: [AstClassTypeWrapper : Int] = [:] // use this to map superclasses to their symbol table IDs
    private var symbolTable: [SymbolInfo] = []
    
    internal func visitGroupingExpr(expr: GroupingExpr) throws {
        try typeCheck(expr.expression)
    }
    
    internal func visitLiteralExpr(expr: LiteralExpr) throws {
        // already done
    }
    
    internal func visitArrayLiteralExpr(expr: ArrayLiteralExpr) throws {
        
    }
    
    internal func visitThisExpr(expr: ThisExpr) throws {
        
    }
    
    internal func visitSuperExpr(expr: SuperExpr) throws {
        
    }
    
    internal func visitVariableExpr(expr: VariableExpr) throws {
        
    }
    
    internal func visitSubscriptExpr(expr: SubscriptExpr) throws {
        
    }
    
    internal func visitCallExpr(expr: CallExpr) throws {
        
    }
    
    internal func visitGetExpr(expr: GetExpr) throws {
        
    }
    
    internal func visitUnaryExpr(expr: UnaryExpr) throws {
        
    }
    
    internal func visitCastExpr(expr: CastExpr) throws {
        
    }
    
    internal func visitArrayAllocationExpr(expr: ArrayAllocationExpr) throws {
        
    }
    
    internal func visitClassAllocationExpr(expr: ClassAllocationExpr) throws {
        
    }
    
    internal func visitBinaryExpr(expr: BinaryExpr) throws {
        
    }
    
    internal func visitLogicalExpr(expr: LogicalExpr) throws {
        
    }
    
    internal func visitSetExpr(expr: SetExpr) throws {
        
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
    
    private func typeCheck(_ stmt: Stmt) {
        stmt.accept(visitor: self)
    }
    
    private func typeCheck(_ expr: Expr) throws {
        try expr.accept(visitor: self)
    }
    
    private func buildClassHierarchy(statements: [Stmt]) {
        var classIdCount = 0
        for statement in statements {
            if let classStmt = statement as? ClassStmt {
                if classStmt.symbolTableIndex == nil {
                    assertionFailure("Class statement has no symbol table index!")
                    continue
                }
                let currentClassChain = ClassChain(upperClass: -1, classStmt: classStmt)
                idToChain[classStmt.symbolTableIndex!] = currentClassChain
                
                var classAstType = AstClassType(name: classStmt.name, templateArguments: classStmt.expandedTemplateParameters)
                astClassTypeToId[.init(val: classAstType)] = classStmt.symbolTableIndex!
                
                classIdCount = max(classIdCount, ((symbolTable[classStmt.symbolTableIndex!] as? ClassSymbolInfo)?.classId) ?? 0)
            }
        }
        
        let classClusterer = UnionFind(size: classIdCount+1)
        let anyTypeClusterId = classIdCount+1
        // fill in the class chains
        for statement in statements {
            if let classStmt = statement as? ClassStmt {
                if classStmt.symbolTableIndex == nil {
                    continue
                }
                guard let classSymbol = symbolTable[classStmt.symbolTableIndex!] as? ClassSymbolInfo else {
                    assertionFailure("Expected class symbol info in symbol table")
                    continue
                }
                guard let classChain = idToChain[classStmt.symbolTableIndex!] else {
                    assertionFailure("Class chain missing ID!")
                    continue
                }
                if classStmt.superclass == nil {
                    classClusterer.unite(anyTypeClusterId, classSymbol.classId)
                    continue
                }
                guard let inheritedClass = astClassTypeToId[.init(val: .init(name: .dummyToken(tokenType: .IDENTIFIER, lexeme: classStmt.superclass!.name.lexeme), templateArguments: classStmt.superclass!.templateArguments))] else {
                    assertionFailure("Inherited class not found")
                    continue
                }
                guard let inheritedClassSymbol = symbolTable[inheritedClass] as? ClassSymbolInfo else {
                    assertionFailure("Expected class symbol info in symbol table")
                    continue
                }
                
                // check if the two classes are already related.
                if classClusterer.findParent(inheritedClassSymbol.classId) == classClusterer.findParent(classSymbol.classId) {
                    error(message: "'\(classStmt.name)' inherits from itself", token: classStmt.name)
                    continue
                }
                classClusterer.unite(inheritedClassSymbol.classId, classSymbol.classId)
                classChain.upperClass = inheritedClass
            }
        }
    }
    
    func typeCheckAst(statements: [Stmt], symbolTable: inout [SymbolInfo]) -> [InterpreterProblem] {
        idToChain = [:]
        self.symbolTable = symbolTable
        
        buildClassHierarchy(statements: statements)
        
        symbolTable = self.symbolTable
        return problems
    }
}
