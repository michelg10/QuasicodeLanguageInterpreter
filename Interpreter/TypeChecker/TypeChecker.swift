class TypeChecker: ExprVisitor, StmtVisitor {
    private enum TypeCheckerError: Error {
        case error(String)
    }
    private func error(message: String, token: Token) -> TypeCheckerError {
        problems.append(.init(message: message, token: token))
        return TypeCheckerError.error(message)
    }
    private func error(message: String, start: InterpreterLocation, end: InterpreterLocation) -> TypeCheckerError {
        problems.append(.init(message: message, start: start, end: end))
        return TypeCheckerError.error(message)
    }
    private class ClassChain {
        init(upperClass: Int, depth: Int, classStmt: ClassStmt, parentOf: [Int]) {
            self.upperClass = upperClass
            self.classStmt = classStmt
            self.parentOf = parentOf
            self.depth = depth
        }
        
        var upperClass: Int
        var depth: Int
        var classStmt: ClassStmt
        var parentOf: [Int]
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
    
    private func findCommonType(_ a: QsType, _ b: QsType) -> QsType {
        if typesIsEqual(a, b) {
            return a
        }
        if a is QsAnyType || b is QsAnyType {
            return QsAnyType()
        }
        if a is QsNativeType || b is QsNativeType {
            if !(a is QsNativeType && b is QsNativeType) {
                // if one of them is a native type but one of them aren't
                return QsAnyType()
            }
            
            // both of them are of QsNativeType and are different
            // case 1: one of them is boolean. thus the other one must be int or double
            if a is QsBoolean || b is QsBoolean {
                return QsAnyType()
            }
            
            // if none of them are QsBoolean, then one must be QsInt and another must be QsDouble. the common type there is QsDouble, so return that
            return QsDouble()
        }
        if a is QsArray || b is QsArray {
            if !(a is QsArray && b is QsArray) {
                // one of them is a QsArray but another isn't
                return QsAnyType()
            }
            
            // both are QsArrays
            return QsArray(contains: findCommonType((a as! QsArray).contains, (b as! QsArray).contains))
        }
        
        struct JumpError: Error { }
        func jumpUpChain(classChain: ClassChain) throws -> (Int, ClassChain) {
            let newClassId = classChain.upperClass
            guard let newChain = idToChain[newClassId] else {
                throw JumpError()
            }
            return (newClassId, newChain)
        }
        
        do {
            if a is QsClass || b is QsClass {
                if !(a is QsClass && b is QsClass) {
                    // one of them is a QsClass but another isn't
                    return QsAnyType()
                }
                var aClassId = (a as! QsClass).id
                var bClassId = (b as! QsClass).id
                // they're unequal, so jump up the chain
                // let the depth of aClass is deeper than bClass
                guard var aChain = idToChain[aClassId] else {
                    return QsAnyType()
                }
                guard var bChain = idToChain[bClassId] else {
                    return QsAnyType()
                }
                if aChain.depth<bChain.depth {
                    swap(&aChain, &bChain)
                    swap(&aClassId, &bClassId)
                }
                let depthDiff = abs(aChain.depth - bChain.depth)
                for _ in 0..<depthDiff {
                    (aClassId, aChain) = try jumpUpChain(classChain: aChain)
                }
                
                assert(aChain.depth == bChain.depth, "Depth of chains should be identical!")
                
                // keep on jumping up for both until they are the same
                while (aClassId != bClassId) {
                    if aChain.upperClass == -1 {
                        return QsAnyType()
                    }
                    
                    (aClassId, aChain) = try jumpUpChain(classChain: aChain)
                    (bClassId, bChain) = try jumpUpChain(classChain: bChain)
                }
                
                return QsClass(name: aChain.classStmt.name.lexeme, id: aClassId)
            }
        } catch {
            return QsAnyType()
        }
        return QsAnyType()
    }
    
    private var problems: [InterpreterProblem] = []
    private var idToChain: [Int : ClassChain] = [:] // their symbol table IDs
    private var astClassTypeToId: [AstClassTypeWrapper : Int] = [:] // use this to map superclasses to their symbol table IDs
    private var symbolTable: [SymbolInfo] = []
    
    internal func visitGroupingExpr(expr: GroupingExpr) {
        typeCheck(expr.expression)
        expr.type = expr.expression.type
    }
    
    internal func visitLiteralExpr(expr: LiteralExpr) {
        // already done
    }
    
    internal func visitArrayLiteralExpr(expr: ArrayLiteralExpr) {
        if expr.values.count == 0 {
            expr.type = QsAnyType()
            return
        }
        typeCheck(expr.values[0])
        var inferredType = expr.values[0].type!
        for i in 1..<expr.values.count {
            typeCheck(expr.values[i])
            inferredType = findCommonType(inferredType, expr.values[i].type!)
        }
        
        expr.type = inferredType
    }
    
    internal func visitThisExpr(expr: ThisExpr) {
        // TODO
        expr.type = QsAnyType()
    }
    
    internal func visitSuperExpr(expr: SuperExpr) {
        // TODO
        expr.type = QsAnyType()
    }
    
    internal func visitVariableExpr(expr: VariableExpr) {
        if expr.symbolTableIndex == nil {
            expr.type = QsAnyType()
            return
        }
        guard let variableSymbolEntry = symbolTable[expr.symbolTableIndex!] as? VariableSymbolInfo else {
            expr.type = QsAnyType()
            return
        }
        if variableSymbolEntry.type == nil {
            expr.type = QsAnyType()
            return // this should only happen upon first assignment
        }
        expr.type = variableSymbolEntry.type!
    }
    
    internal func visitSubscriptExpr(expr: SubscriptExpr) {
        // alert: type check!
        typeCheck(expr.index)
        if !(expr.index.type! is QsAnyType || expr.index.type is QsInt) {
            error(message: "Array subscript is not an integer", start: expr.index.startLocation, end: expr.index.endLocation) // this should highlight the entire expression
        }
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
    
    private func typeCheck(_ expr: Expr) {
        expr.accept(visitor: self)
    }
    
    private func buildClassHierarchy(statements: [Stmt]) {
        var classStmts: [ClassStmt] = []
        for statement in statements {
            if let classStmt = statement as? ClassStmt {
                classStmts.append(classStmt)
            }
        }
        var classIdCount = 0
        for classStmt in classStmts {
            if classStmt.symbolTableIndex == nil {
                assertionFailure("Class statement has no symbol table index!")
                continue
            }
            let currentClassChain = ClassChain(upperClass: -1, depth: 1, classStmt: classStmt, parentOf: [])
            idToChain[classStmt.symbolTableIndex!] = currentClassChain
            
            var classAstType = AstClassType(name: classStmt.name, templateArguments: classStmt.expandedTemplateParameters, startLocation: .init(start: classStmt.name), endLocation: .init(end: classStmt.name))
            astClassTypeToId[.init(val: classAstType)] = classStmt.symbolTableIndex!
            
            classIdCount = max(classIdCount, ((symbolTable[classStmt.symbolTableIndex!] as? ClassSymbolInfo)?.classId) ?? 0)
        }
        
        let classClusterer = UnionFind(size: classIdCount+1)
        let anyTypeClusterId = classIdCount+1
        // fill in the class chains
        for classStmt in classStmts {
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
            guard let inheritedClass = astClassTypeToId[.init(val: .init(name: .dummyToken(tokenType: .IDENTIFIER, lexeme: classStmt.superclass!.name.lexeme), templateArguments: classStmt.superclass!.templateArguments, startLocation: .init(start: classStmt.superclass!.name), endLocation: .init(end: classStmt.superclass!.name)))] else {
                assertionFailure("Inherited class not found")
                continue
            }
            guard let inheritedClassSymbol = symbolTable[inheritedClass] as? ClassSymbolInfo else {
                assertionFailure("Expected class symbol info in symbol table")
                continue
            }
            guard let inheritedClassChainObject = idToChain[inheritedClass] else {
                assertionFailure("Could not find class chain object")
                continue
            }
            
            // check if the two classes are already related.
            if classClusterer.findParent(inheritedClassSymbol.classId) == classClusterer.findParent(classSymbol.classId) {
                error(message: "'\(classStmt.name.lexeme)' inherits from itself", token: classStmt.name)
                continue
            }
            inheritedClassChainObject.parentOf.append(classStmt.symbolTableIndex!)
            classClusterer.unite(inheritedClassSymbol.classId, classSymbol.classId)
            classChain.upperClass = inheritedClass
        }
        
        func fillDepth(_ symbolTableId: Int, depth: Int) {
            // fills the depth information in
            guard let classChain = idToChain[symbolTableId] else {
                return
            }
            classChain.depth = depth
            for children in classChain.parentOf {
                fillDepth(children, depth: depth+1)
            }
        }
        for classStmt in classStmts {
            guard let classId = classStmt.symbolTableIndex else {
                continue
            }
            guard let classChain = idToChain[classId] else {
                continue
            }
            if classChain.depth == 1 {
                for children in classChain.parentOf {
                    fillDepth(children, depth: 2)
                }
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
