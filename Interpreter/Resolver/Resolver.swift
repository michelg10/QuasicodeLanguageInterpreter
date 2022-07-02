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
        if currentClassStatus == nil {
            throw error(message: "Can't use 'this' outside of a class", token: expr.keyword)
        }
        if currentFunction != .nonstaticMethod && currentFunction != .staticMethod {
            throw error(message: "Can't use 'this' outside of a method", token: expr.keyword)
        }
        if currentFunction != .nonstaticMethod {
            throw error(message: "Can't use 'this' in a static context", token: expr.keyword)
        }
        expr.symbolTableIndex = symbolTable.query("this")?.id
        assert(expr.symbolTableIndex != nil, "'this' is undefined")
    }
    
    internal func visitSuperExpr(expr: SuperExpr) throws {
        if currentClassStatus?.classType != .Subclass {
            throw error(message: "Can't use 'super' outside of a subclass", token: expr.keyword)
        }
    }
    
    internal func visitVariableExpr(expr: VariableExpr) {
        if let existingSymbol = symbolTable.query(expr.name.lexeme) {
            if let symbol = existingSymbol as? VariableSymbol {
                // uninit -> is a global, init it
                // initing -> use of variable within its own declaration
                // globalIniting -> global circular reference
                // finishedInit -> no problem
                if symbol.isInstanceVariable && currentFunction == .staticMethod {
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
            try resolve(expr.object!)
        }
        if expr.property.lexeme == "super" {
            if currentFunction != .initializer {
                error(message: "'super' cannot be called outside of an initializer", token: expr.property)
            } else {
                if superInitCallIsFirstLineOfInitializer == true {
                    superInitCallIsFirstLineOfInitializer = false
                } else {
                    error(message: "Call to 'super' must be first statement in constructor", token: expr.property)
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
                
                let associatedSymbol = VariableSymbol(name: expr.to.name.lexeme, variableStatus: .initing, isInstanceVariable: false)
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
        // use this with class fields, function parameters, etc.
        if symbolTable.queryAtScopeOnly(name.lexeme) != nil {
            error(message: "Invalid redeclaration of \(name.lexeme)", token: name)
            return nil
        }
        let symbol = VariableSymbol(name: name.lexeme, variableStatus: .initing, isInstanceVariable: false)
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
        let previousIsInGlobalScope = isInGlobalScope
        isInGlobalScope = false
        let currentClassName = stmt.name.lexeme
        
        symbolTable.gotoTable(stmt.scopeIndex!)
    linkSymbolTableToSuperclass: if stmt.superclass != nil {
            let superclassSignature = generateClassSignature(className: stmt.superclass!.name.lexeme, templateAstTypes: stmt.superclass!.templateArguments)
            let superclassSymbol = symbolTable.queryAtGlobalOnly(superclassSignature)
            guard let superclassSymbol = superclassSymbol as? ClassSymbol else {
                break linkSymbolTableToSuperclass
            }
            if superclassSymbol.classStmt.scopeIndex != nil {
                symbolTable.linkCurrentTableToParent(superclassSymbol.classStmt.scopeIndex!)
            }
        }
        stmt.thisSymbolTableIndex = symbolTable.addToSymbolTable(symbol: VariableSymbol(name: "this", variableStatus: .finishedInit, isInstanceVariable: false))
        let previousClassStatus = currentClassStatus
        var currentClassType = ClassType.Class
        if stmt.superclass != nil {
            currentClassType = .Subclass
        } else {
            currentClassType = .Class
        }
        currentClassStatus = .init(classType: currentClassType, name: currentClassName)
        
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
        for field in stmt.staticFields {
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
        for field in stmt.staticFields {
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
        for method in stmt.staticMethods {
            if method.function.symbolTableIndex == nil {
                continue
            }
            let symbol = symbolTable.getSymbol(id: method.function.symbolTableIndex!) as! MethodSymbol
            symbol.finishedInit = true
        }
        
        // resolve the methods now
        for method in stmt.staticMethods {
            resolve(method)
        }
        for method in stmt.methods {
            resolve(method)
        }
        symbolTable.exitScope()
        currentClassStatus = previousClassStatus
        isInGlobalScope = previousIsInGlobalScope
    }
    
    internal func visitMethodStmt(stmt: MethodStmt) {
        let previousFunctionStatus = currentFunction
        if stmt.function.name.lexeme == currentClassStatus?.name {
            currentFunction = .initializer
            if currentClassStatus?.classType == .Subclass {
                superInitCallIsFirstLineOfInitializer = true
            }
            if stmt.isStatic {
                error(message: "Initializer declaration cannot be marked 'static'", token: stmt.staticKeyword!)
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
        stmt.scopeIndex = symbolTable.createAndEnterScope()
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
        symbolTable.exitScope()
        isInGlobalScope = previousIsInGlobalScope
    }
    
    private func defineFunction(stmt: FunctionStmt) throws -> Int {
        try defineFunction(stmt: stmt, methodStmt: nil, withinClass: nil)
    }
    
    private func defineFunction(stmt: FunctionStmt, methodStmt: MethodStmt?, withinClass: Int?) throws -> Int {
        var paramsName = ""
        for param in stmt.params {
            if paramsName != "" {
                paramsName = paramsName+", "
            }
            paramsName+=astTypeToStringSingleton.stringify(param.astType ?? AstAnyType(startLocation: .dub(), endLocation: .dub()))
        }
        let functionSignature = "\(stmt.name.lexeme)(\(paramsName))"
        if symbolTable.queryAtScopeOnly(functionSignature) != nil {
            throw error(message: "Invalid redeclaration of '\(stmt.name.lexeme)'", token: stmt.name)
        }
        var symbolTableIndex = -1
        if withinClass == nil {
            symbolTableIndex = symbolTable.addToSymbolTable(symbol: FunctionSymbol(name: functionSignature, functionStmt: stmt, returnType: QsAnyType(assignable: false)))
        } else {
            symbolTableIndex = symbolTable.addToSymbolTable(symbol: MethodSymbol(name: functionSignature, withinClass: withinClass!, overridedBy: [], methodStmt: methodStmt!, returnType: QsAnyType(assignable: false), finishedInit: false))
        }
        stmt.symbolTableIndex = symbolTableIndex
        let functionNameSymbolName = "$FuncName$"+stmt.name.lexeme
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
                error(message: "Can't return a value from an initializer", token: stmt.keyword)
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
                stmt.variable.symbolTableIndex = symbolTable.addToSymbolTable(symbol: VariableSymbol(type: QsInt(), name: stmt.variable.name.lexeme, variableStatus: .finishedInit, isInstanceVariable: false))
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
        resolve(stmt.body)
        
        isInLoop = previousLoopState
    }
    
    internal func visitWhileStmt(stmt: WhileStmt) {
        let previousLoopState = isInLoop
        
        catchErrorClosure {
            try resolve(stmt.expression)
        }
        
        isInLoop = true
        resolve(stmt.body)
        
        isInLoop = previousLoopState
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
        stmt.scopeIndex = symbolTable.createAndEnterScope()
        let previousInGlobalScope = isInGlobalScope
        isInGlobalScope = false
        resolve(stmt.statements)
        isInGlobalScope = previousInGlobalScope
        symbolTable.exitScope()
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
        
        let classSymbol = ClassSymbol(name: classSignature, classId: classId, classChain: nil, classStmt: stmt)
        let symbolTableIndex = symbolTable.addToSymbolTable(symbol: classSymbol)
        stmt.symbolTableIndex = symbolTableIndex
        if let existingNameSymbolInfo = symbolTable.queryAtScopeOnly(stmt.name.lexeme) {
            if !(existingNameSymbolInfo is ClassNameSymbol) {
                error(message: "Invalid redeclaration of '\(stmt.name.lexeme)'", token: stmt.name)
            }
        } else {
            symbolTable.addToSymbolTable(symbol: ClassNameSymbol(name: stmt.name.lexeme))
        }
        
        stmt.scopeIndex = symbolTable.createAndEnterScope()
        for method in stmt.methods {
            catchErrorClosure {
                try defineFunction(stmt: method.function, methodStmt: method, withinClass: classSymbol.id)
            }
        }
        for method in stmt.staticMethods {
            catchErrorClosure {
                try defineFunction(stmt: method.function, methodStmt: method, withinClass: classSymbol.id)
            }
        }
        
        func defineField(field: ClassField) {
            if symbolTable.queryAtScopeOnly(field.name.lexeme) != nil {
                error(message: "Invalid redeclaration of \(field.name.lexeme)", token: field.name)
                return
            }
            let symbol = VariableSymbol(name: field.name.lexeme, variableStatus: .fieldIniting, isInstanceVariable: !field.isStatic)
            field.symbolTableIndex = symbolTable.addToSymbolTable(symbol: symbol)
        }
        for field in stmt.fields {
            defineField(field: field)
        }
        for field in stmt.staticFields {
            defineField(field: field)
        }
        symbolTable.exitScope()
        
        return symbolTableIndex
    }
    
    private func eagerDefineClassesAndFunctions(statements: [Stmt]) {
        // add all class and function names into the undefinables list
        var classIdCounter = 0
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
        var classIdCount = 0
        for classStmt in classStmts {
            if classStmt.symbolTableIndex == nil {
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
        
        // create the class chains by initializing every class without a superclass with a depth of 1 and linking child classes classes with their superclasses
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
        
        // fills the depth information in for the child classes
        func fillDepth(_ symbolTableId: Int, depth: Int) {
            guard let classChain = symbolTable.getClassChain(id: symbolTableId) else {
                return
            }
            classChain.depth = depth
            for children in classChain.parentOf {
                fillDepth(children, depth: depth+1)
            }
        }
        var methodsChain: [[MethodAstTypeSignature : Int]] = []
        func findMethodInChain(signature: MethodAstTypeSignature) -> Int? {
            for i in 0..<methodsChain.count {
                let methodChain = methodsChain[methodsChain.count-i-1]
                if let resultingId = methodChain[signature] {
                    return resultingId
                }
            }
            return nil
        }
        func computeOverrideMethods(classId: Int) -> [MethodAstTypeSignature : [Int]] {
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
            var newMethodChain: [MethodAstTypeSignature : Int] = [:]
            var overrides: [MethodAstTypeSignature : [Int]] = [:]
            var currentClassSignatureToSymbolIdDict: [MethodAstTypeSignature : Int] = [:]
            
            func addOverride(methodSignature: MethodAstTypeSignature, functionId: Int) {
                if overrides[methodSignature] == nil {
                    overrides[methodSignature] = [functionId]
                    return
                }
                overrides[methodSignature]!.append(functionId)
            }
            func addOverride(methodSignature: MethodAstTypeSignature, functionIds: [Int]) {
                if overrides[methodSignature] == nil {
                    overrides[methodSignature] = functionIds
                    return
                }
                overrides[methodSignature]!.append(contentsOf: functionIds)
            }
            
            
            func handleMethod(_ method: MethodStmt) {
                if method.function.symbolTableIndex == nil || method.function.nameSymbolTableIndex == nil {
                    // an error probably occured, dont process it
                    return
                }
                let signature = MethodAstTypeSignature.init(functionStmt: method.function)
                let existingMethod = findMethodInChain(signature: signature)
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
            guard let classId = classStmt.symbolTableIndex else {
                continue
            }
            guard let classChain = symbolTable.getClassChain(id: classId) else {
                continue
            }
            if classChain.depth == 1 {
                fillDepth(classId, depth: 1)
                computeOverrideMethods(classId: classId)
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
