class TypeChecker: ExprVisitor, StmtVisitor, AstTypeQsTypeVisitor {
    private var problems: [InterpreterProblem] = []
    private var symbolTable: SymbolTables = .init()
    
    private func getClassChain(id: Int) -> ClassChain? {
        return (symbolTable.getSymbol(id: id) as? ClassSymbolInfo)?.classChain
    }
    
    private func findCommonType(_ a: QsType, _ b: QsType) -> QsType {
        if typesIsEqual(a, b) {
            return a
        }
        if a is QsAnyType || b is QsAnyType {
            return QsAnyType(assignable: false)
        }
        if a is QsNativeType || b is QsNativeType {
            if !(a is QsNativeType && b is QsNativeType) {
                // if one of them is a native type but one of them aren't
                return QsAnyType(assignable: false)
            }
            
            // both of them are of QsNativeType and are different
            // case 1: one of them is boolean. thus the other one must be int or double
            if a is QsBoolean || b is QsBoolean {
                return QsAnyType(assignable: false)
            }
            
            // if none of them are QsBoolean, then one must be QsInt and another must be QsDouble. the common type there is QsDouble, so return that
            return QsDouble(assignable: false)
        }
        if a is QsArray || b is QsArray {
            if !(a is QsArray && b is QsArray) {
                // one of them is a QsArray but another isn't
                return QsAnyType(assignable: false)
            }
            
            // both are QsArrays
            return QsArray(contains: findCommonType((a as! QsArray).contains, (b as! QsArray).contains), assignable: false)
        }
        
        struct JumpError: Error { }
        func jumpUpChain(classChain: ClassChain) throws -> (Int, ClassChain) {
            let newClassId = classChain.upperClass
            guard let newChain = getClassChain(id: newClassId) else {
                throw JumpError()
            }
            return (newClassId, newChain)
        }
        
        do {
            if a is QsClass || b is QsClass {
                if !(a is QsClass && b is QsClass) {
                    // one of them is a QsClass but another isn't
                    return QsAnyType(assignable: false)
                }
                var aClassId = (a as! QsClass).id
                var bClassId = (b as! QsClass).id
                // they're unequal, so jump up the chain
                // let the depth of aClass is deeper than bClass
                guard var aChain = getClassChain(id: aClassId) else {
                    return QsAnyType(assignable: false)
                }
                guard var bChain = getClassChain(id: bClassId) else {
                    return QsAnyType(assignable: false)
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
                        return QsAnyType(assignable: false)
                    }
                    
                    (aClassId, aChain) = try jumpUpChain(classChain: aChain)
                    (bClassId, bChain) = try jumpUpChain(classChain: bChain)
                }
                
                return QsClass(name: aChain.classStmt.name.lexeme, id: aClassId, assignable: false)
            }
        } catch {
            return QsAnyType(assignable: false)
        }
        return QsAnyType(assignable: false)
    }
    
    func visitAstArrayTypeQsType(asttype: AstArrayType) -> QsType {
        return QsArray(contains: typeCheck(asttype.contains), assignable: false)
    }
    
    func visitAstClassTypeQsType(asttype: AstClassType) -> QsType {
        let classSignature = classSignature(className: asttype.name.lexeme, templateAstTypes: asttype.templateArguments)
        guard let symbolTableId = symbolTable.queryGlobal(classSignature)?.id else {
            return QsAnyType(assignable: false)
        }
        return QsClass(name: asttype.name.lexeme, id: symbolTableId, assignable: false)
    }
    
    func visitAstTemplateTypeNameQsType(asttype: AstTemplateTypeName) -> QsType {
        // shouldn't happen
        assertionFailure("AstTemplateType shouldn't exist in visited")
        return QsAnyType(assignable: false)
    }
    
    func visitAstIntTypeQsType(asttype: AstIntType) -> QsType {
        return QsInt(assignable: false)
    }
    
    func visitAstDoubleTypeQsType(asttype: AstDoubleType) -> QsType {
        return QsDouble(assignable: false)
    }
    
    func visitAstBooleanTypeQsType(asttype: AstBooleanType) -> QsType {
        return QsDouble(assignable: false)
    }
    
    func visitAstAnyTypeQsType(asttype: AstAnyType) -> QsType {
        return QsAnyType(assignable: false)
    }
    
    internal func visitGroupingExpr(expr: GroupingExpr) {
        typeCheck(expr.expression)
        expr.type = expr.expression.type
    }
    
    internal func visitLiteralExpr(expr: LiteralExpr) {
        // already done
    }
    
    internal func visitArrayLiteralExpr(expr: ArrayLiteralExpr) {
        if expr.values.count == 0 {
            expr.type = QsAnyType(assignable: false)
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
    
    func visitStaticClassExpr(expr: StaticClassExpr) {
        // TODO
        expr.type = QsAnyType(assignable: true)
    }
    
    internal func visitThisExpr(expr: ThisExpr) {
        // TODO
        expr.type = QsAnyType(assignable: false)
    }
    
    internal func visitSuperExpr(expr: SuperExpr) {
        // TODO
        expr.type = QsAnyType(assignable: true) // could be assignable or not assignable
    }
    
    internal func visitVariableExpr(expr: VariableExpr) {
        if expr.symbolTableIndex == nil {
            expr.type = QsAnyType(assignable: true)
            return
        }
        
        let symbolEntry = symbolTable.getSymbol(id: expr.symbolTableIndex!)
        switch symbolEntry {
        case is VariableSymbolInfo:
            if (symbolEntry as! VariableSymbolInfo).type == nil {
                expr.type = QsAnyType(assignable: true)
            } else {
                expr.type = (symbolEntry as! VariableSymbolInfo).type!
            }
        case is FunctionNameSymbolInfo:
            expr.type = QsFunction(nameId: (symbolEntry as! FunctionNameSymbolInfo).id)
        default:
            assertionFailure("Symbol entry for variable expression must be of type Variable or Function!")
        }
    }
    
    internal func visitSubscriptExpr(expr: SubscriptExpr) {
        // the index and the expression must both be indexable
        typeCheck(expr.index)
        if !(expr.index.type is QsAnyType || expr.index.type is QsInt) {
            expr.type = QsAnyType(assignable: true)
            error(message: "Array subscript is not an integer", start: expr.index.startLocation, end: expr.index.endLocation) // this should highlight the entire expression
            return
        }
        typeCheck(expr.expression)
        if expr.expression.type is QsAnyType {
            expr.type = QsAnyType(assignable: true)
            return
        }
        // expression must be of type array
        if let expressionArray = expr.expression.type as? QsArray {
            expr.type = expressionArray.contains
            expr.type!.assignable = true
            return
        }
        // if the expression is neither an any or an array
        error(message: "Subscripted expression is not an array", start: expr.startLocation, end: expr.endLocation)
        expr.type = QsAnyType(assignable: true) // fallback
        return
    }
    
    internal func visitCallExpr(expr: CallExpr) {
        typeCheck(expr.callee)
        for argument in expr.arguments {
            typeCheck(argument)
        }
        if expr.callee.type! is QsFunction {
            // Resolve function calls
            guard let functionNameSymbolEntry = symbolTable.getSymbol(id: (expr.callee.type! as! QsFunction).nameId) as? FunctionNameSymbolInfo else {
                assertionFailure("Symbol at index is not a function name symbol")
                expr.type = QsAnyType(assignable: false)
                return
            }
            // Resolve based on a "match level": the lower the level, the greater it is
            var bestMatches: [Int] = []
            var bestMatchLevel = Int.max
            let belongingFunctions = functionNameSymbolEntry.belongingFunctions;
            for belongingFunction in belongingFunctions {
                guard let functionSymbolEntry = symbolTable.getSymbol(id: belongingFunction) as? FunctionLikeSymbol else {
                    assertionFailure("Symbol at index is not a function symbol")
                    expr.type = QsAnyType(assignable: false)
                    return
                }
                if functionSymbolEntry.getParamCount() != expr.arguments.count {
                    continue
                }
                // determine match level between the functions
                var matchLevel = 1
                for i in 0..<expr.arguments.count {
                    let givenType = expr.arguments[i].type!
                    let expectedType = functionSymbolEntry.getUnderlyingFunctionStmt().params[i].type!
                    if typesIsEqual(givenType, expectedType) {
                        matchLevel = max(matchLevel, 1)
                        continue
                    }
                    let commonType = findCommonType(givenType, expectedType)
                    if typesIsEqual(commonType, expectedType) {
                        if expectedType is QsAnyType {
                            // the given type is being casted to an any
                            matchLevel = max(matchLevel, 3)
                        } else {
                            matchLevel = max(matchLevel, 2)
                        }
                    } else {
                        matchLevel = Int.max
                        break
                    }
                }
                if matchLevel < bestMatchLevel {
                    bestMatchLevel = matchLevel
                    bestMatches = [belongingFunction]
                } else if matchLevel == bestMatchLevel {
                    bestMatches.append(belongingFunction)
                }
                
            }
            // TODO: Default parameters
            if bestMatchLevel == Int.max || bestMatches.count == 0 {
                error(message: "No matching function to call", start: expr.startLocation, end: expr.endLocation)
                expr.type = QsAnyType(assignable: false) // fallback
                return
            }
            if bestMatches.count>1 {
                error(message: "Function call is ambiguous", start: expr.startLocation, end: expr.endLocation)
                expr.type = QsAnyType(assignable: false)
                return
            }
            
            let resolvedFunctionSymbol = symbolTable.getSymbol(id: bestMatches[0])
            if let typedResolvedFunctionSymbol = resolvedFunctionSymbol as? FunctionSymbolInfo {
                expr.uniqueFunctionCall = bestMatches[0]
                expr.type = typedResolvedFunctionSymbol.returnType
            } else if let typedResolvedFunctionSymbol = resolvedFunctionSymbol as? MethodSymbolInfo {
                var polymorphicCallClassIdToIdDict: [Int : Int] = [:]
                expr.type = typedResolvedFunctionSymbol.returnType
                polymorphicCallClassIdToIdDict[typedResolvedFunctionSymbol.withinClass] = typedResolvedFunctionSymbol.id
                for overrides in typedResolvedFunctionSymbol.overridedBy {
                    guard let methodSymbol = symbolTable.getSymbol(id: overrides) as? MethodSymbolInfo else {
                        continue
                    }
                    polymorphicCallClassIdToIdDict[methodSymbol.withinClass] = overrides
                }
                expr.polymorphicCallClassIdToIdDict = polymorphicCallClassIdToIdDict
            } else {
                assertionFailure("Expect FunctionLike symbol")
            }
            expr.type!.assignable = false
            
            return
        }
        error(message: "Expression cannot be called", start: expr.startLocation, end: expr.endLocation)
        expr.type = QsAnyType(assignable: false) // fallback to the any type
        return
    }
    
    internal func visitGetExpr(expr: GetExpr) {
        // TODO: Do not allow initializers to be get. they don't exist
    }
    
    internal func visitUnaryExpr(expr: UnaryExpr) {
        typeCheck(expr.right)
        if expr.opr.tokenType == .NOT {
            if expr.right.type is QsBoolean {
                expr.type = QsBoolean(assignable: false)
                return
            }
        } else if expr.opr.tokenType == .MINUS {
            
        } else {
            assertionFailure("Unexpected unary expression token type \(expr.opr.tokenType)")
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
    
    internal func visitClassStmt(stmt: ClassStmt) {
        
    }
    
    internal func visitMethodStmt(stmt: MethodStmt) {
        
    }
    
    internal func visitFunctionStmt(stmt: FunctionStmt) {
        
    }
    
    internal func visitExpressionStmt(stmt: ExpressionStmt) {
        typeCheck(stmt.expression)
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
        // nothing to do
    }
    
    internal func visitContinueStmt(stmt: ContinueStmt) {
        // nothing to do
    }
    
    func visitBlockStmt(stmt: BlockStmt) {
        
    }
    
    private func typeCheck(_ stmt: Stmt) {
        stmt.accept(visitor: self)
    }
    
    private func typeCheck(_ expr: Expr) {
        expr.accept(visitor: self)
    }
    
    private func typeCheck(_ type: AstType) -> QsType {
        return type.accept(visitor: self)
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
            guard let classSymbolInfo = symbolTable.getSymbol(id: classStmt.symbolTableIndex!) as? ClassSymbolInfo else {
                assertionFailure("Symbol table symbol is not a class symbol")
                continue
            }
            let currentClassChain = ClassChain(upperClass: -1, depth: -1, classStmt: classStmt, parentOf: [])
            classSymbolInfo.classChain = currentClassChain
            
            classIdCount = max(classIdCount, ((symbolTable.getSymbol(id: classStmt.symbolTableIndex!) as? ClassSymbolInfo)?.classId) ?? 0)
        }
        
        let classClusterer = UnionFind(size: classIdCount+1+1)
        let anyTypeClusterId = classIdCount+1
        
        // fill in the class chains
        for classStmt in classStmts {
            if classStmt.symbolTableIndex == nil {
                continue
            }
            guard let classSymbol = symbolTable.getSymbol(id: classStmt.symbolTableIndex!) as? ClassSymbolInfo else {
                assertionFailure("Expected class symbol info in symbol table")
                continue
            }
            guard let classChain = classSymbol.classChain else {
                assertionFailure("Class chain missing!")
                continue
            }
            if classStmt.superclass == nil {
                classClusterer.unite(anyTypeClusterId, classSymbol.classId)
                classChain.depth = 1
                continue
            }
            guard let inheritedClassSymbol = symbolTable.queryGlobal(classSignature(className: classStmt.superclass!.name.lexeme, templateAstTypes: classStmt.superclass!.templateArguments)) else {
                assertionFailure("Inherited class not found")
                continue
            }
            guard let inheritedClassSymbol = inheritedClassSymbol as? ClassSymbolInfo else {
                assertionFailure("Expected class symbol info in symbol table")
                continue
            }
            guard let inheritedClassChainObject = inheritedClassSymbol.classChain else {
                assertionFailure("Class chain for inherited class missing!")
                continue
            }
            
            // check if the two classes are already related.
            if classClusterer.findParent(inheritedClassSymbol.classId) == classClusterer.findParent(classSymbol.classId) {
                error(message: "'\(classStmt.name.lexeme)' inherits from itself", token: classStmt.name)
                continue
            }
            inheritedClassChainObject.parentOf.append(classStmt.symbolTableIndex!)
            classClusterer.unite(inheritedClassSymbol.classId, classSymbol.classId)
            classChain.upperClass = inheritedClassSymbol.id
        }
        
        func fillDepth(_ symbolTableId: Int, depth: Int) {
            // fills the depth information in
            guard let classChain = getClassChain(id: symbolTableId) else {
                return
            }
            classChain.depth = depth
            for children in classChain.parentOf {
                fillDepth(children, depth: depth+1)
            }
        }
        var methodsChain: [[MethodSignature : Int]] = []
        func findMethodInChain(signature: MethodSignature) -> Int? {
            for i in 0..<methodsChain.count {
                let methodChain = methodsChain[methodsChain.count-i-1]
                if let resultingId = methodChain[signature] {
                    return resultingId
                }
            }
            return nil
        }
        func processOverrideMethods(classId: Int) -> [MethodSignature : [Int]] {
            // within the class specified by classId:
            // record functions into the methods in chain (if they're new)
            // report errors if return types and static is inconsistent
            // log all the functions that override methods from the top of the hierarchy into the return value
            // continue down the class hierarchy
            
            // record functions into the methods
            guard let classSymbol = symbolTable.getSymbol(id: classId) as? ClassSymbolInfo else {
                assertionFailure("Expected class symbol")
                return [:]
            }
            guard let classChain = classSymbol.classChain else {
                assertionFailure("Expected class chain")
                return [:]
            }
            let classStmt = classChain.classStmt
            var newMethodChain: [MethodSignature : Int] = [:]
            var overrides: [MethodSignature : [Int]] = [:]
            var currentClassSignatureToSymbolIdDict: [MethodSignature : Int] = [:]
            
            func addOverride(methodSignature: MethodSignature, functionId: Int) {
                if overrides[methodSignature] == nil {
                    overrides[methodSignature] = [functionId]
                    return
                }
                overrides[methodSignature]!.append(functionId)
            }
            func addOverride(methodSignature: MethodSignature, functionIds: [Int]) {
                if overrides[methodSignature] == nil {
                    overrides[methodSignature] = functionIds
                    return
                }
                overrides[methodSignature]!.append(contentsOf: functionIds)
            }
            
            
            func handleMethod(_ method: MethodStmt) {
                let signature = MethodSignature.init(functionStmt: method.function)
                let existingMethod = findMethodInChain(signature: signature)
                if method.function.symbolTableIndex == nil || method.function.nameSymbolTableIndex == nil {
                    // an error probably occured, dont process it
                    return
                }
                currentClassSignatureToSymbolIdDict[signature] = method.function.symbolTableIndex!
                guard let currentMethodSymbol = symbolTable.getSymbol(id: method.function.symbolTableIndex!) as? MethodSymbolInfo else {
                    assertionFailure("Expected method symbol info!")
                    return
                }
                if existingMethod == nil {
                    // record function into the chain
                    newMethodChain[.init(functionStmt: method.function)] = method.function.symbolTableIndex!
                } else {
                    // check consistency with the function currently in the chain
                    guard let existingMethodSymbolInfo = (symbolTable.getSymbol(id: existingMethod!) as? MethodSymbolInfo) else {
                        return
                    }
                    // check static consistency
                    if method.isStatic != existingMethodSymbolInfo.methodStmt.isStatic {
                        error(message: "Static does not match for overriding method", token: (method.isStatic ? method.staticKeyword! : method.function.name))
                    }
                    // check return type consistency
                    if !typesIsEqual(existingMethodSymbolInfo.returnType, currentMethodSymbol.returnType) {
                        let annotation = method.function.annotation
                        if annotation == nil {
                            error(message: "Return type does not match for overriding method", token: method.function.keyword)
                        } else {
                            error(message: "Return type does not match for overriding method", start: annotation!.startLocation, end: annotation!.endLocation)
                        }
                    }
                    
                    // log this override
                    addOverride(methodSignature: signature, functionId: method.function.symbolTableIndex!)
                }
            }
            for method in classStmt.methods {
                handleMethod(method)
            }
            for method in classStmt.staticMethods {
                handleMethod(method)
            }
            
            methodsChain.append(newMethodChain)
            
            for childClass in classChain.parentOf {
                let childClassOverrides = processOverrideMethods(classId: childClass)
                for (childOverrideSignature, overridingIds) in childClassOverrides {
                    if let methodSymbolId = currentClassSignatureToSymbolIdDict[childOverrideSignature] {
                        // the method that the child is overriding resides in this class. log it.
                        if let methodInfo = (symbolTable.getSymbol(id: methodSymbolId) as? MethodSymbolInfo) {
                            methodInfo.overridedBy = overridingIds
                        }
                    }
                    if newMethodChain[childOverrideSignature] == nil {
                        // the method did not originate from this class. propogate it back through the class hierarchy
                        addOverride(methodSignature: childOverrideSignature, functionIds: overridingIds)
                    }
                }
            }
            
            methodsChain.popLast()
            
            return overrides
        }
        for classStmt in classStmts {
            guard let classId = classStmt.symbolTableIndex else {
                continue
            }
            guard let classChain = getClassChain(id: classId) else {
                continue
            }
            if classChain.depth == 1 {
                fillDepth(classId, depth: 1)
                processOverrideMethods(classId: classId)
            }
        }
    }
    
    private func typeFunctions() {
        // assign types to their parameters and their return types
        for symbolTable in symbolTable.getAllSymbols() {
            guard var functionSymbol = symbolTable as? FunctionLikeSymbol else {
                continue
            }
            let functionStmt = functionSymbol.getUnderlyingFunctionStmt()
            if functionStmt.annotation != nil {
                functionSymbol.returnType = typeCheck(functionStmt.annotation!)
            }
            for i in 0..<functionStmt.params.count {
                let param = functionStmt.params[i]
                var paramType: QsType = QsAnyType(assignable: false)
                if param.astType != nil {
                    paramType = typeCheck(param.astType!)
                }
                functionStmt.params[i].type = paramType
            }
        }
    }
    
    func typeCheckAst(statements: [Stmt], symbolTables: inout SymbolTables) -> [InterpreterProblem] {
        self.symbolTable = symbolTables
        
        typeFunctions()
        buildClassHierarchy(statements: statements)
        
        for statement in statements {
            typeCheck(statement)
        }
        
        symbolTables = self.symbolTable
        return problems
    }
    
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
}
