// TODO: Symbol table indexes may be nil in the event of an error!

class TypeChecker: ExprVisitor, StmtVisitor, AstTypeQsTypeVisitor {
    private var problems: [InterpreterProblem] = []
    private var symbolTable: SymbolTables = .init()
    
    private func findCommonType(_ a: QsType, _ b: QsType) -> QsType {
        if a is QsErrorType || b is QsErrorType {
            return QsErrorType()
        }
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
            guard let newChain = symbolTable.getClassChain(id: newClassId) else {
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
                guard var aChain = symbolTable.getClassChain(id: aClassId) else {
                    return QsErrorType()
                }
                guard var bChain = symbolTable.getClassChain(id: bClassId) else {
                    return QsErrorType()
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
            return QsErrorType()
        }
        return QsAnyType()
    }
    
    func visitAstArrayTypeQsType(asttype: AstArrayType) -> QsType {
        return QsArray(contains: typeCheck(asttype.contains))
    }
    
    func visitAstClassTypeQsType(asttype: AstClassType) -> QsType {
        let classSignature = generateClassSignature(className: asttype.name.lexeme, templateAstTypes: asttype.templateArguments)
        guard let symbolTableId = symbolTable.queryAtGlobalOnly(classSignature)?.id else {
            return QsErrorType()
        }
        return QsClass(name: asttype.name.lexeme, id: symbolTableId)
    }
    
    func visitAstTemplateTypeNameQsType(asttype: AstTemplateTypeName) -> QsType {
        // shouldn't happen
        assertionFailure("AstTemplateType shouldn't exist in visited")
        return QsErrorType()
    }
    
    func visitAstIntTypeQsType(asttype: AstIntType) -> QsType {
        return QsInt()
    }
    
    func visitAstDoubleTypeQsType(asttype: AstDoubleType) -> QsType {
        return QsDouble()
    }
    
    func visitAstBooleanTypeQsType(asttype: AstBooleanType) -> QsType {
        return QsDouble()
    }
    
    func visitAstAnyTypeQsType(asttype: AstAnyType) -> QsType {
        return QsAnyType()
    }
    
    private enum TypeAssertion {
        case isAssignable
        case isNumeric
        case isArray
        case isType(QsType)
        case isSubTypeOf(QsType)
        case isSuperTypeOf(QsType)
    }
    private func assertType(expr: Expr, errorMessage: String?, typeAssertions: TypeAssertion...) -> Bool {
        if expr.type is QsErrorType || expr.type == nil {
            return false
        }
        for typeAssertion in typeAssertions {
            switch typeAssertion {
            case .isAssignable:
                if !expr.type!.assignable {
                    if errorMessage != nil {
                        error(message: errorMessage!, start: expr.startLocation, end: expr.endLocation)
                    }
                    return false
                }
            case .isNumeric:
                if !isNumericType(expr.type!) {
                    if errorMessage != nil {
                        error(message: errorMessage!, start: expr.startLocation, end: expr.endLocation)
                    }
                    return false
                }
            case .isArray:
                if !(expr.type is QsArray) {
                    if errorMessage != nil {
                        error(message: errorMessage!, start: expr.startLocation, end: expr.endLocation)
                    }
                    return false
                }
            case .isType(let qsType):
                if qsType is QsErrorType {
                    return false
                }
                if !typesIsEqual(expr.type!, qsType) {
                    if errorMessage != nil {
                        error(message: errorMessage!, start: expr.startLocation, end: expr.endLocation)
                    }
                    return false
                }
            case .isSubTypeOf(let qsType):
                if qsType is QsErrorType {
                    return false
                }
                let commonType = findCommonType(expr.type!, qsType)
                if !typesIsEqual(qsType, commonType) {
                    if errorMessage != nil {
                        error(message: errorMessage!, start: expr.startLocation, end: expr.endLocation)
                    }
                    return false
                }
            case .isSuperTypeOf(let qsType):
                if qsType is QsErrorType {
                    return false
                }
                let commonType = findCommonType(expr.type!, qsType)
                if !typesIsEqual(expr.type!, qsType) {
                    if errorMessage != nil {
                        error(message: errorMessage!, start: expr.startLocation, end: expr.endLocation)
                    }
                    return false
                }
            }
        }
        return true
    }
        
    internal func visitGroupingExpr(expr: GroupingExpr) {
        typeCheck(expr.expression)
        expr.type = expr.expression.type
        expr.type!.assignable = false
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
        
        if inferredType is QsErrorType {
            // propogate the error
            expr.type = QsErrorType(assignable: false)
        } else {
            expr.type = QsArray(contains: inferredType, assignable: false)
        }
    }
    
    internal func visitStaticClassExpr(expr: StaticClassExpr) {
        // handle it at its source (CallExprs and GetExprs)
        // should never be visited
    }
    
    internal func visitThisExpr(expr: ThisExpr) {
        if expr.symbolTableIndex == nil {
            expr.type = QsErrorType(assignable: false)
            return
        }
        let symbol = symbolTable.getSymbol(id: expr.symbolTableIndex!) as! VariableSymbol
        expr.type = symbol.type
        if expr.type == nil {
            expr.type = QsErrorType(assignable: false)
            return
        }
        expr.type!.assignable = false
    }
    
    internal func visitSuperExpr(expr: SuperExpr) {
        // TODO
        expr.type = QsAnyType(assignable: true) // could be assignable or not assignable
    }
    
    internal func visitVariableExpr(expr: VariableExpr) {
        if expr.symbolTableIndex == nil {
            expr.type = QsErrorType(assignable: true)
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
                assertionFailure("Initing variable status unexpected")
                expr.type = QsErrorType(assignable: true)
            case .fieldIniting:
                assertionFailure("FieldIniting variable status unexpected")
                expr.type = QsErrorType(assignable: true)
            case .uninit:
                typeGlobal(id: expr.symbolTableIndex!)
                expr.type = globalEntry.type!
            case .globalIniting:
                // circular
                expr.type = QsErrorType(assignable: true)
            }
        case is VariableSymbol:
            if (symbolEntry as! VariableSymbol).type == nil {
                expr.type = QsErrorType(assignable: true)
            } else {
                expr.type = (symbolEntry as! VariableSymbol).type!
                expr.type!.assignable = true
            }
        case is FunctionNameSymbol:
            expr.type = QsFunction(nameId: (symbolEntry as! FunctionNameSymbol).id)
        default:
            expr.type = QsErrorType(assignable: true)
            assertionFailure("Symbol entry for variable expression must be of type Variable or Function!")
        }
    }
    
    internal func visitSubscriptExpr(expr: SubscriptExpr) {
        // the index and the expression must both be indexable
        typeCheck(expr.index)
        assertType(expr: expr.index, errorMessage: "Array subscript is not an integer", typeAssertions: .isType(QsInt()))
        typeCheck(expr.expression)
        // expression must be of type array
        if assertType(expr: expr.expression, errorMessage: "Subscripted expression is not an array", typeAssertions: .isArray) {
            let expressionArray = expr.expression.type as! QsArray
            expr.type = expressionArray.contains
            expr.type!.assignable = true
            return
        }
        expr.type = QsErrorType(assignable: true) // fallback
        return
    }
    
    internal func visitCallExpr(expr: CallExpr) {
        // TODO: public and private
        
        if expr.object != nil {
            typeCheck(expr.object!)
        }
        for argument in expr.arguments {
            typeCheck(argument)
        }
        
        // Find all the functions that can be called
        var potentialFunctions: [Int] = []
        
        let currentSymbolTablePosition = symbolTable.getCurrentTableId()
        if expr.object == nil {
            // look up an instance method, a class method, or a global function
            // TODO: track the symbol table along with the type checking
            let allMethods = symbolTable.getAllMethods(methodName: expr.property.lexeme)
            if allMethods == [] {
                // search for global functions
                let globalFunctionNameSymbol = symbolTable.queryAtGlobalOnly("$FuncName$\(expr.property.lexeme)")
                if globalFunctionNameSymbol != nil {
                    let globalFunctionNameSymbol = globalFunctionNameSymbol as! FunctionNameSymbol
                    potentialFunctions.append(contentsOf: globalFunctionNameSymbol.belongingFunctions)
                }
            } else {
                potentialFunctions = allMethods
            }
        } else if expr.object is ThisExpr || expr.object is GetExpr || expr.object is VariableExpr {
            // look up an instance method on the object
            if expr.object!.type is QsClass {
                let objectClassType = expr.object!.type! as! QsClass
                let classSymbol = symbolTable.getSymbol(id: objectClassType.id) as! ClassSymbol
                symbolTable.gotoTable(classSymbol.classStmt.scopeIndex!)
                potentialFunctions = symbolTable.getAllMethods(methodName: expr.property.lexeme)
                // filter through and get only the instance methods
                potentialFunctions.removeAll { val in
                    let functionSymbol = symbolTable.getSymbol(id: val) as! MethodSymbol
                    return functionSymbol.methodStmt.isStatic
                }
            }
        } else if expr.object is StaticClassExpr {
            // look up a class method on the object
            let object = expr.object as! StaticClassExpr
            if object.classId != nil {
                let classSymbol = symbolTable.getSymbol(id: object.classId!) as! ClassSymbol
                symbolTable.gotoTable(classSymbol.classStmt.scopeIndex!)
                potentialFunctions = symbolTable.getAllMethods(methodName: expr.property.lexeme)
                // filter through and get only the class methods
                potentialFunctions.removeAll { val in
                    let functionSymbol = symbolTable.getSymbol(id: val) as! MethodSymbol
                    return !functionSymbol.methodStmt.isStatic
                }
            }
        } else {
            expr.type = QsErrorType(assignable: false)
            assertionFailure("Call expression on unknown object")
            return
        }
        symbolTable.gotoTable(currentSymbolTablePosition)
        
        // find the best match based off of a "match level": the lower the level, the greater the function matches
        var bestMatches: [Int] = []
        var bestMatchLevel = Int.max
        var bestMatchBelongsToClassId = -1 // the symbol table ID for the class symbol to which the best classes belong to
        for potentialFunction in potentialFunctions {
            guard let functionSymbolEntry = symbolTable.getSymbol(id: potentialFunction) as? FunctionLikeSymbol else {
                assertionFailure("Symbol at index is not a function symbol")
                continue
                
            }
            // TODO: Default parameters
            // TODO: Infer types for function parameters from their initializers
            if functionSymbolEntry.getParamCount() != expr.arguments.count {
                // that's a no go
                continue
            }
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
            
            var belongsToClass = -1
            if functionSymbolEntry is MethodSymbol {
                let functionSymbolEntry = functionSymbolEntry as! MethodSymbol
                belongsToClass = functionSymbolEntry.withinClass
            }
            if matchLevel < bestMatchLevel {
                bestMatchLevel = matchLevel
                bestMatches = [potentialFunction]
                if functionSymbolEntry is MethodSymbol {
                    let functionSymbolEntry = functionSymbolEntry as! MethodSymbol
                    bestMatchBelongsToClassId = belongsToClass
                }
            } else if matchLevel == bestMatchLevel {
                if belongsToClass == bestMatchBelongsToClassId {
                    bestMatches.append(potentialFunction)
                }
            }
        }
        if bestMatches.count == 0 {
            error(message: "No matching function to call", start: expr.startLocation, end: expr.endLocation)
            expr.type = QsErrorType(assignable: false)
            return
        }
        if bestMatches.count > 1 {
            error(message: "Function call is ambiguous", start: expr.startLocation, end: expr.endLocation)
            expr.type = QsErrorType(assignable: false)
            return
        }
        // TODO: Implicit casts
        let resolvedFunctionSymbol = symbolTable.getSymbol(id: bestMatches[0])
        if let typedResolvedFunctionSymbol = resolvedFunctionSymbol as? FunctionSymbol {
            expr.uniqueFunctionCall = bestMatches[0]
            expr.type = typedResolvedFunctionSymbol.returnType
        } else if let typedResolvedFunctionSymbol = resolvedFunctionSymbol as? MethodSymbol {
            if typedResolvedFunctionSymbol.methodStmt.isStatic {
                // static calls cannot be polymorphic
                expr.uniqueFunctionCall = bestMatches[0]
                expr.type = typedResolvedFunctionSymbol.returnType
            } else {
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
            }
        } else {
            assertionFailure("Expect FunctionLike symbol")
        }
        expr.type!.assignable = false
    }
    
    internal func visitGetExpr(expr: GetExpr) {
        // TODO: Do not allow initializers to be get. they don't exist (from the perspective of the language)
    }
    
    internal func visitUnaryExpr(expr: UnaryExpr) {
        typeCheck(expr.right)
        switch expr.opr.tokenType {
        case .NOT:
            expr.type = QsBoolean(assignable: false)
            assertType(expr: expr.right, errorMessage: "Unary operator '\(expr.opr.lexeme)' can only be applied to an operand of type 'boolean'", typeAssertions: .isType(QsBoolean(assignable: false)))
        case .MINUS:
            if assertType(expr: expr.right, errorMessage: "Unary operator '\(expr.opr.lexeme)' can only be applied to an operand of type 'int' or 'double'", typeAssertions: .isNumeric) {
                expr.type = expr.right.type
                expr.type!.assignable = false
                return
            } else {
                expr.type = QsErrorType(assignable: false)
            }
        default:
            expr.type = QsErrorType(assignable: false)
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
        let commonType = findCommonType(expr.value.type!, castTo)
        if typesIsEqual(commonType, expr.value.type!) {
            // casting to a subclass
            return
        }
        if typesIsEqual(commonType, castTo) {
            // casting to a superclass
            return
        }
        
        if !(expr.value.type is QsErrorType) {
            error(message: "Type '\(printType(expr.value.type))' cannot be cast to '\(castTo))'", start: expr.toType.startLocation, end: expr.toType.endLocation)
        }
    }
    
    internal func visitArrayAllocationExpr(expr: ArrayAllocationExpr) {
        var expressionType = typeCheck(expr.contains)
        for capacity in expr.capacity {
            typeCheck(capacity)
            assertType(expr: capacity, errorMessage: "Expect type 'int' for array capacity", typeAssertions: .isType(QsInt()))
            expressionType = QsArray(contains: expressionType, assignable: false)
        }
        expr.type = expressionType
    }
    
    internal func visitClassAllocationExpr(expr: ClassAllocationExpr) {
        // TODO: resolve the call using code from the call expr for this
        let classSignature = generateClassSignature(className: expr.classType.name.lexeme, templateAstTypes: expr.classType.templateArguments)
        let classSymbol = symbolTable.queryAtGlobalOnly(classSignature) as! ClassSymbol
        expr.type = QsClass(name: expr.classType.name.lexeme, id: classSymbol.id)
    }
    
    internal func visitBinaryExpr(expr: BinaryExpr) {
        // TODO
        typeCheck(expr.left)
        typeCheck(expr.right)
        switch expr.opr.tokenType {
        case .GREATER, .GREATER_EQUAL, .LESS, .LESS_EQUAL:
            expr.type = QsBoolean(assignable: false)
            if isNumericType(expr.left.type!) && isNumericType(expr.right.type!) {
                return
            }
            // TODO: Strings
        case .EQUAL_EQUAL, .BANG_EQUAL:
            expr.type = QsBoolean(assignable: false)
            if isNumericType(expr.left.type!) && isNumericType(expr.right.type!) {
                return
            }
            if typesIsEqual(expr.left.type!, QsBoolean()) && typesIsEqual(expr.right.type!, QsBoolean()) {
                return
            }
            // TODO: Strings
        case .MINUS, .SLASH, .STAR, .DIV:
            expr.type = QsErrorType(assignable: false)
            if isNumericType(expr.left.type!) && isNumericType(expr.right.type!) {
                expr.type = findCommonType(expr.left.type!, expr.right.type!)
                expr.type!.assignable = false
                return
            }
        case .MOD:
            expr.type = QsInt(assignable: false)
            if typesIsEqual(expr.left.type!, QsInt(assignable: false)) && typesIsEqual(expr.right.type!, QsInt(assignable: false)) {
                return
            }
        case .PLUS:
            expr.type = QsErrorType(assignable: false)
            if isNumericType(expr.left.type!) && isNumericType(expr.right.type!) {
                expr.type = findCommonType(expr.left.type!, expr.right.type!)
                expr.type!.assignable = false
                return
            }
            // TODO: Strings
        default:
            expr.type = QsErrorType(assignable: false)
        }
        if !(expr.left.type is QsErrorType) && !(expr.right.type is QsErrorType) {
            error(message: "Binary operator '\(expr.opr.lexeme)' cannot be applied to operands of type '\(printType(expr.left.type))' and '\(printType(expr.right.type))'", start: expr.startLocation, end: expr.endLocation)
        }

    }
    
    internal func visitLogicalExpr(expr: LogicalExpr) {
        typeCheck(expr.left)
        typeCheck(expr.right)
        expr.type = QsBoolean(assignable: false)
        if !(assertType(expr: expr.left, errorMessage: nil, typeAssertions: .isType(QsBoolean())) && assertType(expr: expr.right, errorMessage: nil, typeAssertions: .isType(QsBoolean()))) {
            error(message: "Binary operator '\(expr.opr.lexeme)' can only be applied to operands of type 'boolean' and 'boolean'", start: expr.startLocation, end: expr.endLocation)
        }
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
        typeCheck(expr.value)
        typeCheck(expr.to)
        
        if !assertType(expr: expr.to, errorMessage: "Cannot assign to immutable value", typeAssertions: .isAssignable) {
            expr.type = QsErrorType(assignable: false)
            return
        }
        
        // assignment can be to: fields within classes
        assertType(expr: expr.value, errorMessage: "Type '\(printType(expr.value.type!))' cannot be cast to '\(printType(expr.to.type!))'", typeAssertions: .isSubTypeOf(expr.to.type!))
        expr.type = expr.to.type!
        expr.type!.assignable = false
    }
    
    func visitAssignExpr(expr: AssignExpr) {
        typeCheck(expr.value)
        typeCheck(expr.to)
        
        if assertType(expr: expr.to, errorMessage: "Cannot assign to immutable value", typeAssertions: .isAssignable) {
            // this shouldn't be possible but... just in case constants are added in later on?
            expr.type = QsErrorType(assignable: false)
            return
        }
        
        if expr.isFirstAssignment! {
            if expr.annotation != nil {
                let variableType = typeCheck(expr.annotation!)
                typeVariable(variable: expr.to as! VariableExpr, type: variableType)
                assertType(expr: expr.to, errorMessage: "Type '\(printType(expr.to.type))' cannot be cast to '\(printType(variableType))'", typeAssertions: .isSubTypeOf(variableType))
                expr.type = variableType
                expr.type!.assignable = false
                return
            } else {
                typeVariable(variable: expr.to as! VariableExpr, type: expr.value.type!)
                expr.type = expr.to.type!
                expr.type!.assignable = false
                return
            }
        } else {
            assertType(expr: expr.value, errorMessage: "Type '\(printType(expr.value.type!))' cannot be cast to '\(printType(expr.to.type!))'", typeAssertions: .isSubTypeOf(expr.to.type!))
            expr.type = expr.to.type!
            expr.type!.assignable = false
        }
    }
    
    func visitIsTypeExpr(expr: IsTypeExpr) {
        typeCheck(expr.left)
        expr.rightType = typeCheck(expr.right)
        expr.type = QsBoolean(assignable: false)
    }
    
    func visitImplicitCastExpr(expr: ImplicitCastExpr) {
        assertionFailure("Implicit cast expression should not be visited!")
    }
    
    internal func visitClassStmt(stmt: ClassStmt) {
        symbolTable.gotoTable(stmt.scopeIndex!)
        // type all of the fields
        func typeField(_ field: ClassField) {
            if field.symbolTableIndex == nil {
                return
            }
            let fieldSymbol = symbolTable.getSymbol(id: field.symbolTableIndex!) as! VariableSymbol
            if field.initializer != nil {
                typeCheck(field.initializer!)
            }
            if field.astType != nil {
                let fieldType = typeCheck(field.astType!)
                fieldSymbol.type = fieldType
                if field.initializer != nil {
                    assertType(expr: field.initializer!, errorMessage: "Type '\(printType(field.initializer!.type))' cannot be cast to '\(printType(fieldType))'", typeAssertions: .isSubTypeOf(fieldType))
                }
            } else {
                if field.initializer == nil {
                    fieldSymbol.type = QsErrorType(assignable: false)
                } else {
                    let inferredType = field.initializer!.type
                    fieldSymbol.type = inferredType
                }
            }
        }
        for field in stmt.fields {
            typeField(field)
        }
        for field in stmt.staticFields {
            typeField(field)
        }
        if stmt.thisSymbolTableIndex != nil && stmt.symbolTableIndex != nil {
            let relatedThisSymbol = symbolTable.getSymbol(id: stmt.thisSymbolTableIndex!) as! VariableSymbol
            relatedThisSymbol.type = QsClass(name: stmt.name.lexeme, id: stmt.symbolTableIndex!)
        }
        
        // type all of the methods
        // TODO: Think about initializers?
        for method in stmt.methods {
            processMethodStmt(stmt: method, isInitializer: method.function.name.lexeme == stmt.name.lexeme, accompanyingClassStmt: stmt)
        }
        for method in stmt.staticMethods {
            processMethodStmt(stmt: method, isInitializer: false, accompanyingClassStmt: stmt)
        }
        
        symbolTable.exitScope()
    }
    
    private func processMethodStmt(stmt: MethodStmt, isInitializer: Bool, accompanyingClassStmt: ClassStmt) {
        
    }
    
    internal func visitMethodStmt(stmt: MethodStmt) {
        assertionFailure("visitMethodStmt should never be called!")
        // this should never be visited
    }
    
    internal func visitFunctionStmt(stmt: FunctionStmt) {
        // TODO
    }
    
    internal func visitExpressionStmt(stmt: ExpressionStmt) {
        typeCheck(stmt.expression)
    }
    
    internal func visitIfStmt(stmt: IfStmt) {
        typeCheck(stmt.condition)
        assertType(expr: stmt.condition, errorMessage: "Type '\(printType(stmt.condition.type))' cannot be used as a boolean", typeAssertions: .isType(QsBoolean()))
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
            assertType(expr: expression, errorMessage: "Cannot assign to immutable value", typeAssertions: .isAssignable)
            assertType(expr: expression, errorMessage: "Cannot input to type '\(printType(expression.type!))'", typeAssertions: .isType(QsInt()), .isType(QsAnyType()), .isType(QsDouble())) // TODO: include string
        }
    }
    
    internal func visitReturnStmt(stmt: ReturnStmt) {
        // TODO
    }
    
    internal func visitLoopFromStmt(stmt: LoopFromStmt) {
        typeCheck(stmt.lRange)
        typeCheck(stmt.rRange)
        if stmt.variable.type == nil {
            typeCheck(stmt.variable)
            assertType(expr: stmt.variable, errorMessage: "Type '\(printType(stmt.variable.type!))' cannot be used as an int", typeAssertions: .isType(QsInt()))
        }
        assertType(expr: stmt.lRange, errorMessage: "Type '\(printType(stmt.lRange.type!))' cannot be used as an int", typeAssertions: .isType(QsInt()))
        assertType(expr: stmt.rRange, errorMessage: "Type '\(printType(stmt.rRange.type!))' cannot be used as an int", typeAssertions: .isType(QsInt()))
        typeCheck(stmt.body)
    }
    
    internal func visitWhileStmt(stmt: WhileStmt) {
        typeCheck(stmt.expression)
        assertType(expr: stmt.expression, errorMessage: "Type '\(printType(stmt.expression.type!))' cannot be used as a boolean", typeAssertions: .isType(QsBoolean()))
        typeCheck(stmt.body)
    }
    
    internal func visitBreakStmt(stmt: BreakStmt) {
        // nothing to do
    }
    
    internal func visitContinueStmt(stmt: ContinueStmt) {
        // nothing to do
    }
    
    func visitBlockStmt(stmt: BlockStmt) {
        symbolTable.gotoTable(stmt.scopeIndex!)
        for statement in stmt.statements {
            typeCheck(statement)
        }
        symbolTable.exitScope()
    }
    
    private func typeCheck(_ stmt: Stmt) {
        stmt.accept(visitor: self)
    }
    
    private func typeCheck(_ expr: Expr) {
        if expr.type != nil {
            return
        }
        expr.accept(visitor: self)
    }
    
    private func typeCheck(_ type: AstType) -> QsType {
        return type.accept(visitor: self)
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
        globalVariableSymbol.variableStatus = .globalIniting
        typeCheck(globalVariableSymbol.globalDefiningAssignExpr)
        globalVariableSymbol.variableStatus = .finishedInit
    }
    
    private func typeGlobals(statements: [Stmt]) {
        var globals: [Int] = []
        for symbol in symbolTable.getAllSymbols() {
            guard let symbol = symbol as? GlobalVariableSymbol else {
                continue
            }
            symbol.variableStatus = .uninit
            globals.append(symbol.id)
        }
        for global in globals {
            typeGlobal(id: global)
        }
    }
    
    func typeCheckAst(statements: [Stmt], symbolTables: inout SymbolTables) -> [InterpreterProblem] {
        self.symbolTable = symbolTables
        
        typeFunctions()
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
