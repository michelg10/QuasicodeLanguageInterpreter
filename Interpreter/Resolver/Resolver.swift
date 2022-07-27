class Resolver: ExprThrowVisitor, StmtVisitor {
    private enum FunctionType {
        case none, function, staticMethod, nonstaticMethod, initializer
    }
    private enum ResolverError: Error {
        case error(String)
    }
    private enum ClassType {
        case Class, Subclass
    }
    var superInitCallIsFirstLineOfInitializer: Bool? = nil // this is for the super expressions
    private struct ClassStatus {
        var classType: ClassType
        var name: String
        var symbolTableIndex: Int
    }
    
    // include functions and classes in the symbol table and resolve them like everything else
    private var isInLoop = false
    private var currentClassStatus: ClassStatus? = nil
    private var currentFunction: FunctionType = .none
    private var problems: [InterpreterProblem] = []
    private var symbolTable: SymbolTables = .init()
    private var isInGlobalScope = false
    
    internal func visitGroupingExpr(expr: GroupingExpr) throws {
        try resolve(expr.expression)
    }
    
    internal func visitLiteralExpr(expr: LiteralExpr) {
        // nothing
    }
    
    internal func visitArrayLiteralExpr(expr: ArrayLiteralExpr) throws {
        for value in expr.values {
            try resolve(value)
        }
    }
    
    internal func visitStaticClassExpr(expr: StaticClassExpr) throws {
        let symbol = symbolTable.query(generateClassSignature(className: expr.classType.name.lexeme, templateAstTypes: expr.classType.templateArguments))
        assert(symbol is ClassSymbol, "Expected class symbol")
        expr.classId = symbol!.id
    }
    
    internal func visitThisExpr(expr: ThisExpr) throws {
        if currentClassStatus == nil || currentFunction != .nonstaticMethod && currentFunction != .staticMethod && currentFunction != .initializer {
            throw error(message: "Cannot use 'this' outside of a method", token: expr.keyword)
        }
        if currentFunction == .staticMethod {
            expr.symbolTableIndex = symbolTable.query("$Static$this")?.id
        } else {
            expr.symbolTableIndex = symbolTable.query("$Instance$this")?.id
        }
        assert(expr.symbolTableIndex != nil, "'this' is undefined")
    }
    
    internal func visitSuperExpr(expr: SuperExpr) throws {
        if currentClassStatus?.classType != .Subclass {
            if currentClassStatus == nil {
                throw error(message: "'super' cannot be referenced outside of a class", token: expr.keyword)
            } else if currentClassStatus!.classType == .Class {
                throw error(message: "'super' cannot be referenced in a root class", token: expr.keyword)
            }
        }
        if currentFunction != .nonstaticMethod && currentFunction != .staticMethod && currentFunction != .initializer {
            throw error(message: "'super' cannot be referenced outside of a method", token: expr.keyword)
        }
        let currentClassSymbol = symbolTable.getSymbol(id: currentClassStatus!.symbolTableIndex) as! ClassSymbol
        if currentClassSymbol.upperClass == nil {
            return
        }
        let upperClass = symbolTable.getSymbol(id: currentClassSymbol.upperClass!) as! ClassSymbol
        if upperClass.classScopeSymbolTableIndex == nil {
            return
        }
        
        let previousSymbolTablePosition = symbolTable.getCurrentTableId()
        defer {
            symbolTable.gotoTable(previousSymbolTablePosition)
        }
        symbolTable.gotoTable(upperClass.classScopeSymbolTableIndex!)
        
        let findVariable = symbolTable.query(expr.property.lexeme)
        let errorString = "Superclass '\(upperClass.displayName)' has no member '\(expr.property.lexeme)'"
        if !(findVariable is VariableSymbol) {
            error(message: errorString, start: expr.startLocation, end: expr.endLocation)
            return
        }
        let variableSymbol = findVariable as! VariableSymbol
        switch variableSymbol.variableType {
        case .instance:
            expr.propertyId = variableSymbol.id
            if currentFunction == .staticMethod {
                error(message: "Instance member '\(expr.property.lexeme)' cannot be used in a static context", start: expr.startLocation, end: expr.endLocation)
            }
        case .staticVar:
            expr.propertyId = variableSymbol.id
        default:
            error(message: errorString, start: expr.startLocation, end: expr.endLocation)
        }
    }
    
    internal func visitVariableExpr(expr: VariableExpr) {
        if let existingSymbol = symbolTable.query(expr.name.lexeme) {
            if let symbol = existingSymbol as? VariableSymbol {
                // uninit -> is a global, init it
                // initing -> use of variable within its own declaration
                // globalIniting -> global circular reference
                // finishedInit -> no problem
                if symbol.variableType == .instance && currentFunction == .staticMethod {
                    error(message: "Use of instance variable from a static method", start: expr.startLocation, end: expr.endLocation)
                }
                switch symbol.variableStatus {
                case .uninit:
                    // is a global, init it
                    initGlobal(index: symbol.id)
                case .initing:
                    // use of variable within its own declaration
                    error(message: "Use of variable within its own declaration", token: expr.name)
                case .fieldIniting:
                    error(message: "Use of variable within class before class is available", start: expr.startLocation, end: expr.endLocation)
                case .globalIniting:
                    // global circular reference
                    error(message: "Circular reference", start: expr.startLocation, end: expr.endLocation)
                case .finishedInit:
                    // no problem
                    break
                }
            } else if let symbol = existingSymbol as? FunctionNameSymbol {
                if symbol.isForMethods {
                    let method = symbolTable.getSymbol(id: symbol.belongingFunctions[0]) as! MethodSymbol
                    if !method.finishedInit {
                        error(message: "Use of method within class before class is available", start: expr.startLocation, end: expr.endLocation)
                    }
                }
            }
            expr.symbolTableIndex = existingSymbol.id
        } else {
            error(message: "Use of unknown identifier \(expr.name.lexeme)", start: expr.startLocation, end: expr.endLocation)
        }
    }
    
    internal func visitSubscriptExpr(expr: SubscriptExpr) throws {
        try resolve(expr.expression)
        try resolve(expr.index)
    }
    
    internal func visitCallExpr(expr: CallExpr) throws {
        if expr.object != nil {
            var isSuperCall = false
            if expr.object is VariableExpr {
                let object = expr.object as! VariableExpr
                if object.name.lexeme == "super" {
                    // don't resolve and check if its in a method
                    isSuperCall = true
                    if currentFunction != .staticMethod && currentFunction != .initializer && currentFunction != .nonstaticMethod {
                        error(message: "'super' cannot be referenced outside of a method", start: expr.startLocation, end: expr.endLocation)
                    } else if currentClassStatus?.classType != .Subclass {
                        // must be in a method because it's an "else if," so if it's not a subclass then it must be a root class.
                        error(message: "'super' cannot be referenced in a root class", token: expr.property)
                    }
                }
            }
            if !isSuperCall {
                try resolve(expr.object!)
            }
        }
        if expr.property.lexeme == "super" {
            if currentClassStatus?.classType != .Subclass {
                if currentClassStatus?.classType == .Class {
                    error(message: "'super' cannot be referenced in a root class", token: expr.property)
                } else {
                    error(message: "'super' cannot be referenced outside of a class", token: expr.property)
                }
            } else {
                if currentFunction != .initializer {
                    error(message: "'super' cannot be called outside of a constructor", token: expr.property)
                } else {
                    if superInitCallIsFirstLineOfInitializer == true {
                        superInitCallIsFirstLineOfInitializer = false
                    } else {
                        error(message: "Call to 'super' must be first statement in constructor", token: expr.property)
                    }
                }
            }
        }
        for argument in expr.arguments {
            try resolve(argument)
        }
    }
    
    internal func visitGetExpr(expr: GetExpr) throws {
        try resolve(expr.object)
    }
    
    internal func visitUnaryExpr(expr: UnaryExpr) throws {
        try resolve(expr.right)
    }
    
    internal func visitCastExpr(expr: CastExpr) throws {
        try resolve(expr.value)
    }
    
    internal func visitArrayAllocationExpr(expr: ArrayAllocationExpr) throws {
        for expression in expr.capacity {
            try resolve(expression)
        }
    }
    
    internal func visitClassAllocationExpr(expr: ClassAllocationExpr) throws {
        for expression in expr.arguments {
            try resolve(expression)
        }
    }
    
    internal func visitBinaryExpr(expr: BinaryExpr) throws {
        try resolve(expr.left)
        try resolve(expr.right)
    }
    
    internal func visitLogicalExpr(expr: LogicalExpr) throws {
        try resolve(expr.left)
        try resolve(expr.right)
    }
    
    internal func visitSetExpr(expr: SetExpr) throws {
        try resolve(expr.to)
        try resolve(expr.value)
    }
    
    internal func visitAssignExpr(expr: AssignExpr) throws {
        // first figure out if it is a variable declaration (is first assignment)
        
        // isFirstAssignment being nil means that it needs to be computed.
        // true means that its already been computed and that the value must've already been resolved
        // false means that its already been computed, but the value might've not been resolved.
        if expr.isFirstAssignment == nil {
            if let existingSymbol = symbolTable.query(expr.to.name.lexeme) {
                if !(existingSymbol is VariableSymbol) {
                    // error! cannot assign
                    if existingSymbol is FunctionNameSymbol {
                        error(message: "Cannot assign to value: '\(expr.to.name.lexeme) is a function", token: expr.to.name)
                    } else if existingSymbol is ClassNameSymbol {
                        error(message: "Cannot assign to value: '\(expr.to.name.lexeme) is a class", token: expr.to.name)
                    } else {
                        assertionFailure("Unexpected symbol type!")
                        error(message: "Cannot assign to value", token: expr.to.name)
                    }
                    
                    try resolve(expr.value)
                    return
                }
                expr.isFirstAssignment = false
            } else {
                expr.isFirstAssignment = true
            }
            
            if expr.isFirstAssignment! {
                // define the variable but set it as unusable
                
                let associatedSymbol = VariableSymbol(name: expr.to.name.lexeme, variableStatus: .initing, variableType: .local)
                expr.to.symbolTableIndex = symbolTable.addToSymbolTable(symbol: associatedSymbol)
                defer {
                    associatedSymbol.variableStatus = .finishedInit
                }
                try resolve(expr.value)
            } else {
                if expr.annotation != nil {
                    error(message: "Cannot retype variable after first assignment", token: expr.annotationColon!)
                }
                try resolve(expr.to)
                try resolve(expr.value)
            }
        } else if expr.isFirstAssignment == false {
            try resolve(expr.value)
        }
    }
    
    func visitIsTypeExpr(expr: IsTypeExpr) throws {
        try resolve(expr.left)
    }
    
    func visitImplicitCastExpr(expr: ImplicitCastExpr) throws {
        assertionFailure("Implicit cast expression present in Resolver")
    }
    
    func defineVariableWithInitializer(name: Token, initializer: Expr?) -> Int? {
        // use this with function parameters, etc.
        if symbolTable.queryAtScopeOnly(name.lexeme) != nil {
            error(message: "Invalid redeclaration of \(name.lexeme)", token: name)
            return nil
        }
        let symbol = VariableSymbol(name: name.lexeme, variableStatus: .initing, variableType: .local)
        let symbolTableIndex = symbolTable.addToSymbolTable(symbol: symbol)
        if initializer != nil {
            catchErrorClosure {
                try resolve(initializer!)
            }
        }
        symbol.variableStatus = .finishedInit
        return symbolTableIndex
    }
    
    internal func visitClassStmt(stmt: ClassStmt) {
        guard stmt.symbolTableIndex != nil else {
            return
        }
        let currentClassName = stmt.name.lexeme
        
        let previousIsInGlobalScope = isInGlobalScope
        isInGlobalScope = false
        let previousSymbolTablePosition = symbolTable.getCurrentTableId()
        symbolTable.gotoTable(stmt.scopeIndex!)
    linkSymbolTableToSuperclass: if stmt.superclass != nil {
            let superclassSignature = generateClassSignature(className: stmt.superclass!.name.lexeme, templateAstTypes: stmt.superclass!.templateArguments)
            let superclassSymbol = symbolTable.queryAtGlobalOnly(superclassSignature)
            guard let superclassSymbol = superclassSymbol as? ClassSymbol else {
                break linkSymbolTableToSuperclass
            }
            if superclassSymbol.classScopeSymbolTableIndex != nil {
                symbolTable.linkCurrentTableToParent(superclassSymbol.classScopeSymbolTableIndex!)
            }
        }
        stmt.instanceThisSymbolTableIndex = symbolTable.addToSymbolTable(symbol: VariableSymbol(name: "$Instance$this", variableStatus: .finishedInit, variableType: .instance))
        stmt.staticThisSymbolTableIndex = symbolTable.addToSymbolTable(symbol: VariableSymbol(name: "$Static$this", variableStatus: .finishedInit, variableType: .staticVar))
        let previousClassStatus = currentClassStatus
        var currentClassType = ClassType.Class
        if stmt.superclass != nil {
            currentClassType = .Subclass
        } else {
            currentClassType = .Class
        }
        currentClassStatus = .init(classType: currentClassType, name: currentClassName, symbolTableIndex: stmt.symbolTableIndex!)
        
        defer {
            isInGlobalScope = previousIsInGlobalScope
            currentClassStatus = previousClassStatus
            symbolTable.gotoTable(previousSymbolTablePosition)
        }
        
        guard let classSymbol = symbolTable.getSymbol(id: stmt.symbolTableIndex!) as? ClassSymbol else {
            assertionFailure("Symbol at class statement is not a class symbol")
            return
        }
        
        for field in stmt.fields {
            if field.initializer != nil {
                catchErrorClosure {
                    try resolve(field.initializer!)
                }
            }
        }
        
        // set all the methods to available and all the fields to finishedInit
        for field in stmt.fields {
            if field.symbolTableIndex == nil {
                continue
            }
            let symbol = symbolTable.getSymbol(id: field.symbolTableIndex!) as! VariableSymbol
            symbol.variableStatus = .finishedInit
        }
        for method in stmt.methods {
            if method.function.symbolTableIndex == nil {
                continue
            }
            let symbol = symbolTable.getSymbol(id: method.function.symbolTableIndex!) as! MethodSymbol
            symbol.finishedInit = true
        }
        
        // resolve the methods now
        for method in stmt.methods {
            resolve(method)
        }
    }
    
    internal func visitMethodStmt(stmt: MethodStmt) {
        let previousFunctionStatus = currentFunction
        if stmt.function.name.lexeme == currentClassStatus?.name {
            currentFunction = .initializer
            if currentClassStatus?.classType == .Subclass {
                superInitCallIsFirstLineOfInitializer = true
            }
            if stmt.isStatic {
                error(message: "Constructor declaration cannot be marked 'static'", token: stmt.staticKeyword!)
            }
        } else {
            if stmt.isStatic {
                currentFunction = .staticMethod
            } else {
                currentFunction = .nonstaticMethod
            }
        }
        resolveFunction(stmt: stmt.function)
        currentFunction = previousFunctionStatus
    }
    
    private func resolveFunction(stmt: FunctionStmt) {
        let previousIsInGlobalScope = isInGlobalScope
        isInGlobalScope = false
        let previousSymbolTableIndex = symbolTable.getCurrentTableId()
        stmt.scopeIndex = symbolTable.createAndEnterScope()
        defer {
            symbolTable.gotoTable(previousSymbolTableIndex)
            isInGlobalScope = previousIsInGlobalScope
        }
        for i in 0..<stmt.params.count {
            stmt.params[i].symbolTableIndex = defineVariableWithInitializer(name: stmt.params[i].name, initializer: stmt.params[i].initializer)
        }
        for stmt in stmt.body {
            if superInitCallIsFirstLineOfInitializer == true {
                if !(stmt is ExpressionStmt) {
                    superInitCallIsFirstLineOfInitializer = false
                } else {
                    let expr = (stmt as! ExpressionStmt).expression
                    if !(expr is CallExpr) {
                        superInitCallIsFirstLineOfInitializer = false
                    } else {
                        let expr = expr as! CallExpr
                        if expr.property.lexeme != "super" {
                            superInitCallIsFirstLineOfInitializer = false
                        }
                    }
                }
            }
            resolve(stmt)
            if superInitCallIsFirstLineOfInitializer == true {
                superInitCallIsFirstLineOfInitializer = false
            }
        }
    }
    
    private func defineFunction(stmt: FunctionStmt) throws -> Int {
        try defineFunction(stmt: stmt, methodStmt: nil, withinClass: nil)
    }
    
    private func defineFunction(stmt: FunctionStmt, methodStmt: MethodStmt?, withinClass: Int?) throws -> Int {
        let functionSignature = createFunctionAstTypeSignature(functionStmt: stmt)
        if symbolTable.queryAtScopeOnly(functionSignature) != nil {
            throw error(message: "Invalid redeclaration of '\(stmt.name.lexeme)'", token: stmt.name)
        }
        var symbolTableIndex = -1
        if withinClass == nil {
            symbolTableIndex = symbolTable.addToSymbolTable(symbol: FunctionSymbol(name: functionSignature, functionStmt: stmt, returnType: QsVoidType()))
        } else {
            let classSymbol = symbolTable.getSymbol(id: withinClass!) as! ClassSymbol
            symbolTableIndex = symbolTable.addToSymbolTable(symbol: MethodSymbol(name: functionSignature, withinClass: withinClass!, overridedBy: [], methodStmt: methodStmt!, returnType: QsVoidType(), finishedInit: false, isConstructor: classSymbol.nonSignatureName == stmt.name.lexeme))
        }
        stmt.symbolTableIndex = symbolTableIndex
        let functionNameSymbolName = "#FuncName#"+stmt.name.lexeme
        if let existingNameSymbolInfo = symbolTable.queryAtScopeOnly(functionNameSymbolName) {
            guard let functionNameSymbolInfo = existingNameSymbolInfo as? FunctionNameSymbol else {
                throw error(message: "Invalid redeclaration of '\(stmt.name.lexeme)'", token: stmt.name)
            }
            stmt.nameSymbolTableIndex = functionNameSymbolInfo.id
            functionNameSymbolInfo.belongingFunctions.append(symbolTableIndex)
        } else {
            stmt.nameSymbolTableIndex = symbolTable.addToSymbolTable(symbol: FunctionNameSymbol(isForMethods: withinClass != nil, name: functionNameSymbolName, belongingFunctions: [symbolTableIndex]))
        }
        
        return symbolTableIndex
    }
    
    internal func visitFunctionStmt(stmt: FunctionStmt) {
        let previousFunction = currentFunction
        currentFunction = .function
        resolveFunction(stmt: stmt)
        currentFunction = previousFunction
    }
    
    internal func visitExpressionStmt(stmt: ExpressionStmt) {
        catchErrorClosure {
            try resolve(stmt.expression)
        }
    }
    
    internal func visitIfStmt(stmt: IfStmt) {
        catchErrorClosure {
            try resolve(stmt.condition)
        }
        
        resolve(stmt.thenBranch)
        
        resolve(stmt.elseIfBranches)
        
        if stmt.elseBranch != nil {
            resolve(stmt.elseBranch!)
        }
    }
    
    internal func visitOutputStmt(stmt: OutputStmt) {
        for expression in stmt.expressions {
            catchErrorClosure {
                try resolve(expression)
            }
        }
    }
    
    internal func visitInputStmt(stmt: InputStmt) {
        for expression in stmt.expressions {
            catchErrorClosure {
                try resolve(expression)
            }
        }
    }
    
    internal func visitReturnStmt(stmt: ReturnStmt) {
        if currentFunction == .none {
            if stmt.value != nil {
                error(message: "Can't return a value from top-level code.", token: stmt.keyword)
            }
            stmt.isTerminator = true
        }
        
        if stmt.value != nil {
            if currentFunction == .initializer {
                error(message: "Can't return a value from a constructor", token: stmt.keyword)
            }
            catchErrorClosure {
                try resolve(stmt.value!)
            }
        }
    }
    
    internal func visitLoopFromStmt(stmt: LoopFromStmt) {
        let previousLoopState = isInLoop
        catchErrorClosure {
            let existingSymbol = symbolTable.query(stmt.variable.name.lexeme)
            if existingSymbol is VariableSymbol {
                try resolve(stmt.variable)
            } else {
                stmt.variable.symbolTableIndex = symbolTable.addToSymbolTable(symbol: VariableSymbol(type: QsInt(), name: stmt.variable.name.lexeme, variableStatus: .finishedInit, variableType: .local))
                stmt.variable.type = QsInt(assignable: true)
            }
        }
        catchErrorClosure {
            try resolve(stmt.lRange)
        }
        catchErrorClosure {
            try resolve(stmt.rRange)
        }
        
        isInLoop = true
        defer {
            isInLoop = previousLoopState
        }
        resolve(stmt.body)
    }
    
    internal func visitWhileStmt(stmt: WhileStmt) {
        let previousLoopState = isInLoop
        
        catchErrorClosure {
            try resolve(stmt.expression)
        }
        
        isInLoop = true
        defer {
            isInLoop = previousLoopState
        }
        resolve(stmt.body)
    }
    
    internal func visitBreakStmt(stmt: BreakStmt) {
        if !isInLoop {
            error(message: "Can't use 'break' outside of loop", token: stmt.keyword)
        }
    }
    
    internal func visitContinueStmt(stmt: ContinueStmt) {
        if !isInLoop {
            error(message: "Can't use 'continue' outside of loop", token: stmt.keyword)
        }
    }
    
    internal func visitBlockStmt(stmt: BlockStmt) {
        let previousSymbolTableIndex = symbolTable.getCurrentTableId()
        stmt.scopeIndex = symbolTable.createAndEnterScope()
        let previousInGlobalScope = isInGlobalScope
        isInGlobalScope = false
        defer {
            isInGlobalScope = previousInGlobalScope
            symbolTable.gotoTable(previousSymbolTableIndex)
        }
        resolve(stmt.statements)
    }
    
    private func error(message: String, token: Token) -> ResolverError {
        problems.append(.init(message: message, token: token))
        return ResolverError.error(message)
    }
    private func error(message: String, start: InterpreterLocation, end: InterpreterLocation) -> ResolverError {
        problems.append(.init(message: message, start: start, end: end))
        return ResolverError.error(message)
    }
    
    private func resolve(_ expression: Expr) throws {
        try expression.accept(visitor: self)
    }
    
    private func resolve(_ statement: Stmt) {
        statement.accept(visitor: self)
    }
    
    private func resolve(_ statements: [Stmt]) {
        for statement in statements {
            resolve(statement)
        }
    }
    
    private func defineClass(stmt: ClassStmt, classId: Int) throws -> Int {
        let classSignature = generateClassSignature(className: stmt.name.lexeme, templateAstTypes: stmt.expandedTemplateParameters)
        if symbolTable.queryAtScopeOnly(classSignature) != nil {
            throw error(message: "Invalid redeclaration of '\(stmt.name.lexeme)'", token: stmt.name)
        }
        
        let classSymbol = ClassSymbol(name: classSignature, classId: classId, classStmt: stmt, upperClass: nil, depth: nil, parentOf: [])
        let symbolTableIndex = symbolTable.addToSymbolTable(symbol: classSymbol)
        stmt.symbolTableIndex = symbolTableIndex
        if let existingNameSymbolInfo = symbolTable.queryAtScopeOnly(stmt.name.lexeme) {
            if !(existingNameSymbolInfo is ClassNameSymbol) {
                error(message: "Invalid redeclaration of '\(stmt.name.lexeme)'", token: stmt.name)
            }
        } else {
            symbolTable.addToSymbolTable(symbol: ClassNameSymbol(name: stmt.name.lexeme))
        }
        
        let previousSymbolTableIndex = symbolTable.getCurrentTableId()
        stmt.scopeIndex = symbolTable.createAndEnterScope()
        classSymbol.classScopeSymbolTableIndex = stmt.scopeIndex!
        defer {
            symbolTable.gotoTable(previousSymbolTableIndex)
        }
        for method in stmt.methods {
            catchErrorClosure {
                try defineFunction(stmt: method.function, methodStmt: method, withinClass: classSymbol.id)
            }
        }
        
        func defineField(field: AstClassField) {
            if symbolTable.queryAtScopeOnly(field.name.lexeme) != nil {
                error(message: "Invalid redeclaration of \(field.name.lexeme)", token: field.name)
                return
            }
            let symbol = VariableSymbol(name: field.name.lexeme, variableStatus: .fieldIniting, variableType: (field.isStatic ? .staticVar : .instance))
            field.symbolTableIndex = symbolTable.addToSymbolTable(symbol: symbol)
        }
        for field in stmt.fields {
            defineField(field: field)
        }
        
        return symbolTableIndex
    }
    
    private func eagerDefineClassesAndFunctions(statements: [Stmt]) {
        // add all class and function names into the undefinables list
        var classIdCounter = BUILTIN_CLASSES_COUNT // leave class ids for the built-in classes
        for statement in statements {
            if let classStmt = statement as? ClassStmt {
                catchErrorClosure {
                    try defineClass(stmt: classStmt, classId: classIdCounter)
                }
                classIdCounter+=1
            }
            
            if let functionStmt = statement as? FunctionStmt {
                catchErrorClosure {
                    try defineFunction(stmt: functionStmt)
                }
            }
        }
    }
    
    private func initGlobal(index: Int) {
        let symbol = symbolTable.getSymbol(id: index) as! GlobalVariableSymbol
        symbol.variableStatus = .globalIniting
        catchErrorClosure {
            try resolve(symbol.globalDefiningAssignExpr.value)
        }
        symbol.variableStatus = .finishedInit
    }
    
    private func eagerDefineGlobalVariables(statements: [Stmt]) {
        // two passes. one finding all the global defining set expressions and another traversal
        var globalVariableIndexes: [Int] = []
        for statement in statements {
            guard let expressionStmt = statement as? ExpressionStmt else {
                continue
            }
            guard let assignExpr = expressionStmt.expression as? AssignExpr else {
                continue
            }
            
            if let existingSymbol = symbolTable.query(assignExpr.to.name.lexeme) {
                assignExpr.isFirstAssignment = false
                if !(existingSymbol is VariableSymbol) {
                    error(message: "Invalid redeclaration of \(existingSymbol.name)", token: assignExpr.to.name)
                    continue
                }
                assignExpr.to.symbolTableIndex = existingSymbol.id
            } else {
                assignExpr.isFirstAssignment = true
                assignExpr.to.symbolTableIndex = symbolTable.addToSymbolTable(symbol: GlobalVariableSymbol(name: assignExpr.to.name.lexeme, globalDefiningAssignExpr: assignExpr, variableStatus: .uninit))
                globalVariableIndexes.append(assignExpr.to.symbolTableIndex!)
            }
        }
        
        for globalVariableIndex in globalVariableIndexes {
            initGlobal(index: globalVariableIndex)
        }
    }
    
    private func buildClassHierarchy(statements: [Stmt]) {
        // first find all of the class statements
        var classStmts: [ClassStmt] = []
        for statement in statements {
            if let classStmt = statement as? ClassStmt {
                classStmts.append(classStmt)
            }
        }
        
        // find the maximum class id to create a union-find disjoint set in order to find circular references
        var classIdCount = BUILTIN_CLASSES_COUNT-1
        for classStmt in classStmts {
            if classStmt.symbolTableIndex == nil {
                continue
            }
            
            classIdCount = max(classIdCount, ((symbolTable.getSymbol(id: classStmt.symbolTableIndex!) as? ClassSymbol)?.classId) ?? 0)
        }
        
        let classClusterer = UnionFind(size: classIdCount+1+1)
        let anyTypeClusterId = classIdCount+1
        
        // create the class chains by initializing every class without a superclass with a depth of 1 and linking child classes classes with their superclasses
        for classStmt in classStmts {
            if classStmt.symbolTableIndex == nil {
                continue
            }
            guard let classSymbol = symbolTable.getSymbol(id: classStmt.symbolTableIndex!) as? ClassSymbol else {
                assertionFailure("Expected class symbol info in symbol table")
                continue
            }
            if classStmt.superclass == nil {
                classClusterer.unite(anyTypeClusterId, classSymbol.classId)
                classSymbol.depth = 1
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
            
            // check if the two classes are already related.
            if classClusterer.findParent(inheritedClassSymbol.classId) == classClusterer.findParent(classSymbol.classId) {
                error(message: "'\(classSymbol.displayName)' inherits from itself", token: classStmt.name)
                continue
            }
            inheritedClassSymbol.parentOf.append(classStmt.symbolTableIndex!)
            classClusterer.unite(inheritedClassSymbol.classId, classSymbol.classId)
            classSymbol.upperClass = inheritedClassSymbol.id
        }
        
        // fills the depth information in for the child classes
        func fillDepth(_ symbolTableId: Int, depth: Int) {
            let classSymbol = symbolTable.getSymbol(id: symbolTableId) as! ClassSymbol
            classSymbol.depth = depth
            for children in classSymbol.parentOf {
                fillDepth(children, depth: depth+1)
            }
        }
        var methodsChain: [[String : Int]] = []
        func findMethodInChain(signature: String) -> Int? {
            for i in 0..<methodsChain.count {
                let methodChain = methodsChain[methodsChain.count-i-1]
                if let resultingId = methodChain[signature] {
                    return resultingId
                }
            }
            return nil
        }
        func computeOverrideMethods(classId: Int) -> [String : [Int]] {
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
            var newMethodChain: [String : Int] = [:]
            var overrides: [String : [Int]] = [:]
            var currentClassSignatureToSymbolIdDict: [String : Int] = [:]
            
            func addOverride(methodSignature: String, functionId: Int) {
                if overrides[methodSignature] == nil {
                    overrides[methodSignature] = [functionId]
                    return
                }
                overrides[methodSignature]!.append(functionId)
            }
            func addOverride(methodSignature: String, functionIds: [Int]) {
                if overrides[methodSignature] == nil {
                    overrides[methodSignature] = functionIds
                    return
                }
                overrides[methodSignature]!.append(contentsOf: functionIds)
            }
            
            
            func handleMethod(_ methodSymbol: MethodSymbol) {
                let signature = methodSymbol.name
                let existingMethod = findMethodInChain(signature: signature)
                currentClassSignatureToSymbolIdDict[signature] = methodSymbol.belongsToTable
                if existingMethod == nil {
                    // record function into the chain
                    newMethodChain[methodSymbol.name] = methodSymbol.id
                } else {
                    // check consistency with the function currently in the chain
                    guard let existingMethodSymbolInfo = (symbolTable.getSymbol(id: existingMethod!) as? MethodSymbol) else {
                        return
                    }
                    // check static consistency
                    if methodSymbol.isStatic != existingMethodSymbolInfo.isStatic {
                        if methodSymbol.methodStmt == nil {
                            assertionFailure("An internal language error occurred")
                        } else {
                            error(message: "Static does not match for overriding method", token: (methodSymbol.isStatic ? methodSymbol.methodStmt!.staticKeyword! : methodSymbol.methodStmt!.function.name))
                        }
                    }
                    // check return type consistency
                    if !typesIsEqual(existingMethodSymbolInfo.returnType, methodSymbol.returnType) {
                        if methodSymbol.methodStmt == nil {
                            assertionFailure("An internal language error occurred")
                        } else {
                            let annotation = methodSymbol.methodStmt!.function.annotation
                            if annotation == nil {
                                error(message: "Return type does not match for overriding method", token: methodSymbol.methodStmt!.function.keyword)
                            } else {
                                error(message: "Return type does not match for overriding method", start: annotation!.startLocation, end: annotation!.endLocation)
                            }
                        }
                    }
                    
                    // log this override
                    addOverride(methodSignature: signature, functionId: methodSymbol.id)
                }
            }
            for method in classSymbol.getMethodSymbols(symbolTable: symbolTable) {
                handleMethod(method)
            }
            
            methodsChain.append(newMethodChain)
            
            for childClass in classSymbol.parentOf {
                let childClassOverrides = computeOverrideMethods(classId: childClass)
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
            guard let classSymbolTableId = classStmt.symbolTableIndex else {
                continue
            }
            let classSymbol = symbolTable.getSymbol(id: classSymbolTableId) as! ClassSymbol
            if classSymbol.depth == 1 {
                fillDepth(classSymbolTableId, depth: 1)
                computeOverrideMethods(classId: classSymbolTableId)
            }
        }
    }
    
    func resolveAST(statements: inout [Stmt], symbolTable: inout SymbolTables) -> [InterpreterProblem] {
        self.symbolTable = symbolTable
        
        isInGlobalScope = true
        isInLoop = false
        currentFunction = .none
        currentClassStatus = nil
        problems = []
        
        eagerDefineClassesAndFunctions(statements: statements)
        eagerDefineGlobalVariables(statements: statements)
        buildClassHierarchy(statements: statements)
        resolve(statements)
        
        symbolTable = self.symbolTable
        return problems
    }
}
