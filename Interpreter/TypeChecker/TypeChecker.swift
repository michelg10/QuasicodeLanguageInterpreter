// swiftlint:disable:next type_body_length
class TypeChecker: ExprVisitor, StmtVisitor, AstTypeQsTypeVisitor {
    private var problems: [InterpreterProblem] = []
    private var symbolTable: SymbolTables = .init()
    // type checker needs to know:
    // current function / method the checker is currently in for return checks
    // current class the checker is currently in for public / private checks and super checks
    var currentFunctionIndex: Int?
    var currentClassIndex: Int?
    var stringClassId: Int = -1
    
    private func isInMethod() -> Bool {
        return currentFunctionIndex != nil && currentClassIndex != nil
    }
    
    private func findCommonType(_ lhs: QsType, _ rhs: QsType) -> QsType {
        if lhs is QsErrorType || rhs is QsErrorType {
            return QsErrorType()
        }
        if lhs is QsVoidType || rhs is QsVoidType {
            return QsVoidType()
        }
        if typesEqual(lhs, rhs, anyEqAny: true) {
            return lhs
        }
        if lhs is QsAnyType || rhs is QsAnyType {
            return QsAnyType()
        }
        if lhs is QsNativeType || rhs is QsNativeType {
            if !(lhs is QsNativeType && rhs is QsNativeType) {
                // if one of them is a native type but one of them aren't
                return QsAnyType()
            }
            
            // both of them are of QsNativeType and are different
            // case 1: one of them is boolean. thus the other one must be int or double
            if lhs is QsBoolean || rhs is QsBoolean {
                return QsAnyType()
            }
            
            // if none of them are QsBoolean, then one must be QsInt and another must be QsDouble. the common type there is QsDouble, so return that
            return QsDouble()
        }
        if lhs is QsArray || rhs is QsArray {
            if !(lhs is QsArray && rhs is QsArray) {
                // one of them is a QsArray but another isn't
                return QsAnyType()
            }
            
            // both are QsArrays
            return QsArray(contains: findCommonType((lhs as! QsArray).contains, (rhs as! QsArray).contains))
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
            if lhs is QsClass || rhs is QsClass {
                if !(lhs is QsClass && rhs is QsClass) {
                    // one of them is a QsClass but another isn't
                    return QsAnyType()
                }
                // they're unequal, so jump up the chain
                // let the depth of aClass is deeper than bClass
                var aClassSymbol = symbolTable.getSymbol(id: (lhs as! QsClass).id) as! ClassSymbol
                var bClassSymbol = symbolTable.getSymbol(id: (rhs as! QsClass).id) as! ClassSymbol
                if aClassSymbol.depth == nil || bClassSymbol.depth == nil {
                    return QsErrorType()
                }
                if aClassSymbol.depth! < bClassSymbol.depth! {
                    swap(&aClassSymbol, &bClassSymbol)
                }
                let depthDiff = abs(aClassSymbol.depth! - bClassSymbol.depth!)
                for _ in 0..<depthDiff {
                    aClassSymbol = try jumpUpHierarchy(classSymbol: aClassSymbol)
                }
                
                assert(aClassSymbol.depth == bClassSymbol.depth, "Depth of chains should be identical!")
                
                // keep on jumping up for both until they are the same
                while aClassSymbol.id != bClassSymbol.id {
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
        case isString
        case isType(QsType)
        case isSubTypeOf(QsType)
        case isSuperTypeOf(QsType)
    }
    
    private func assertType(expr: Expr, errorMessage: String?, typeAssertions: [TypeAssertion]) -> Bool {
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
            case .isString:
                if !isStringType(expr.type!) {
                    return false
                }
            case .isType(let qsType):
                if qsType is QsErrorType {
                    return false
                }
                if !typesEqual(expr.type!, qsType, anyEqAny: true) {
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
                if !typesEqual(qsType, commonType, anyEqAny: true) {
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
                if !typesEqual(expr.type!, qsType, anyEqAny: true) {
                    if errorMessage != nil {
                        error(message: errorMessage!, on: expr)
                    }
                    return false
                }
            }
        }
        return true
    }
    
    private func assertType(expr: Expr, errorMessage: String?, typeAssertions: TypeAssertion...) -> Bool {
        return assertType(expr: expr, errorMessage: errorMessage, typeAssertions: typeAssertions)
    }
    
    private func isStringType(_ type: QsType) -> Bool {
        guard let type = type as? QsClass else {
            return false
        }
        if type.id == stringClassId {
            return true
        }
        return false
    }
    
    private func getStringType() -> QsType {
        return QsClass(name: "String", id: stringClassId)
    }
    
    private func implicitlyCastExprOfSubTypeToType(expr: inout Expr, toType: QsType, reportError: Bool) -> Bool {
        // attempted implicit casts may fail for casting to and from array types
        // the rules for implicitly casting arrays are: casting single elements are OK, just not arrays
        
        if let toType = toType as? QsArray {
            if let expr = expr as? ArrayLiteralExpr {
                var canCast = true
                for i in 0..<expr.values.count {
                    canCast = canCast && implicitlyCastExprOfSubTypeToType(expr: &expr.values[i], toType: toType.contains, reportError: reportError)
                }
                return canCast
            } else {
                if reportError {
                    error(message: "Cannot convert value of type '\(printType(expr.type))' to expected element type '\(printType(toType))'", on: expr)
                }
                return false
            }
        } else {
            if !typesEqual(expr.type!, toType, anyEqAny: true) {
                expr = ImplicitCastExpr(expression: expr, type: toType, startLocation: expr.startLocation, endLocation: expr.endLocation)
            }
            return true
        }
    }
    
    func visitGroupingExpr(expr: GroupingExpr) {
        defer {
            expr.fallbackToErrorType(assignable: false)
            expr.type!.assignable = false
        }
        
        typeCheck(expr.expression)
        expr.type = expr.expression.type
    }
    
    func visitLiteralExpr(expr: LiteralExpr) {
        // already done
    }
    
    func visitArrayLiteralExpr(expr: ArrayLiteralExpr) {
        defer {
            expr.fallbackToErrorType(assignable: false)
            expr.type!.assignable = false
        }
        if expr.values.isEmpty {
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
            implicitlyCastExprOfSubTypeToType(expr: &expr.values[i], toType: inferredType, reportError: true)
        }
        
        if inferredType is QsErrorType {
            // propogate the error
            expr.type = QsErrorType()
        } else {
            expr.type = QsArray(contains: inferredType)
        }
    }
    
    func visitStaticClassExpr(expr: StaticClassExpr) {
        // handle it at its source (CallExprs and GetExprs)
        // should never be visited
    }
    
    func visitThisExpr(expr: ThisExpr) {
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
    
    func visitSuperExpr(expr: SuperExpr) {
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
    
    func visitVariableExpr(expr: VariableExpr) {
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
    
    func visitSubscriptExpr(expr: SubscriptExpr) {
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
                if typesEqual(givenType, expectedType, anyEqAny: true) {
                    matchLevel = max(matchLevel, 1)
                    continue
                }
                let commonType = findCommonType(givenType, expectedType)
                if typesEqual(commonType, expectedType, anyEqAny: true) {
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
    
    // swiftlint:disable:next function_body_length
    func visitCallExpr(expr: CallExpr) {
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
            if allMethods.isEmpty {
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
        if bestMatches.isEmpty {
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
            implicitlyCastExprOfSubTypeToType(expr: &expr.arguments[i], toType: expectedType, reportError: true)
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
    
    private enum StaticLimit {
        case limitToStatic, limitToNonstatic, noLimit
    }
    
    private struct ComputedObjectPropertyInfo {
        var type: QsType
        var propertyId: Int
    }
    
    private func getPropertyForObject(
        property: Token,
        className: String,
        classSymbolScopeIndex: Int,
        staticLimit: StaticLimit
    ) -> ComputedObjectPropertyInfo? {
        let previousSymbolTableLocation = symbolTable.getCurrentTableId()
        defer {
            symbolTable.gotoTable(previousSymbolTableLocation)
        }
        
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
        let errorMessage = "Type '\(className)' has no \(propertyDescription + (propertyDescription.isEmpty ? "" : " "))property '\(property.lexeme)'"
        
        guard let queriedSymbol = queriedSymbol else {
            error(message: errorMessage, on: property)
            return nil
        }
        guard let queriedSymbol = queriedSymbol as? VariableSymbol else {
            error(message: errorMessage, on: property)
            return nil
        }
        
        if staticLimit == .limitToStatic {
            if queriedSymbol.variableType != .staticVar {
                error(message: errorMessage, on: property)
                return nil
            }
        } else if staticLimit == .limitToNonstatic {
            if queriedSymbol.variableType != .instance {
                error(message: errorMessage, on: property)
                return nil
            }
        }
        
        var type = queriedSymbol.type
        type?.assignable = true
        return ComputedObjectPropertyInfo(type: type!, propertyId: queriedSymbol.id)
    }
    
    private func getPropertyForObject(property: Token, className: String, classId: Int, staticLimit: StaticLimit) -> ComputedObjectPropertyInfo? {
        let symbol = symbolTable.getSymbol(id: classId) as! ClassSymbol
        return getPropertyForObject(
            property: property,
            className: className,
            classSymbolScopeIndex: symbol.classScopeSymbolTableIndex!,
            staticLimit: staticLimit
        )
    }
    
    func visitGetExpr(expr: GetExpr) {
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
        
        // static getters
        if expr.object is StaticClassExpr {
            let object = expr.object as! StaticClassExpr
            if object.classId == nil {
                return
            }
            
            let classSymbol = symbolTable.getSymbol(id: object.classId!) as! ClassSymbol
            let fetchedProperty = getPropertyForObject(
                property: expr.property,
                className: classSymbol.displayName,
                classSymbolScopeIndex: classSymbol.classScopeSymbolTableIndex!,
                staticLimit: .limitToStatic
            )
            
            expr.type = fetchedProperty?.type
            expr.propertyId = fetchedProperty?.propertyId
            return
        } else if expr.object is ThisExpr {
            let object = expr.object as! ThisExpr
            if object.symbolTableIndex == nil {
                return
            }
            let symbol = symbolTable.getSymbol(id: object.symbolTableIndex!) as! VariableSymbol
            
            let fetchedProperty = getPropertyForObject(
                property: expr.property,
                className: (object.type! as! QsClass).name,
                classSymbolScopeIndex: symbol.belongsToTable,
                staticLimit: symbol.variableType == .staticVar ? .limitToStatic : .noLimit
            )
            expr.type = fetchedProperty?.type
            expr.propertyId = fetchedProperty?.propertyId
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
                let fetchedProperty = getPropertyForObject(
                    property: expr.property,
                    className: objectType.name,
                    classId: objectType.id,
                    staticLimit: .limitToNonstatic
                )
                
                expr.type = fetchedProperty?.type
                expr.propertyId = fetchedProperty?.propertyId
            } else {
                error(message: propertyDoesNotExistErrorMessage, on: expr)
            }
        }
    }
    
    func visitUnaryExpr(expr: UnaryExpr) {
        defer {
            expr.fallbackToErrorType(assignable: false)
            expr.type!.assignable = false
        }
        typeCheck(expr.right)
        switch expr.opr.tokenType {
        case .NOT:
            expr.type = QsBoolean()
            assertType(
                expr: expr.right,
                errorMessage: "Unary operator '\(expr.opr.lexeme)' can only be applied to an operand of type 'boolean'",
                typeAssertions: .isType(QsBoolean(assignable: false))
            )
        case .MINUS:
            if assertType(
                expr: expr.right,
                errorMessage: "Unary operator '\(expr.opr.lexeme)' can only be applied to an operand of type 'int' or 'double'",
                typeAssertions: .isNumeric
            ) {
                expr.type = expr.right.type
                return
            }
        default:
            assertionFailure("Unexpected unary expression token type \(expr.opr.tokenType)")
        }
    }
    
    func visitCastExpr(expr: CastExpr) {
        defer {
            expr.fallbackToErrorType(assignable: false)
            expr.type!.assignable = false
        }
        typeCheck(expr.value)
        let castTo = typeCheck(expr.toType)
        expr.type = castTo
        if typesEqual(castTo, expr.value.type!, anyEqAny: true) {
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
        if typesEqual(commonType, expr.value.type!, anyEqAny: true) {
            // casting to a subclass
            return
        }
        if typesEqual(commonType, castTo, anyEqAny: true) {
            // casting to a superclass
            return
        }
        
        if !(expr.value.type is QsErrorType) {
            error(message: "Type '\(printType(expr.value.type))' cannot be cast to '\(castTo))'", on: expr.toType)
        }
    }
    
    func visitArrayAllocationExpr(expr: ArrayAllocationExpr) {
        defer {
            expr.fallbackToErrorType(assignable: false)
            expr.type!.assignable = false
        }
        let expressionType = typeCheck(expr.contains)
        for capacity in expr.capacity {
            typeCheck(capacity)
            assertType(expr: capacity, errorMessage: "Expect type 'int' for array capacity", typeAssertions: .isType(QsInt()))
        }
        expr.type = expressionType
    }
    
    func visitClassAllocationExpr(expr: ClassAllocationExpr) {
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
        
        let initializerFunctionNameSymbol = symbolTable.queryAtScopeOnly("#FuncName#" + classSymbol.nonSignatureName)
        let noInitializerFoundErrorMessage = "No matches in call to initializer"
        guard let initializerFunctionNameSymbol = initializerFunctionNameSymbol as? FunctionNameSymbol else {
            error(message: noInitializerFoundErrorMessage, on: expr)
            return
        }
        
        let bestMatches = pickBestFunctions(potentialFunctions: initializerFunctionNameSymbol.belongingFunctions, withParameters: expr.arguments)
        if bestMatches.isEmpty {
            error(message: noInitializerFoundErrorMessage, on: expr)
            return
        }
        if bestMatches.count > 1 {
            error(message: "Constructor call is ambiguous", on: expr)
            return
        }
        expr.callsFunction = bestMatches[0]
    }
    
    func visitBinaryExpr(expr: BinaryExpr) {
        defer {
            expr.fallbackToErrorType(assignable: false)
            expr.type!.assignable = false
        }
        typeCheck(expr.left)
        typeCheck(expr.right)
        
        func promoteToDoubleIfNecessary() {
            if expr.left.type! is QsDouble || expr.right.type! is QsDouble {
                implicitlyCastExprOfSubTypeToType(expr: &expr.left, toType: QsDouble(), reportError: true)
                implicitlyCastExprOfSubTypeToType(expr: &expr.right, toType: QsDouble(), reportError: true)
            }
        }
        
        switch expr.opr.tokenType {
        case .GREATER, .GREATER_EQUAL, .LESS, .LESS_EQUAL:
            expr.type = QsBoolean()
            if isNumericType(expr.left.type!) && isNumericType(expr.right.type!) {
                promoteToDoubleIfNecessary()
                return
            }
            
            if isStringType(expr.left.type!) && isStringType(expr.right.type!) {
                return
            }
        case .EQUAL_EQUAL, .BANG_EQUAL:
            expr.type = QsBoolean()
            if isNumericType(expr.left.type!) && isNumericType(expr.right.type!) {
                promoteToDoubleIfNecessary()
                return
            }
            if typesEqual(expr.left.type!, QsBoolean(), anyEqAny: false) && typesEqual(expr.right.type!, QsBoolean(), anyEqAny: false) {
                return
            }
            if isStringType(expr.left.type!) && isStringType(expr.right.type!) {
                return
            }
            if expr.left.type is QsArray && expr.right.type is QsArray {
                if typesEqual(expr.left.type!, expr.right.type!, anyEqAny: false) {
                    return
                }
            }
        case .MINUS, .SLASH, .STAR, .DIV:
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
            if typesEqual(expr.left.type!, QsInt(), anyEqAny: false) && typesEqual(expr.right.type!, QsInt(), anyEqAny: false) {
                return
            }
        case .PLUS:
            if isNumericType(expr.left.type!) && isNumericType(expr.right.type!) {
                promoteToDoubleIfNecessary()
                expr.type = expr.left.type!
                return
            }
            if isStringType(expr.left.type!) && isStringType(expr.right.type!) {
                expr.type = expr.left.type!
                return
            }
            if isStringType(expr.left.type!) || isStringType(expr.right.type!) {
                func canConcatenateWithString(_ expr: Expr) -> Bool {
                    let type = expr.type!
                    if isNumericType(type) {
                        return true
                    }
                    if type is QsBoolean {
                        return true
                    }
                    return false
                }
                if canConcatenateWithString(expr.left) || canConcatenateWithString(expr.right) {
                    expr.type = getStringType()
                    implicitlyCastExprOfSubTypeToType(expr: &expr.left, toType: getStringType(), reportError: true)
                    implicitlyCastExprOfSubTypeToType(expr: &expr.right, toType: getStringType(), reportError: true)
                    return
                }
            }
        default:
            expr.type = QsErrorType()
        }
        if !(expr.left.type is QsErrorType) && !(expr.right.type is QsErrorType) {
            error(
                message: "Binary operator '\(expr.opr.lexeme)' cannot be applied " +
                "to operands of type '\(printType(expr.left.type))' and '\(printType(expr.right.type))'",
                on: expr
            )
        }

    }
    
    func visitLogicalExpr(expr: LogicalExpr) {
        defer {
            expr.fallbackToErrorType(assignable: false)
            expr.type!.assignable = false
        }
        typeCheck(expr.left)
        typeCheck(expr.right)
        expr.type = QsBoolean()
        if !(
            assertType(expr: expr.left, errorMessage: nil, typeAssertions: .isType(QsBoolean())) &&
            assertType(expr: expr.right, errorMessage: nil, typeAssertions: .isType(QsBoolean()))
        ) {
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
        var typeCopy = type
        typeCopy.assignable = true
        symbol.type = typeCopy
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
    
    func visitVariableToSetExpr(expr: VariableToSetExpr) {
        defer {
            expr.fallbackToErrorType(assignable: true)
            expr.type!.assignable = true
        }
        
        typeCheck(expr.to)
        expr.type = expr.to.type
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
    
    func visitClassStmt(stmt: ClassStmt) {
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
                if assertType(
                    expr: field.initializer!,
                    errorMessage: "Type '\(printType(field.initializer!.type))' cannot be cast to '\(printType(fieldType))'",
                    typeAssertions: .isSubTypeOf(fieldType)
                ) {
                    implicitlyCastExprOfSubTypeToType(expr: &field.initializer!, toType: fieldType, reportError: true)
                }
                
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
            let instanceVariableHasInitializedInInitializerChecker = InstanceVariableInitializedInInitializerChecker(
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
            for field in accompanyingClassStmt.fields where field.symbolTableIndex != nil {
                instanceVariableHasInitializedInInitializerChecker.trackVariable(variableId: field.symbolTableIndex!)
            }
            if accompanyingClassStmt.symbolTableIndex != nil {
                
                instanceVariableHasInitializedInInitializerChecker.checkStatements(
                    stmt.function.body,
                    withinClass: accompanyingClassStmt.symbolTableIndex!
                )
            }
        }
    }
    
    func visitMethodStmt(stmt: MethodStmt) {
        assertionFailure("visitMethodStmt should never be called!")
        // this should never be visited
    }
    
    func visitFunctionStmt(stmt: FunctionStmt) {
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
        
        let functionSymbol = symbolTable.getSymbol(id: stmt.symbolTableIndex!) as! FunctionLikeSymbol
        if !(functionSymbol.returnType is QsVoidType) {
            // gaurentee a return
            var gaurenteeReturnChecker = GaurenteeReturnChecker {
                let functionSymbol = self.symbolTable.getSymbol(id: stmt.symbolTableIndex!) as! FunctionLikeSymbol
                self.error(message: "Missing return in function expected to return '\(printType(functionSymbol.returnType))'", on: stmt.endOfFunction)
            }
            gaurenteeReturnChecker.checkStatements(stmt.body)
        }
    }
    
    func visitExpressionStmt(stmt: ExpressionStmt) {
        typeCheck(stmt.expression)
    }
    
    func visitIfStmt(stmt: IfStmt) {
        typeCheck(stmt.condition)
        assertType(
            expr: stmt.condition,
            errorMessage: "Type '\(printType(stmt.condition.type))' cannot be used as a boolean",
            typeAssertions: .isType(QsBoolean())
        )
        typeCheck(stmt.thenBranch)
        for elseIfBranch in stmt.elseIfBranches {
            typeCheck(elseIfBranch)
        }
        if stmt.elseBranch != nil {
            typeCheck(stmt.elseBranch!)
        }
    }
    
    func visitOutputStmt(stmt: OutputStmt) {
        for expression in stmt.expressions {
            typeCheck(expression)
        }
    }
    
    func visitInputStmt(stmt: InputStmt) {
        for expression in stmt.expressions {
            typeCheck(expression)
            assertType(
                expr: expression,
                errorMessage: "Cannot assign to immutable value",
                typeAssertions: .isAssignable
            )
            assertType(
                expr: expression,
                errorMessage: "Cannot input to type '\(printType(expression.type!))'",
                typeAssertions: .isType(QsInt()),
                .isType(QsAnyType()),
                .isType(QsDouble()),
                .isString
            )
        }
    }
    
    func visitReturnStmt(stmt: ReturnStmt) {
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
                    if assertType(
                        expr: stmt.value!,
                        errorMessage: "Cannot convert return expression of type '\(printType(stmt.value!.type))' to return type '\(printType(returnType))'",
                        typeAssertions: .isSubTypeOf(returnType)
                    ) {
                        implicitlyCastExprOfSubTypeToType(expr: &stmt.value!, toType: returnType, reportError: true)
                    }
                }
            }
        }
    }
    
    func visitLoopFromStmt(stmt: LoopFromStmt) {
        typeCheck(stmt.lRange)
        typeCheck(stmt.rRange)
        if stmt.variable.type == nil {
            typeCheck(stmt.variable)
            assertType(
                expr: stmt.variable,
                errorMessage: "Type '\(printType(stmt.variable.type!))' cannot be used as an int",
                typeAssertions: .isType(QsInt())
            )
        }
        assertType(
            expr: stmt.lRange,
            errorMessage: "Type '\(printType(stmt.lRange.type!))' cannot be used as an int",
            typeAssertions: .isType(QsInt())
        )
        assertType(
            expr: stmt.rRange,
            errorMessage: "Type '\(printType(stmt.rRange.type!))' cannot be used as an int",
            typeAssertions: .isType(QsInt())
        )
        typeCheck(stmt.body)
    }
    
    func visitWhileStmt(stmt: WhileStmt) {
        typeCheck(stmt.expression)
        assertType(
            expr: stmt.expression,
            errorMessage: "Type '\(printType(stmt.expression.type!))' cannot be used as a boolean",
            typeAssertions: .isType(QsBoolean())
        )
        typeCheck(stmt.body)
    }
    
    func visitBreakStmt(stmt: BreakStmt) {
        // nothing to do
    }
    
    func visitContinueStmt(stmt: ContinueStmt) {
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
    
    func visitExitStmt(stmt: ExitStmt) {
        // nothing to do
    }
    
    func visitMultiSetStmt(stmt: MultiSetStmt) {
        for setStmt in stmt.setStmts {
            typeCheck(setStmt)
        }
    }
    
    func visitSetStmt(stmt: SetStmt) {
        // valid set to types:
        // GetExpr, SubscriptExpr, VariableSetExpr (wrapping VariableExpr), VariableExpr (only in chained)
        typeCheck(stmt.value)
        
        if stmt.left is VariableToSetExpr {
            let left = stmt.left as! VariableToSetExpr
            if left.isFirstAssignment! {
                if left.annotation != nil {
                    let variableType = typeCheck(left.annotation!)
                    typeVariable(variable: left.to, type: variableType)
                } else {
                    // type inference
                    // do not allow void to be assigned to a variable!
                    if stmt.value.type is QsVoidType {
                        error(message: "Type '\(printType(stmt.value.type))' cannot be assigned to a variable", on: stmt.value)
                        typeVariable(variable: left.to, type: QsErrorType())
                    } else {
                        typeVariable(variable: left.to, type: stmt.value.type!)
                    }
                }
            }
        }
        typeCheck(stmt.left)
        assertType(expr: stmt.left, errorMessage: "Cannot assign to immutable value", typeAssertions: .isAssignable)
        if assertType(expr: stmt.value, errorMessage: "Type '\(printType(stmt.value.type!))' cannot be cast to '\(printType(stmt.left.type!))'", typeAssertions: .isSubTypeOf(stmt.left.type!)) {
            implicitlyCastExprOfSubTypeToType(expr: &stmt.value, toType: stmt.left.type!, reportError: true)
        }
        
        for i in stmt.chained.indices {
            typeCheck(stmt.chained[i])
            assertType(expr: stmt.chained[i], errorMessage: "Cannot assign to immutable value", typeAssertions: .isAssignable)
            assertType(expr: stmt.chained[i], errorMessage: "lvalues in chained equality expressions must be of the same type", typeAssertions: .isType(stmt.left.type!))
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
        for statement in statements where statement is ClassStmt {
            typeClassFields(classStmt: statement as! ClassStmt)
        }
    }
    
    private func typeGlobal(id: Int) {
        let globalVariableSymbol = symbolTable.getSymbol(id: id) as! GlobalVariableSymbol
        globalVariableSymbol.variableStatus = .globalIniting
        typeCheck(globalVariableSymbol.globalDefiningSetExpr)
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
        stringClassId = symbolTable.queryAtGlobalOnly("String<>")?.id ?? -1
        
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
