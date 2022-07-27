class TypeChecker: ExprVisitor, StmtVisitor, AstTypeQsTypeVisitor {
    private var problems: [InterpreterProblem] = []
    private var symbolTable: SymbolTables = .init()
    // type checker needs to know:
    // current function / method the checker is currently in for return checks
    // current class the checker is currently in for public / private checks and super checks
    var currentFunctionIndex: Int?
    var currentClassIndex: Int?
    
    private func isInMethod() -> Bool {
        return currentFunctionIndex != nil && currentClassIndex != nil
    }
    
    private func findCommonType(_ a: QsType, _ b: QsType) -> QsType {
        if a is QsErrorType || b is QsErrorType {
            return QsErrorType()
        }
        if a is QsVoidType || b is QsVoidType {
            return QsVoidType()
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
        func jumpUpHierarchy(classSymbol: ClassSymbol) throws -> ClassSymbol {
            guard let newClassId = classSymbol.upperClass else {
                throw JumpError()
            }
            let newClassSymbol = symbolTable.getSymbol(id: newClassId) as! ClassSymbol
            return newClassSymbol
        }
        
        do {
            if a is QsClass || b is QsClass {
                if !(a is QsClass && b is QsClass) {
                    // one of them is a QsClass but another isn't
                    return QsAnyType()
                }
                // they're unequal, so jump up the chain
                // let the depth of aClass is deeper than bClass
                var aClassSymbol = symbolTable.getSymbol(id: (a as! QsClass).id) as! ClassSymbol
                var bClassSymbol = symbolTable.getSymbol(id: (b as! QsClass).id) as! ClassSymbol
                if aClassSymbol.depth == nil || bClassSymbol.depth == nil {
                    return QsErrorType()
                }
                if aClassSymbol.depth!<bClassSymbol.depth! {
                    swap(&aClassSymbol, &bClassSymbol)
                }
                let depthDiff = abs(aClassSymbol.depth! - bClassSymbol.depth!)
                for _ in 0..<depthDiff {
                    aClassSymbol = try jumpUpHierarchy(classSymbol: aClassSymbol)
                }
                
                assert(aClassSymbol.depth == bClassSymbol.depth, "Depth of chains should be identical!")
                
                // keep on jumping up for both until they are the same
                while (aClassSymbol.id != bClassSymbol.id) {
                    if aClassSymbol.upperClass == nil {
                        return QsAnyType()
                    }
                    
                    aClassSymbol = try jumpUpHierarchy(classSymbol: aClassSymbol)
                    bClassSymbol = try jumpUpHierarchy(classSymbol: bClassSymbol)
                }
                
                return QsClass(name: aClassSymbol.displayName, id: aClassSymbol.id)
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
        guard let symbol = symbolTable.queryAtGlobalOnly(classSignature) as? ClassSymbol else {
            return QsErrorType()
        }
        return QsClass(name: symbol.displayName, id: symbol.id)
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
        return QsBoolean()
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
                        error(message: errorMessage!, on: expr)
                    }
                    return false
                }
            case .isNumeric:
                if !isNumericType(expr.type!) {
                    if errorMessage != nil {
                        error(message: errorMessage!, on: expr)
                    }
                    return false
                }
            case .isArray:
                if !(expr.type is QsArray) {
                    if errorMessage != nil {
                        error(message: errorMessage!, on: expr)
                    }
                    return false
                }
            case .isType(let qsType):
                if qsType is QsErrorType {
                    return false
                }
                if !typesIsEqual(expr.type!, qsType) {
                    if errorMessage != nil {
                        error(message: errorMessage!, on: expr)
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
                        error(message: errorMessage!, on: expr)
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
                        error(message: errorMessage!, on: expr)
                    }
                    return false
                }
            }
        }
        return true
    }
    
    internal func visitGroupingExpr(expr: GroupingExpr) {
        defer {
            expr.fallbackToErrorType(assignable: false)
            expr.type!.assignable = false
        }
        
        typeCheck(expr.expression)
        expr.type = expr.expression.type
    }
    
    internal func visitLiteralExpr(expr: LiteralExpr) {
        // already done
    }
    
    internal func visitArrayLiteralExpr(expr: ArrayLiteralExpr) {
        defer {
            expr.fallbackToErrorType(assignable: false)
            expr.type!.assignable = false
        }
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
        // add in the implicit type conversions
        for i in 0..<expr.values.count {
            if !typesIsEqual(inferredType, expr.values[i].type!) {
                expr.values[i] = ImplicitCastExpr(expression: expr.values[i], type: inferredType, startLocation: expr.startLocation, endLocation: expr.endLocation)
            }
        }
        
        if inferredType is QsErrorType {
            // propogate the error
            expr.type = QsErrorType()
        } else {
            expr.type = QsArray(contains: inferredType)
        }
    }
    
    internal func visitStaticClassExpr(expr: StaticClassExpr) {
        // handle it at its source (CallExprs and GetExprs)
        // should never be visited
    }
    
    internal func visitThisExpr(expr: ThisExpr) {
        defer {
            expr.fallbackToErrorType(assignable: false)
            expr.type!.assignable = false
        }
        if expr.symbolTableIndex == nil {
            return
        }
        let symbol = symbolTable.getSymbol(id: expr.symbolTableIndex!) as! VariableSymbol
        expr.type = symbol.type
        if expr.type == nil {
            return
        }
    }
    
    internal func visitSuperExpr(expr: SuperExpr) {
        defer {
            expr.fallbackToErrorType(assignable: true)
            expr.type!.assignable = true
        }
        if expr.propertyId == nil {
            return
        }
        let symbol = symbolTable.getSymbol(id: expr.propertyId!) as! VariableSymbol
        expr.type = symbol.type
    }
    
    internal func visitVariableExpr(expr: VariableExpr) {
        defer {
            expr.fallbackToErrorType(assignable: true)
            // IMPORTANT: whether the type of this expression is assignable depends on the actual property. be careful to set assignable here
        }
        if expr.name.lexeme == "super" && currentClassIndex != nil {
            let currentClassSymbol = symbolTable.getSymbol(id: currentClassIndex!) as! ClassSymbol
            if currentClassSymbol.upperClass != nil {
                let parentClass = currentClassSymbol.upperClass!
                let parentClassSymbol = symbolTable.getSymbol(id: parentClass) as! ClassSymbol
                expr.type = QsClass(name: parentClassSymbol.displayName, id: parentClass, assignable: false)
                return
            }
        }
        if expr.symbolTableIndex == nil {
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
            case .fieldIniting:
                assertionFailure("FieldIniting variable status unexpected")
            case .uninit:
                typeGlobal(id: expr.symbolTableIndex!)
                expr.type = globalEntry.type!
            case .globalIniting:
                // circular
                return
            }
        case is VariableSymbol:
            if (symbolEntry as! VariableSymbol).type == nil {
                return
            } else {
                expr.type = (symbolEntry as! VariableSymbol).type!
                expr.type!.assignable = true
            }
        default:
            assertionFailure("Symbol entry for variable expression must be of type Variable or Function!")
        }
    }
    
    internal func visitSubscriptExpr(expr: SubscriptExpr) {
        defer {
            expr.fallbackToErrorType(assignable: true)
            expr.type!.assignable = true
        }
        // the index and the expression must both be indexable
        typeCheck(expr.index)
        assertType(expr: expr.index, errorMessage: "Array subscript is not an integer", typeAssertions: .isType(QsInt()))
        typeCheck(expr.expression)
        // expression must be of type array
        if assertType(expr: expr.expression, errorMessage: "Subscripted expression is not an array", typeAssertions: .isArray) {
            let expressionArray = expr.expression.type as! QsArray
            expr.type = expressionArray.contains
            return
        }
    }
    
    private func pickBestFunctions(potentialFunctions: [Int], withParameters: [Expr]) -> [Int] {
        return pickBestFunctions(potentialFunctions: potentialFunctions, withParameters: withParameters.map({ expr in
            expr.type!
        }))
    }
    
    private func pickBestFunctions(potentialFunctions: [Int], withParameters: [QsType]) -> [Int] {
        var bestMatches: [Int] = []
        var bestMatchLevel = Int.max
        var bestMatchBelongsToClassId = -1 // the symbol table ID for the class symbol to which the best classes belong to
        for potentialFunction in potentialFunctions {
            guard let functionSymbolEntry = symbolTable.getSymbol(id: potentialFunction) as? FunctionLikeSymbol else {
                assertionFailure("Symbol at index is not a function symbol")
                continue
                
            }
            if !functionSymbolEntry.paramRange.contains(withParameters.count) {
                // that's a no go
                continue
            }
            var matchLevel = 1
            for i in 0..<withParameters.count {
                let givenType = withParameters[i]
                let expectedType = functionSymbolEntry.functionParams[i].type
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
        return bestMatches
    }
    
    internal func visitCallExpr(expr: CallExpr) {
        defer {
            expr.fallbackToErrorType(assignable: false)
            expr.type!.assignable = false
        }
        if expr.object != nil {
            typeCheck(expr.object!)
        }
        for argument in expr.arguments {
            typeCheck(argument)
        }
        
        // Find all the functions that can be called
        var potentialFunctions: [Int] = []
        
        var blockPolymorphicCall = false
        let currentSymbolTablePosition = symbolTable.getCurrentTableId()
        defer {
            symbolTable.gotoTable(currentSymbolTablePosition)
        }
        enum FunctionsFilter {
            case leaveStatic
            case leaveNonstatic
            case leavePublic
            case leavePublicAndPrivateOfClass(Int)
            case removeConstructors
            case leaveConstructorsOfClass(Int)
        }
        func filterPotentialFunctions(functionsFilter: FunctionsFilter...) {
            var removeIsStatic: Bool?
            var removeIsPrivate: Bool?
            var doNotRemovePrivateOfClass: Int?
            var removeConstructor: Bool?
            var doNotRemoveConstructorOfClass: Int?
            for filter in functionsFilter {
                switch filter {
                case .leaveNonstatic:
                    removeIsStatic = true
                case .leaveStatic:
                    removeIsStatic = false
                case .leavePublic:
                    removeIsPrivate = true
                case .leavePublicAndPrivateOfClass(let classId):
                    doNotRemovePrivateOfClass = classId
                case .removeConstructors:
                    removeConstructor = true
                case .leaveConstructorsOfClass(let classId):
                    doNotRemoveConstructorOfClass = classId
                }
            }
            potentialFunctions.removeAll { val in
                let functionSymbol = symbolTable.getSymbol(id: val) as! MethodSymbol
                if removeIsStatic != nil && functionSymbol.isStatic == removeIsStatic {
                    return true
                }
                if removeIsPrivate == true && functionSymbol.visibility == .PRIVATE && doNotRemovePrivateOfClass != functionSymbol.withinClass {
                    return true
                }
                if removeConstructor == true && functionSymbol.isConstructor && doNotRemoveConstructorOfClass != functionSymbol.withinClass {
                    return true
                }
                return false
            }
        }
        if expr.object == nil {
            // look up an instance method, a class method, or a global function
            // cannot be polymorphic
            blockPolymorphicCall = true
            let allMethods = symbolTable.getAllMethods(methodName: expr.property.lexeme)
            if allMethods == [] {
                // search for global functions
                let globalFunctionNameSymbol = symbolTable.queryAtGlobalOnly("#FuncName#\(expr.property.lexeme)")
                if globalFunctionNameSymbol != nil {
                    let globalFunctionNameSymbol = globalFunctionNameSymbol as! FunctionNameSymbol
                    potentialFunctions.append(contentsOf: globalFunctionNameSymbol.belongingFunctions)
                }
            } else {
                // no constructors!
                potentialFunctions = allMethods
                filterPotentialFunctions(functionsFilter: .removeConstructors)
            }
        } else if expr.object is ThisExpr || expr.object is GetExpr || expr.object is VariableExpr {
            // look up an instance method on the object
            if expr.object is ThisExpr {
                blockPolymorphicCall = true
            }
            if expr.object!.type is QsClass {
                let objectClassType = expr.object!.type! as! QsClass
                let classSymbol = symbolTable.getSymbol(id: objectClassType.id) as! ClassSymbol
                symbolTable.gotoTable(classSymbol.classScopeSymbolTableIndex!)
                potentialFunctions = symbolTable.getAllMethods(methodName: expr.property.lexeme)
                if expr.object is VariableExpr && (expr.object as! VariableExpr).name.lexeme == "super" {
                    filterPotentialFunctions(functionsFilter: .removeConstructors, .leaveConstructorsOfClass(objectClassType.id))
                    // 'super' is dependent on whether the context is static or nonstatic
                    if currentFunctionIndex != nil {
                        let currentFunctionSymbol = symbolTable.getSymbol(id: currentFunctionIndex!)
                        if currentFunctionSymbol is MethodSymbol {
                            let currentFunctionSymbol = currentFunctionSymbol as! MethodSymbol
                            let isStatic = currentFunctionSymbol.isStatic
                            // got whether or not its static, now filter through
                            if isStatic {
                                filterPotentialFunctions(functionsFilter: .leaveStatic)
                            }
                        }
                    }
                } else {
                    // filter through and get only the instance methods
                    filterPotentialFunctions(functionsFilter: .leaveNonstatic)
                }
                filterPotentialFunctions(functionsFilter: .removeConstructors)
                // filter through public and private
                if currentClassIndex != nil {
                    filterPotentialFunctions(functionsFilter: .leavePublic, .leavePublicAndPrivateOfClass(currentClassIndex!))
                } else {
                    filterPotentialFunctions(functionsFilter: .leavePublic)
                }
            }
        } else if expr.object is StaticClassExpr {
            blockPolymorphicCall = true
            // look up a class method on the object
            let object = expr.object as! StaticClassExpr
            if object.classId != nil {
                let classSymbol = symbolTable.getSymbol(id: object.classId!) as! ClassSymbol
                symbolTable.gotoTable(classSymbol.classScopeSymbolTableIndex!)
                potentialFunctions = symbolTable.getAllMethods(methodName: expr.property.lexeme)
                // filter through and get only the class methods
                filterPotentialFunctions(functionsFilter: .removeConstructors)
                filterPotentialFunctions(functionsFilter: .leaveStatic)
                if currentClassIndex != object.classId {
                    // filter to leave only public ones
                    filterPotentialFunctions(functionsFilter: .leavePublic)
                }
            }
        } else {
            assertionFailure("Call expression on unknown object")
            return
        }
        
        // find the best match based off of a "match level": the lower the level, the greater the function matches
        let bestMatches: [Int] = pickBestFunctions(potentialFunctions: potentialFunctions, withParameters: expr.arguments)
        if bestMatches.count == 0 {
            error(message: "No matching function to call", on: expr)
            return
        }
        if bestMatches.count > 1 {
            error(message: "Function call is ambiguous", on: expr)
            return
        }
        let functionSymbolEntry = symbolTable.getSymbol(id: bestMatches[0]) as! FunctionLikeSymbol
        for i in 0..<expr.arguments.count {
            let givenType = expr.arguments[i].type!
            let expectedType = functionSymbolEntry.functionParams[i].type
            if !typesIsEqual(givenType, expectedType) {
                expr.arguments[i] = ImplicitCastExpr(expression: expr.arguments[i], type: expectedType, startLocation: expr.startLocation, endLocation: expr.endLocation)
            }
        }
        let resolvedFunctionSymbol = symbolTable.getSymbol(id: bestMatches[0])
        if let typedResolvedFunctionSymbol = resolvedFunctionSymbol as? FunctionSymbol {
            expr.uniqueFunctionCall = bestMatches[0]
            expr.type = typedResolvedFunctionSymbol.returnType
        } else if let typedResolvedFunctionSymbol = resolvedFunctionSymbol as? MethodSymbol {
            if typedResolvedFunctionSymbol.isStatic || blockPolymorphicCall || typedResolvedFunctionSymbol.overridedBy.isEmpty {
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
    }
    
    internal func visitGetExpr(expr: GetExpr) {
        defer {
            expr.fallbackToErrorType(assignable: true)
            // IMPORTANT: whether the type of this expression is assignable depends on the actual property. be careful to set assignable here
        }
        typeCheck(expr.object)
        
        let previousSymbolTableLocation = symbolTable.getCurrentTableId()
        defer {
            symbolTable.gotoTable(previousSymbolTableLocation)
        }
        
        // get expressions fall generally under these categories:
        // static getters: from StaticClassExprs
        // public instance property and language property (only array.length) getters: from variables, ArrayLiteralExprs, SubscriptExprs, CallExprs, other GetExprs, CastExprs, ArrayAllocationExprs, ClassAllocationExprs, BinaryExprs, SetExprs, AssignExprs, SuperExprs (the getting part for supers are handled within the resolver)
        // context-dependent getters: this (static and nonstatic)
        
        enum StaticLimit {
            case limitToStatic, limitToNonstatic, noLimit
        }
        
        func getPropertyForObject(property: Token, className: String, classSymbolScopeIndex: Int, staticLimit: StaticLimit) {
            symbolTable.gotoTable(classSymbolScopeIndex)
            
            let queriedSymbol = symbolTable.query(property.lexeme)
            let propertyDescription: String = {
                switch staticLimit {
                case .limitToStatic:
                    return "static"
                case .limitToNonstatic:
                    return "instance"
                case .noLimit:
                    return ""
                }
            }()
            let errorMessage = "Type '\(className)' has no \(propertyDescription + (propertyDescription == "" ? "" : " "))property '\(expr.property.lexeme)'"
            
            guard let queriedSymbol = queriedSymbol else {
                error(message: errorMessage, on: expr.property)
                return
            }
            guard let queriedSymbol = queriedSymbol as? VariableSymbol else {
                error(message: errorMessage, on: expr.property)
                return
            }
            
            if staticLimit == .limitToStatic {
                if queriedSymbol.variableType != .staticVar {
                    error(message: errorMessage, on: expr.property)
                    return
                }
            } else if staticLimit == .limitToNonstatic {
                if queriedSymbol.variableType != .instance {
                    error(message: errorMessage, on: expr.property)
                    return
                }
            }
            
            expr.type = queriedSymbol.type
            expr.type?.assignable = true
            expr.propertyId = queriedSymbol.id
        }
        func getPropertyForObject(property: Token, className: String, classId: Int, staticLimit: StaticLimit) {
            let symbol = symbolTable.getSymbol(id: classId) as! ClassSymbol
            getPropertyForObject(property: property, className: className, classSymbolScopeIndex: symbol.classScopeSymbolTableIndex!, staticLimit: staticLimit)
        }
        
        // static getters
        if expr.object is StaticClassExpr {
            let object = expr.object as! StaticClassExpr
            if object.classId == nil {
                return
            }
            
            let classSymbol = symbolTable.getSymbol(id: object.classId!) as! ClassSymbol
            getPropertyForObject(property: expr.property, className: classSymbol.displayName, classSymbolScopeIndex: classSymbol.classScopeSymbolTableIndex!, staticLimit: .limitToStatic)
            return
        } else if expr.object is ThisExpr {
            let object = expr.object as! ThisExpr
            if object.symbolTableIndex == nil {
                return
            }
            let symbol = symbolTable.getSymbol(id: object.symbolTableIndex!) as! VariableSymbol
            
            getPropertyForObject(property: expr.property, className: (object.type! as! QsClass).name, classSymbolScopeIndex: symbol.belongsToTable, staticLimit: symbol.variableType == .staticVar ? .limitToStatic : .noLimit)
            return
        } else {
            if expr.object.type is QsErrorType {
                return
            }
            let propertyDoesNotExistErrorMessage = "Value of type '\(printType(expr.object.type!))' has no property '\(expr.property)'"
            if expr.object.type is QsArray {
                // one built in property: length
                if expr.property.lexeme == "length" {
                    expr.type = QsInt(assignable: false)
                } else {
                    error(message: propertyDoesNotExistErrorMessage, on: expr)
                    return
                }
            } else if expr.object.type is QsClass {
                // fetch the instance property
                let objectType = expr.object.type as! QsClass
                getPropertyForObject(property: expr.property, className: objectType.name, classId: objectType.id, staticLimit: .limitToNonstatic)
            } else {
                error(message: propertyDoesNotExistErrorMessage, on: expr)
            }
        }
    }
    
    internal func visitUnaryExpr(expr: UnaryExpr) {
        defer {
            expr.fallbackToErrorType(assignable: false)
            expr.type!.assignable = false
        }
        typeCheck(expr.right)
        switch expr.opr.tokenType {
        case .NOT:
            expr.type = QsBoolean()
            assertType(expr: expr.right, errorMessage: "Unary operator '\(expr.opr.lexeme)' can only be applied to an operand of type 'boolean'", typeAssertions: .isType(QsBoolean(assignable: false)))
        case .MINUS:
            if assertType(expr: expr.right, errorMessage: "Unary operator '\(expr.opr.lexeme)' can only be applied to an operand of type 'int' or 'double'", typeAssertions: .isNumeric) {
                expr.type = expr.right.type
                return
            }
        default:
            assertionFailure("Unexpected unary expression token type \(expr.opr.tokenType)")
        }
    }
    
    internal func visitCastExpr(expr: CastExpr) {
        defer {
            expr.fallbackToErrorType(assignable: false)
            expr.type!.assignable = false
        }
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
            error(message: "Type '\(printType(expr.value.type))' cannot be cast to '\(castTo))'", on: expr.toType)
        }
    }
    
    internal func visitArrayAllocationExpr(expr: ArrayAllocationExpr) {
        defer {
            expr.fallbackToErrorType(assignable: false)
            expr.type!.assignable = false
        }
        var expressionType = typeCheck(expr.contains)
        for capacity in expr.capacity {
            typeCheck(capacity)
            assertType(expr: capacity, errorMessage: "Expect type 'int' for array capacity", typeAssertions: .isType(QsInt()))
            expressionType = QsArray(contains: expressionType)
        }
        expr.type = expressionType
    }
    
    internal func visitClassAllocationExpr(expr: ClassAllocationExpr) {
        defer {
            expr.fallbackToErrorType(assignable: false)
            expr.type!.assignable = false
        }
        let classSignature = generateClassSignature(className: expr.classType.name.lexeme, templateAstTypes: expr.classType.templateArguments)
        guard let classSymbol = symbolTable.queryAtGlobalOnly(classSignature) as? ClassSymbol else {
            return
        }
        expr.type = QsClass(name: classSymbol.displayName, id: classSymbol.id)
        for argument in expr.arguments {
            typeCheck(argument)
        }
        
        
        let previousSymbolTablePosition = symbolTable.getCurrentTableId()
        if classSymbol.classScopeSymbolTableIndex == nil {
            return
        }
        symbolTable.gotoTable(classSymbol.classScopeSymbolTableIndex!)
        defer {
            symbolTable.gotoTable(previousSymbolTablePosition)
        }
        
        let initializerFunctionNameSymbol = symbolTable.queryAtScopeOnly("#FuncName#"+classSymbol.displayName)
        let noInitializerFoundErrorMessage = "No matches in call to initializer"
        guard let initializerFunctionNameSymbol = initializerFunctionNameSymbol as? FunctionNameSymbol else {
            error(message: noInitializerFoundErrorMessage, on: expr)
            return
        }
        
        let bestMatches = pickBestFunctions(potentialFunctions: initializerFunctionNameSymbol.belongingFunctions, withParameters: expr.arguments)
        if bestMatches.count == 0 {
            error(message: noInitializerFoundErrorMessage, on: expr)
            return
        }
        if bestMatches.count > 1 {
            error(message: "Constructor call is ambiguous", on: expr)
            return
        }
        expr.callsFunction = bestMatches[0]
    }
    
    internal func visitBinaryExpr(expr: BinaryExpr) {
        // TODO: Implement cast to double
        defer {
            expr.fallbackToErrorType(assignable: false)
            expr.type!.assignable = false
        }
        // TODO
        typeCheck(expr.left)
        typeCheck(expr.right)
        
        func promoteToDoubleIfNecessary() {
            if expr.left.type! is QsDouble || expr.right.type! is QsDouble {
                if expr.left.type! is QsInt {
                    expr.left = ImplicitCastExpr(expression: expr.left, type: QsDouble(assignable: false), startLocation: expr.left.startLocation, endLocation: expr.left.endLocation)
                }
                if expr.right.type! is QsInt {
                    expr.right = ImplicitCastExpr(expression: expr.right, type: QsDouble(assignable: false), startLocation: expr.right.startLocation, endLocation: expr.right.endLocation)
                }
            }
        }
        
        switch expr.opr.tokenType {
        case .GREATER, .GREATER_EQUAL, .LESS, .LESS_EQUAL:
            expr.type = QsBoolean()
            if isNumericType(expr.left.type!) && isNumericType(expr.right.type!) {
                promoteToDoubleIfNecessary()
                return
            }
            // TODO: Strings
        case .EQUAL_EQUAL, .BANG_EQUAL:
            expr.type = QsBoolean()
            if isNumericType(expr.left.type!) && isNumericType(expr.right.type!) {
                promoteToDoubleIfNecessary()
                return
            }
            if typesIsEqual(expr.left.type!, QsBoolean()) && typesIsEqual(expr.right.type!, QsBoolean()) {
                return
            }
            // TODO: Strings
        case .MINUS, .SLASH, .STAR, .DIV:
            expr.type = QsErrorType()
            if isNumericType(expr.left.type!) && isNumericType(expr.right.type!) {
                promoteToDoubleIfNecessary()
                if expr.opr.tokenType == .DIV {
                    expr.type = QsInt()
                } else {
                    expr.type = expr.left.type!
                }
                return
            }
        case .MOD:
            expr.type = QsInt()
            if typesIsEqual(expr.left.type!, QsInt()) && typesIsEqual(expr.right.type!, QsInt()) {
                return
            }
        case .PLUS:
            if isNumericType(expr.left.type!) && isNumericType(expr.right.type!) {
                promoteToDoubleIfNecessary()
                expr.type = expr.left.type!
                return
            }
            // TODO: Strings
        default:
            expr.type = QsErrorType()
        }
        if !(expr.left.type is QsErrorType) && !(expr.right.type is QsErrorType) {
            error(message: "Binary operator '\(expr.opr.lexeme)' cannot be applied to operands of type '\(printType(expr.left.type))' and '\(printType(expr.right.type))'", on: expr)
        }

    }
    
    internal func visitLogicalExpr(expr: LogicalExpr) {
        defer {
            expr.fallbackToErrorType(assignable: false)
            expr.type!.assignable = false
        }
        typeCheck(expr.left)
        typeCheck(expr.right)
        expr.type = QsBoolean()
        if !(assertType(expr: expr.left, errorMessage: nil, typeAssertions: .isType(QsBoolean())) && assertType(expr: expr.right, errorMessage: nil, typeAssertions: .isType(QsBoolean()))) {
            error(message: "Binary operator '\(expr.opr.lexeme)' can only be applied to operands of type 'boolean' and 'boolean'", on: expr)
        }
    }
    
    private func typeVariable(variable: VariableExpr, type: QsType) {
        // adds the type of a variable into the symbol table and also updates the type in the variableExpr
        if variable.symbolTableIndex == nil {
            return
        }
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
        if variableExpr.symbolTableIndex == nil {
            return nil
        }
        if symbolTable.getSymbol(id: variableExpr.symbolTableIndex!) is GlobalVariableSymbol {
            return variableExpr.symbolTableIndex!
        }
        return nil
    }
    
    internal func visitSetExpr(expr: SetExpr) {
        defer {
            expr.fallbackToErrorType(assignable: false)
            expr.type!.assignable = false
        }
        typeCheck(expr.value)
        typeCheck(expr.to)
        
        if !assertType(expr: expr.to, errorMessage: "Cannot assign to immutable value", typeAssertions: .isAssignable) {
            return
        }
        
        // assignment can be to: fields within classes
        assertType(expr: expr.value, errorMessage: "Type '\(printType(expr.value.type!))' cannot be cast to '\(printType(expr.to.type!))'", typeAssertions: .isSubTypeOf(expr.to.type!))
        expr.type = expr.to.type!
    }
    
    func visitAssignExpr(expr: AssignExpr) {
        defer {
            expr.fallbackToErrorType(assignable: false)
            expr.type!.assignable = false
        }
        
        typeCheck(expr.value)
        typeCheck(expr.to)
        
        if !expr.isFirstAssignment! { // type is not know yet if it is first assignment
            if !assertType(expr: expr.to, errorMessage: "Cannot assign to immutable value", typeAssertions: .isAssignable) {
                // this shouldn't be possible but... just in case constants are added in later on?
                return
            }
        }
        
        if expr.isFirstAssignment! {
            if expr.annotation != nil {
                let variableType = typeCheck(expr.annotation!)
                typeVariable(variable: expr.to, type: variableType)
                assertType(expr: expr.to, errorMessage: "Type '\(printType(expr.to.type))' cannot be cast to '\(printType(variableType))'", typeAssertions: .isSubTypeOf(variableType))
                expr.type = variableType
                return
            } else {
                // infer type
                // do not allow void to be assigned to a variable!
                if expr.value.type is QsVoidType {
                    error(message: "Type '\(printType(expr.value.type))' cannot be assigned to a variable", on: expr.value)
                    typeVariable(variable: expr.to, type: QsErrorType())
                } else {
                    typeVariable(variable: expr.to, type: expr.value.type!)
                    
                    expr.type = expr.to.type!
                }
                return
            }
        } else {
            assertType(expr: expr.value, errorMessage: "Type '\(printType(expr.value.type!))' cannot be cast to '\(printType(expr.to.type!))'", typeAssertions: .isSubTypeOf(expr.to.type!))
            expr.type = expr.to.type!
        }
    }
    
    func visitIsTypeExpr(expr: IsTypeExpr) {
        defer {
            expr.fallbackToErrorType(assignable: false)
            expr.type!.assignable = false
        }
        typeCheck(expr.left)
        expr.rightType = typeCheck(expr.right)
        expr.type = QsBoolean()
    }
    
    func visitImplicitCastExpr(expr: ImplicitCastExpr) {
        assertionFailure("Implicit cast expression should not be visited!")
    }
    
    internal func visitClassStmt(stmt: ClassStmt) {
        if stmt.symbolTableIndex == nil {
            return
        }
        let previousSymbolTableIndex = symbolTable.getCurrentTableId()
        symbolTable.gotoTable(stmt.scopeIndex!)
        let previousClassIndex = currentClassIndex
        currentClassIndex = stmt.symbolTableIndex
        defer {
            symbolTable.gotoTable(previousSymbolTableIndex)
            currentClassIndex = previousClassIndex
        }
        // type all of the fields
        func typeField(_ field: AstClassField) {
            if field.symbolTableIndex == nil {
                return
            }
            let fieldSymbol = symbolTable.getSymbol(id: field.symbolTableIndex!) as! VariableSymbol
            if field.initializer != nil {
                typeCheck(field.initializer!)
            }
            let fieldType = fieldSymbol.type!
            if field.initializer != nil {
                assertType(expr: field.initializer!, errorMessage: "Type '\(printType(field.initializer!.type))' cannot be cast to '\(printType(fieldType))'", typeAssertions: .isSubTypeOf(fieldType))
            }
        }
        for field in stmt.fields {
            typeField(field)
        }
        let symbol = symbolTable.getSymbol(id: stmt.symbolTableIndex!) as! ClassSymbol
        if stmt.staticThisSymbolTableIndex != nil && stmt.instanceThisSymbolTableIndex != nil && stmt.symbolTableIndex != nil {
            let relatedInstanceThisSymbol = symbolTable.getSymbol(id: stmt.instanceThisSymbolTableIndex!) as! VariableSymbol
            relatedInstanceThisSymbol.type = QsClass(name: symbol.displayName, id: stmt.symbolTableIndex!)
            let relatedStaticThisSymbol = symbolTable.getSymbol(id: stmt.staticThisSymbolTableIndex!) as! VariableSymbol
            relatedStaticThisSymbol.type = QsClass(name: symbol.displayName, id: stmt.symbolTableIndex!)
        }
        
        // type all of the methods
        for method in stmt.methods {
            processMethodStmt(stmt: method, isInitializer: method.function.name.lexeme == stmt.name.lexeme, accompanyingClassStmt: stmt)
        }
    }
    
    private func processMethodStmt(stmt: MethodStmt, isInitializer: Bool, accompanyingClassStmt: ClassStmt) {
        // otherwise just process it like a function
        typeCheck(stmt.function)
        let isDub = stmt.function.keyword.isDummy()
        
        if isInitializer && !isDub {
            let instanceVariableHasInitializedInInitializerChecker = InstanceVariableHasInitializedInInitializerChecker(
                reportErrorForReturnStatement: { returnStmt, message in
                    self.error(message: message, on: returnStmt.keyword)
                },
                reportErrorForExpression: { expr, message in
                    self.error(message: message, on: expr)
                },
                reportEndingError: { message in
                    self.error(message: message, on: stmt.function.endOfFunction)
                },
                symbolTable: symbolTable
            )
            for field in accompanyingClassStmt.fields {
                if field.symbolTableIndex != nil {
                    instanceVariableHasInitializedInInitializerChecker.trackVariable(variableId: field.symbolTableIndex!)
                }
            }
            if accompanyingClassStmt.symbolTableIndex != nil {
                
                instanceVariableHasInitializedInInitializerChecker.checkStatements(stmt.function.body, withinClass: accompanyingClassStmt.symbolTableIndex!)
            }
        }
    }
    
    internal func visitMethodStmt(stmt: MethodStmt) {
        assertionFailure("visitMethodStmt should never be called!")
        // this should never be visited
    }
    
    internal func visitFunctionStmt(stmt: FunctionStmt) {
        if stmt.scopeIndex == nil {
            return
        }
        let previousSymbolTablePosition = symbolTable.getCurrentTableId()
        symbolTable.gotoTable(stmt.scopeIndex!)
        let previousFunctionIndex = currentFunctionIndex
        currentFunctionIndex = stmt.symbolTableIndex
        defer {
            symbolTable.gotoTable(previousSymbolTablePosition)
            currentFunctionIndex = previousFunctionIndex
        }
        
        // parameters are already typed
        for stmt in stmt.body {
            typeCheck(stmt)
        }
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
        if stmt.value != nil {
            typeCheck(stmt.value!)
        }
        if currentFunctionIndex != nil {
            let symbol = symbolTable.getSymbol(id: currentFunctionIndex!) as! FunctionLikeSymbol
            let returnType = symbol.returnType
            if returnType is QsVoidType {
                if stmt.value != nil {
                    error(message: "Expected non-void return value in void function", on: stmt.value!)
                }
            } else {
                if stmt.value == nil {
                    error(message: "Non-void function should return a value", on: stmt.keyword)
                } else {
                    assertType(expr: stmt.value!, errorMessage: "Cannot convert return expression of type '\(printType(stmt.value!.type))' to return type '\(printType(returnType))'", typeAssertions: .isSubTypeOf(returnType))
                }
            }
        }
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
        let previousSymbolTablePosition = symbolTable.getCurrentTableId()
        symbolTable.gotoTable(stmt.scopeIndex!)
        defer {
            symbolTable.gotoTable(previousSymbolTablePosition)
        }
        for statement in stmt.statements {
            typeCheck(statement)
        }
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
    
    private func typeFunction(functionStmt: FunctionStmt) {
        if functionStmt.symbolTableIndex == nil {
            return
        }
        var functionSymbol = symbolTable.getSymbol(id: functionStmt.symbolTableIndex!) as! FunctionLikeSymbol
        if functionStmt.annotation != nil {
            functionSymbol.returnType = typeCheck(functionStmt.annotation!)
        } else {
            functionSymbol.returnType = QsVoidType()
        }
        var functionParams: [FunctionParam] = []
        for i in 0..<functionStmt.params.count {
            let param = functionStmt.params[i]
            var paramType: QsType = QsAnyType(assignable: false)
            if param.astType != nil {
                paramType = typeCheck(param.astType!)
            }
            if functionStmt.params[i].symbolTableIndex != nil {
                let symbol = self.symbolTable.getSymbol(id: functionStmt.params[i].symbolTableIndex!) as! VariableSymbol
                symbol.type = paramType
            }
            functionParams.append(.init(name: param.name.lexeme, type: paramType))
        }
        functionSymbol.functionParams = functionParams
        print("Set to", functionParams)
    }
    
    private func typeFunctions(statements: [Stmt]) {
        // assign types to their parameters and their return types
        for statement in statements {
            if statement is ClassStmt {
                let statement = statement as! ClassStmt
                typeFunctions(statements: statement.methods)
                continue
            }
            var functionStmt: FunctionStmt
            if statement is FunctionStmt {
                functionStmt = statement as! FunctionStmt
            } else if statement is MethodStmt {
                functionStmt = (statement as! MethodStmt).function
            } else {
                continue
            }
            typeFunction(functionStmt: functionStmt)
        }
    }
    
    private func typeClassFields(classStmt: ClassStmt) {
        func typeField(classField: AstClassField) {
            guard let symbolTableIndex = classField.symbolTableIndex else {
                return
            }
            let symbol = symbolTable.getSymbol(id: symbolTableIndex) as! VariableSymbol
            symbol.type = typeCheck(classField.astType)
        }
        for field in classStmt.fields {
            typeField(classField: field)
        }
    }
    
    private func typeClassFields(statements: [Stmt]) {
        for statement in statements {
            if statement is ClassStmt {
                typeClassFields(classStmt: statement as! ClassStmt)
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
        
        typeFunctions(statements: statements)
        typeClassFields(statements: statements)
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
    private func error(message: String, on: Expr) -> TypeCheckerError {
        return error(message: message, start: on.startLocation, end: on.endLocation)
    }
    private func error(message: String, on: AstType) -> TypeCheckerError {
        return error(message: message, start: on.startLocation, end: on.endLocation)
    }
    private func error(message: String, on: Token) -> TypeCheckerError {
        return error(message: message, start: on.startLocation, end: on.endLocation)
    }
}
