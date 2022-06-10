class TypeChecker: ExprVisitor, StmtVisitor, AstTypeQsTypeVisitor {
    private var problems: [InterpreterProblem] = []
    private var symbolTable: SymbolTables = .init()
    
    private func getClassChain(id: Int) -> ClassChain? {
        return (symbolTable.getSymbol(id: id) as? ClassSymbol)?.classChain
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
        let classSignature = generateClassSignature(className: asttype.name.lexeme, templateAstTypes: asttype.templateArguments)
        guard let symbolTableId = symbolTable.queryAtGlobalOnly(classSignature)?.id else {
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
        // add in the implicit type conversions
        for i in 0..<expr.values.count {
            if !typesIsEqual(inferredType, expr.values[i].type!) {
                expr.values[i] = ImplicitCastExpr(expression: expr.values[i], type: inferredType, startLocation: expr.startLocation, endLocation: expr.endLocation)
            }
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
        case is GlobalVariableSymbol:
            let globalEntry = symbolEntry as! GlobalVariableSymbol
            switch globalEntry.variableStatus {
            case .finishedInit:
                expr.type = globalEntry.type!
                expr.type!.assignable = true
            case .initing:
                // throw an error: circular
                error(message: "Circular reference", start: expr.startLocation, end: expr.endLocation)
                expr.type = QsAnyType(assignable: true)
            case .uninit:
                typeGlobal(id: expr.symbolTableIndex!)
                expr.type = globalEntry.type!
            case .globalIniting:
                break
            }
        case is VariableSymbol:
            if (symbolEntry as! VariableSymbol).type == nil {
                expr.type = QsAnyType(assignable: true)
            } else {
                expr.type = (symbolEntry as! VariableSymbol).type!
                expr.type!.assignable = true
            }
        case is FunctionNameSymbol:
            expr.type = QsFunction(nameId: (symbolEntry as! FunctionNameSymbol).id)
        default:
            assertionFailure("Symbol entry for variable expression must be of type Variable or Function!")
        }
    }
    
    internal func visitSubscriptExpr(expr: SubscriptExpr) {
        // the index and the expression must both be indexable
        typeCheck(expr.index)
        if expr.index.type is QsInt {
            // do nothing
        } else {
            error(message: "Array subscript is not an integer", start: expr.index.startLocation, end: expr.index.endLocation) // this should highlight the entire expression
        }
        typeCheck(expr.expression)
        // expression must be of type array
        if let expressionArray = expr.expression.type as? QsArray {
            expr.type = expressionArray.contains
            expr.type!.assignable = true
            return
        }
        error(message: "Subscripted expression is not an array", start: expr.startLocation, end: expr.endLocation)
        expr.type = QsAnyType(assignable: true) // fallback
        return
    }
    
    internal func visitCallExpr(expr: CallExpr) {
        // TODO
        typeCheck(expr.callee)
        for argument in expr.arguments {
            typeCheck(argument)
        }
        if expr.callee.type! is QsFunction {
            // Resolve function calls
            guard let functionNameSymbolEntry = symbolTable.getSymbol(id: (expr.callee.type! as! QsFunction).nameId) as? FunctionNameSymbol else {
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
            // TODO: Implicit casts
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
            if let typedResolvedFunctionSymbol = resolvedFunctionSymbol as? FunctionSymbol {
                expr.uniqueFunctionCall = bestMatches[0]
                expr.type = typedResolvedFunctionSymbol.returnType
            } else if let typedResolvedFunctionSymbol = resolvedFunctionSymbol as? MethodSymbol {
                var polymorphicCallClassIdToIdDict: [Int : Int] = [:]
                expr.type = typedResolvedFunctionSymbol.returnType
                polymorphicCallClassIdToIdDict[typedResolvedFunctionSymbol.withinClass] = typedResolvedFunctionSymbol.id
                for overrides in typedResolvedFunctionSymbol.overridedBy {
                    guard let methodSymbol = symbolTable.getSymbol(id: overrides) as? MethodSymbol else {
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
        // TODO: Do not allow initializers to be get. they don't exist (from the perspective of the language)
    }
    
    internal func visitUnaryExpr(expr: UnaryExpr) {
        typeCheck(expr.right)
        switch expr.opr.tokenType {
        case .NOT:
            expr.type = QsBoolean(assignable: false)
            if expr.right.type is QsBoolean {
                // do nothing
            } else {
                error(message: "Type '\(printType(expr.right.type!))' cannot be used as a boolean", start: expr.right.startLocation, end: expr.right.endLocation)
                expr.type = QsBoolean(assignable: false)
            }
        case .MINUS:
            if isNumericType(expr.right.type!) {
                expr.type = expr.right.type
                expr.type!.assignable = false
                return
            } else {
                error(message: "Type '\(printType(expr.right.type!))' cannot be used as 'int' or 'double'", start: expr.right.startLocation, end: expr.right.endLocation)
                expr.type = QsDouble(assignable: false)
            }
        default:
            expr.type = QsAnyType(assignable: false)
            assertionFailure("Unexpected unary expression token type \(expr.opr.tokenType)")
        }
    }
    
    internal func visitCastExpr(expr: CastExpr) {
        typeCheck(expr.value)
        let castTo = typeCheck(expr.toType)
        expr.type = castTo
        if typesIsEqual(castTo, expr.value.type!) {
            return
        }
        // allowed type casts: [any type] -> any, any -> [any type], int -> double, double -> int
        if castTo is QsAnyType {
            return // allow casting to any type
        }
        if expr.value.type is QsAnyType {
            return // allow any to be cast to anything
        }
        if isNumericType(expr.value.type!) && isNumericType(castTo) {
            return // allow int -> double and double -> int
        }
        error(message: "Type '\(printType(expr.value.type))' cannot be cast to '\(castTo))'", start: expr.toType.startLocation, end: expr.toType.endLocation)
    }
    
    internal func visitArrayAllocationExpr(expr: ArrayAllocationExpr) {
        var expressionType = typeCheck(expr.contains)
        for capacity in expr.capacity {
            typeCheck(capacity)
            if !(capacity.type! is QsInt) {
                error(message: "Expect type 'int' for array capacity", start: expr.startLocation, end: expr.endLocation)
                expr.type = QsAnyType(assignable: false)
                return
            }
            expressionType = QsArray(contains: expressionType, assignable: false)
        }
        expr.type = expressionType
    }
    
    internal func visitClassAllocationExpr(expr: ClassAllocationExpr) {
        // TODO: use code from the call expr for this
        expr.type = QsAnyType(assignable: false)
    }
    
    internal func visitBinaryExpr(expr: BinaryExpr) {
        // TODO
        typeCheck(expr.left)
        typeCheck(expr.right)
        switch expr.opr.tokenType {
        case .GREATER, .GREATER_EQUAL, .LESS, .LESS_EQUAL:
            if isNumericType(expr.left.type!) && isNumericType(expr.right.type!) {
                expr.type = QsBoolean(assignable: false)
                return
            } else {
                // string comparison
            }
        default:
            
            break
        }
    }
    
    internal func visitLogicalExpr(expr: LogicalExpr) {
        // TODO
    }
    
    private func typeVariable(variable: VariableExpr, type: QsType) {
        // adds the type of a variable into the symbol table and also updates the type in the variableExpr
        guard let symbol = symbolTable.getSymbol(id: variable.symbolTableIndex!) as? VariableSymbol else {
            return
        }
        symbol.type = type
        variable.type = type
    }
    
    private func extractGlobalIdFromExpr(expr: Expr) -> Int? {
        guard let variableExpr = expr as? VariableExpr else {
            return nil
        }
        if symbolTable.getSymbol(id: variableExpr.symbolTableIndex!) is GlobalVariableSymbol {
            return variableExpr.symbolTableIndex!
        }
        return nil
    }
    
    internal func visitSetExpr(expr: SetExpr) {
        // TODO: be careful about the symbol table
        /*
        typeCheck(expr.value)
        if let globalId = extractGlobalIdFromExpr(expr: expr.to) {
            // mark the global as
            
        }
        typeCheck(expr.to)
        
        if !expr.to.type!.assignable {
            error(message: "Cannot assign to immutable value", start: expr.to.startLocation, end: expr.to.endLocation)
            expr.type = QsAnyType(assignable: false)
            return
        }
        if expr.isFirstAssignment == true {
            // this SHOULD mean that its also a variable expression
            if expr.annotation != nil {
                let variableType = typeCheck(expr.annotation!)
                typeVariable(variable: expr.to as! VariableExpr, type: variableType)
                let commonType = findCommonType(variableType, expr.to.type!)
                if !typesIsEqual(commonType, variableType) {
                    error(message: "Type '\(printType(expr.to.type))' cannot be cast to '\(printType(variableType))'", start: expr.to.startLocation, end: expr.to.endLocation)
                }
                expr.type = variableType
                expr.type!.assignable = false
                return
            } else {
                typeVariable(variable: expr.to as! VariableExpr, type: expr.value.type!)
                expr.type = expr.to.type!
                expr.type!.assignable = false
                return
            }
        }
        
        // assignment can be to: fields within classes or variables.
        let commonType = findCommonType(expr.to.type!, expr.value.type!)
        if !typesIsEqual(commonType, expr.to.type!) {
            error(message: "Type '\(printType(expr.value.type!))' cannot be cast to '\(printType(expr.to.type!))'", start: expr.to.startLocation, end: expr.to.endLocation)
        }
        expr.type = expr.to.type!
        expr.type!.assignable = false
        return
         */
    }
    
    func visitAssignExpr(expr: AssignExpr) {
        
    }
    
    func visitIsTypeExpr(expr: IsTypeExpr) {
        // TODO
    }
    
    func visitImplicitCastExpr(expr: ImplicitCastExpr) {
        assertionFailure("Implicit cast expression should not be visited!")
    }
    
    internal func visitClassStmt(stmt: ClassStmt) {
        // TODO
    }
    
    internal func visitMethodStmt(stmt: MethodStmt) {
        // TODO
    }
    
    internal func visitFunctionStmt(stmt: FunctionStmt) {
        // TODO
    }
    
    internal func visitExpressionStmt(stmt: ExpressionStmt) {
        typeCheck(stmt.expression)
    }
    
    internal func visitIfStmt(stmt: IfStmt) {
        typeCheck(stmt.condition)
        if !(stmt.condition.type is QsBoolean) {
            error(message: "Type '\(printType(stmt.condition.type))' cannot be used as a boolean", start: stmt.condition.startLocation, end: stmt.condition.endLocation)
        }
        typeCheck(stmt.thenBranch)
        for elseIfBranch in stmt.elseIfBranches {
            typeCheck(elseIfBranch)
        }
        if stmt.elseBranch != nil {
            typeCheck(stmt.elseBranch!)
        }
    }
    
    internal func visitOutputStmt(stmt: OutputStmt) {
        for expression in stmt.expressions {
            typeCheck(expression)
        }
    }
    
    internal func visitInputStmt(stmt: InputStmt) {
        // TODO
        
        for expression in stmt.expressions {
            typeCheck(expression)
            if !expression.type!.assignable {
                error(message: "Cannot assign to immutable value", start: expression.startLocation, end: expression.endLocation)
            }
            if !(expression.type is QsInt || expression.type is QsAnyType || expression.type is QsDouble) { // TODO: include string
                error(message: "Cannot input to type '\(printType(expression.type!))'", start: expression.startLocation, end: expression.endLocation)
            }
        }
    }
    
    internal func visitReturnStmt(stmt: ReturnStmt) {
        // TODO
    }
    
    internal func visitLoopFromStmt(stmt: LoopFromStmt) {
        typeCheck(stmt.lRange)
        typeCheck(stmt.rRange)
        typeCheck(stmt.variable)
        if !(stmt.lRange.type is QsInt) {
            error(message: "Type '\(printType(stmt.lRange.type!))' cannot be used as an int", start: stmt.lRange.startLocation, end: stmt.lRange.endLocation)
        }
        if !(stmt.rRange.type is QsInt) {
            error(message: "Type '\(printType(stmt.rRange.type!))' cannot be used as an int", start: stmt.rRange.startLocation, end: stmt.rRange.endLocation)
        }
        typeCheck(stmt.body)
    }
    
    internal func visitWhileStmt(stmt: WhileStmt) {
        typeCheck(stmt.expression)
        if !(stmt.expression.type is QsBoolean) {
            error(message: "Type '\(printType(stmt.expression.type!))' cannot be used as a boolean", start: stmt.expression.startLocation, end: stmt.expression.endLocation)
        }
        typeCheck(stmt.body)
    }
    
    internal func visitBreakStmt(stmt: BreakStmt) {
        // nothing to do
    }
    
    internal func visitContinueStmt(stmt: ContinueStmt) {
        // nothing to do
    }
    
    func visitBlockStmt(stmt: BlockStmt) {
        for statement in stmt.statements {
            typeCheck(statement)
        }
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
            guard let classSymbolInfo = symbolTable.getSymbol(id: classStmt.symbolTableIndex!) as? ClassSymbol else {
                assertionFailure("Symbol table symbol is not a class symbol")
                continue
            }
            let currentClassChain = ClassChain(upperClass: -1, depth: -1, classStmt: classStmt, parentOf: [])
            classSymbolInfo.classChain = currentClassChain
            
            classIdCount = max(classIdCount, ((symbolTable.getSymbol(id: classStmt.symbolTableIndex!) as? ClassSymbol)?.classId) ?? 0)
        }
        
        let classClusterer = UnionFind(size: classIdCount+1+1)
        let anyTypeClusterId = classIdCount+1
        
        // fill in the class chains
        for classStmt in classStmts {
            if classStmt.symbolTableIndex == nil {
                continue
            }
            guard let classSymbol = symbolTable.getSymbol(id: classStmt.symbolTableIndex!) as? ClassSymbol else {
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
            guard let inheritedClassSymbol = symbolTable.queryAtGlobalOnly(generateClassSignature(className: classStmt.superclass!.name.lexeme, templateAstTypes: classStmt.superclass!.templateArguments)) else {
                assertionFailure("Inherited class not found")
                continue
            }
            guard let inheritedClassSymbol = inheritedClassSymbol as? ClassSymbol else {
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
            guard let classSymbol = symbolTable.getSymbol(id: classId) as? ClassSymbol else {
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
                guard let currentMethodSymbol = symbolTable.getSymbol(id: method.function.symbolTableIndex!) as? MethodSymbol else {
                    assertionFailure("Expected method symbol info!")
                    return
                }
                if existingMethod == nil {
                    // record function into the chain
                    newMethodChain[.init(functionStmt: method.function)] = method.function.symbolTableIndex!
                } else {
                    // check consistency with the function currently in the chain
                    guard let existingMethodSymbolInfo = (symbolTable.getSymbol(id: existingMethod!) as? MethodSymbol) else {
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
                        if let methodInfo = (symbolTable.getSymbol(id: methodSymbolId) as? MethodSymbol) {
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
    
    private func typeGlobal(id: Int) {
        let globalVariableSymbol = symbolTable.getSymbol(id: id) as! GlobalVariableSymbol
        globalVariableSymbol.variableStatus = .initing
        typeCheck(globalVariableSymbol.globalDefiningAssignExpr)
    }
    
    private func typeGlobals(statements: [Stmt]) {
        for statement in statements {
            guard let expressionStmt = statement as? ExpressionStmt else {
                continue
            }
            guard let setExpr = expressionStmt.expression as? SetExpr else {
                continue
            }
            guard let variableExpr = setExpr.to as? VariableExpr else {
                continue
            }
            if symbolTable.getSymbol(id: variableExpr.symbolTableIndex!) is GlobalVariableSymbol {
                typeGlobal(id: variableExpr.symbolTableIndex!)
            }
        }
    }
    
    func typeCheckAst(statements: [Stmt], symbolTables: inout SymbolTables) -> [InterpreterProblem] {
        self.symbolTable = symbolTables
        
        typeFunctions()
        buildClassHierarchy(statements: statements)
        typeGlobals(statements: statements)
        
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
