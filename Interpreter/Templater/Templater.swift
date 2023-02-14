class Templater: StmtStmtVisitor, ExprExprThrowVisitor, AstTypeAstTypeThrowVisitor {
    enum TemplaterError: Error {
        case error(String)
    }
    
    private struct ClassSignature: Hashable {
        var name: String
        var templateParameters: [AstType]
        
        static func == (lhs: Templater.ClassSignature, rhs: Templater.ClassSignature) -> Bool {
            if lhs.name != rhs.name {
                return false
            }
            
            if lhs.templateParameters.count != rhs.templateParameters.count {
                assertionFailure("Same class identifier but different template type count!")
                return false
            }
            
            for i in 0..<lhs.templateParameters.count {
                if !typesEqual(lhs.templateParameters[i], rhs.templateParameters[i]) {
                    return false
                }
            }
            
            return true
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(TypeHashValues.CLASS)
            hasher.combine(name)
            hasher.combine(templateParameters.count)
            
            for templateParameter in templateParameters {
                hashTypeIntoHasher(templateParameter, &hasher)
            }
        }
    }
    
    private var statements: [Stmt] = []
    private var problems: [InterpreterProblem] = []
    private var classes: [String : ClassStmt] = [:] // maps from class name to the class statement
    private var templatedClasses: Set<ClassSignature> = [] // keeps track of all the classes that have already been templated
    private var templateParameterMappings: [[String : AstType]] = [] // maps a template parameter to a concrete type
    
    private func expandFields(fields: [AstClassField]) -> [AstClassField] {
        var expandedFields: [AstClassField] = []
        expandedFields.reserveCapacity(fields.count)
        for field in fields {
            var newField = field
            if field.astType != nil {
                newField.astType = (catchErrorClosure {
                    try expandClasses(field.astType)
                } ?? field.astType)
            }
            
            if field.initializer != nil {
                newField.initializer = catchErrorClosure {
                    try expandClasses(field.initializer!)
                }
            }
            
            expandedFields.append(newField)
        }
        
        return expandedFields
    }
    
    private func expandMethods(methods: [MethodStmt]) -> [MethodStmt] {
        var expandedMethods: [MethodStmt] = []
        expandedMethods.reserveCapacity(methods.capacity)
        for method in methods {
            let newMethod = MethodStmt.init(method)
            newMethod.function = expandClasses(method.function) as! FunctionStmt
            expandedMethods.append(newMethod)
        }
        return expandedMethods
    }
    
    private func expandClass(classSignature: ClassSignature) {
        // append to template parameter mappings
        guard let belongingClass = classes[classSignature.name] else {
            assertionFailure("Expand class called on non-existing class \(classSignature.name).")
            return
        }
        
        let resultingClass = ClassStmt.init(belongingClass)
        resultingClass.expandedTemplateParameters = classSignature.templateParameters
        
        let classParameters = belongingClass.templateParameters?.map({ token in
            token.lexeme
        }) ?? []
        
        assert(classParameters.count == classSignature.templateParameters.count, "Mismatch between parameters given in signature and parameters required in class!")
        
        var newMapping: [String : AstType] = [:]
        for i in 0..<classParameters.count {
            newMapping[classParameters[i]] = classSignature.templateParameters[i]
        }
        templateParameterMappings.append(newMapping)
        
        resultingClass.fields = expandFields(fields: belongingClass.fields)
        
        resultingClass.methods = expandMethods(methods: belongingClass.methods)
        
        statements.append(resultingClass)
        
        templateParameterMappings.popLast()
    }
    
    func visitAstArrayTypeAstType(asttype: AstArrayType) throws -> AstType {
        return try AstArrayType(contains: expandClasses(asttype.contains), startLocation: asttype.startLocation, endLocation: asttype.endLocation)
    }
    
    func visitAstClassTypeAstType(asttype: AstClassType) throws -> AstType {
        guard let belongingClass = classes[asttype.name.lexeme] else {
//            assertionFailure("Class \(asttype.name.lexeme) does not exist in classes")
            return asttype
        }
        
        let belongingClassTemplateParameterCount = belongingClass.templateParameters?.count ?? 0
        let givenArguments = asttype.templateArguments?.count ?? 0
        
        let templateArguments = asttype.templateArguments ?? []
        var computedTemplateArguments: [AstType] = []
        if belongingClassTemplateParameterCount == 1 && givenArguments == 0 && builtinClassNames.contains(asttype.name.lexeme) {
            computedTemplateArguments = [AstAnyType(startLocation: .dub(), endLocation: .dub())]
        } else {
            if belongingClassTemplateParameterCount != givenArguments {
                throw error(message: "Expected \(belongingClassTemplateParameterCount) template parameters, got \(givenArguments)", start: asttype.startLocation, end: asttype.endLocation) // underline the entire ast class
            }
            
            for templateArgument in templateArguments {
                computedTemplateArguments.append(try expandClasses(templateArgument))
            }
        }
        
        // compute and expand the class
        if belongingClassTemplateParameterCount > 0 { // there's nothing to generate if there's no template parameters
            let classToGenerateSignature = ClassSignature(name: asttype.name.lexeme, templateParameters: computedTemplateArguments)
            if !templatedClasses.contains(classToGenerateSignature) {
                templatedClasses.insert(classToGenerateSignature)
                if (DEBUG) {
                    let astPrinter = AstPrinter()
                    let templateParametersDesc = classToGenerateSignature.templateParameters.reduce("") { partialResult, next in
                        var result = partialResult
                        if result != "" {
                            result += ", "
                        }
                        result += astPrinter.printAst(next)
                        return result
                    }
                    print("Generate class \(classToGenerateSignature.name)<\(templateParametersDesc)>")
                }
                
                // expand the class
                expandClass(classSignature: classToGenerateSignature)
            }
        }
        
        return AstClassType(name: asttype.name, templateArguments: computedTemplateArguments, startLocation: asttype.startLocation, endLocation: asttype.endLocation)
    }
    
    func visitAstTemplateTypeNameAstType(asttype: AstTemplateTypeName) -> AstType {
        if templateParameterMappings.count == 0 {
            assertionFailure("AST template mappings empty!")
            return asttype // just return something random
        }
        
        let currentMapping = templateParameterMappings.last!
        if let mappedType = currentMapping[asttype.name.lexeme] {
            return mappedType
        } else {
            assertionFailure("Template type \(asttype.name.lexeme) does not exist in mapping!")
        }
        return asttype
    }
    
    func visitAstIntTypeAstType(asttype: AstIntType) -> AstType {
        return asttype
    }
    
    func visitAstDoubleTypeAstType(asttype: AstDoubleType) -> AstType {
        return asttype
    }
    
    func visitAstBooleanTypeAstType(asttype: AstBooleanType) -> AstType {
        return asttype
    }
    
    func visitAstAnyTypeAstType(asttype: AstAnyType) -> AstType {
        return asttype
    }
    
    func visitClassStmtStmt(stmt: ClassStmt) -> Stmt {
        // do nothing
        return stmt
    }
    
    func visitMethodStmtStmt(stmt: MethodStmt) -> Stmt {
        let result = MethodStmt.init(stmt)
        result.function = expandClasses(stmt.function) as! FunctionStmt
        return result
    }
    
    func visitFunctionStmtStmt(stmt: FunctionStmt) -> Stmt {
        let result = FunctionStmt.init(stmt)
        if stmt.annotation != nil {
            result.annotation = catchErrorClosure {
                try expandClasses(stmt.annotation!)
            }
        }
        
        result.params = []
        result.params.reserveCapacity(stmt.params.count)
        
        for param in stmt.params {
            var newParam = AstFunctionParam(name: param.name, astType: nil)
            if param.astType != nil {
                newParam.astType = catchErrorClosure {
                    try expandClasses(param.astType!)
                }
            }
            if param.initializer != nil {
                newParam.initializer = catchErrorClosure {
                    try expandClasses(param.initializer!)
                }
            }
            result.params.append(newParam)
        }
        result.body = expandClasses(stmt.body)
        return result
    }
    
    func visitExpressionStmtStmt(stmt: ExpressionStmt) -> Stmt {
        let result = ExpressionStmt.init(stmt)
        result.expression = (catchErrorClosure {
            try expandClasses(stmt.expression)
        } ?? stmt.expression)
        
        return result
    }
    
    func visitIfStmtStmt(stmt: IfStmt) -> Stmt {
        let result = IfStmt.init(stmt)
        result.condition = (catchErrorClosure {
            try expandClasses(stmt.condition)
        } ?? stmt.condition)
        result.thenBranch = expandClasses(stmt.thenBranch) as! BlockStmt
        result.elseIfBranches = expandClasses(stmt.elseIfBranches) as! [IfStmt]
        if stmt.elseBranch != nil {
            result.elseBranch = (expandClasses(stmt.elseBranch!) as! BlockStmt)
        }
        return result
    }
    
    func visitOutputStmtStmt(stmt: OutputStmt) -> Stmt {
        let result = OutputStmt.init(stmt)
        result.expressions = expandClasses(stmt.expressions)
        return result
    }
    
    func visitInputStmtStmt(stmt: InputStmt) -> Stmt {
        let result = InputStmt.init(stmt)
        result.expressions = expandClasses(stmt.expressions)
        return result
    }
    
    func visitReturnStmtStmt(stmt: ReturnStmt) -> Stmt {
        let result = ReturnStmt.init(stmt)
        if stmt.value != nil {
            result.value = catchErrorClosure {
                try expandClasses(stmt.value!)
            }
        }
        return result
    }
    
    func visitLoopFromStmtStmt(stmt: LoopFromStmt) -> Stmt {
        let result = LoopFromStmt.init(stmt)
        result.variable = (catchErrorClosure {
            try expandClasses(stmt.variable) as! VariableExpr
        } ?? stmt.variable)
        result.lRange = (catchErrorClosure {
            try expandClasses(stmt.lRange)
        } ?? stmt.lRange)
        result.rRange = (catchErrorClosure {
            try expandClasses(stmt.rRange)
        } ?? stmt.rRange)
        
        result.body = expandClasses(stmt.body) as! BlockStmt
        
        return result
    }
    
    func visitWhileStmtStmt(stmt: WhileStmt) -> Stmt {
        let result = WhileStmt.init(stmt)
        result.expression = (catchErrorClosure {
            try expandClasses(stmt.expression)
        } ?? stmt.expression)
        result.body = expandClasses(stmt.body) as! BlockStmt
        return result
    }
    
    func visitBreakStmtStmt(stmt: BreakStmt) -> Stmt {
        return stmt
    }
    
    func visitContinueStmtStmt(stmt: ContinueStmt) -> Stmt {
        return stmt
    }
    
    func visitBlockStmtStmt(stmt: BlockStmt) -> Stmt {
        let result = BlockStmt.init(stmt)
        result.statements = expandClasses(result.statements)
        return result
    }
    
    func visitExitStmtStmt(stmt: ExitStmt) -> Stmt {
        return stmt
    }
    
    func visitGroupingExprExpr(expr: GroupingExpr) throws -> Expr {
        let result = GroupingExpr.init(expr)
        result.expression = try expandClasses(expr.expression)
        return result
    }
    
    func visitLiteralExprExpr(expr: LiteralExpr) -> Expr {
        return expr
    }
    
    func visitArrayLiteralExprExpr(expr: ArrayLiteralExpr) throws -> Expr {
        let result = ArrayLiteralExpr.init(expr)
        result.values = expandClasses(expr.values)
        return result
    }
    
    func visitStaticClassExprExpr(expr: StaticClassExpr) throws -> Expr {
        let result = StaticClassExpr.init(expr)
        result.classType = try expandClasses(expr.classType) as! AstClassType
        return result
    }
    
    func visitThisExprExpr(expr: ThisExpr) -> Expr {
        return expr
    }
    
    func visitSuperExprExpr(expr: SuperExpr) -> Expr {
        return expr
    }
    
    func visitVariableExprExpr(expr: VariableExpr) -> Expr {
        return expr
    }
    
    func visitSubscriptExprExpr(expr: SubscriptExpr) throws -> Expr {
        let result = SubscriptExpr.init(expr)
        result.expression = try expandClasses(expr.expression)
        result.index = try expandClasses(expr.index)
        return result
    }
    
    func visitCallExprExpr(expr: CallExpr) throws -> Expr {
        let result = CallExpr.init(expr)
        if expr.object != nil {
            expr.object = try expandClasses(expr.object!)
        }
        result.arguments = expandClasses(expr.arguments)
        return result
    }
    
    func visitGetExprExpr(expr: GetExpr) throws -> Expr {
        let result = GetExpr.init(expr)
        result.object = try expandClasses(expr.object)
        return result
    }
    
    func visitUnaryExprExpr(expr: UnaryExpr) throws -> Expr {
        let result = UnaryExpr.init(expr)
        result.right = try expandClasses(expr.right)
        return result
    }
    
    func visitCastExprExpr(expr: CastExpr) throws -> Expr {
        let result = CastExpr.init(expr)
        result.value = try expandClasses(expr.value)
        result.toType = try expandClasses(expr.toType)
        return result
    }
    
    func visitArrayAllocationExprExpr(expr: ArrayAllocationExpr) -> Expr {
        let result = ArrayAllocationExpr.init(expr)
        result.capacity = expandClasses(expr.capacity)
        result.contains = (catchErrorClosure {
            try expandClasses(expr.contains)
        } ?? expr.contains)
        return result
    }
    
    func visitClassAllocationExprExpr(expr: ClassAllocationExpr) -> Expr {
        let result = ClassAllocationExpr.init(expr)
        result.arguments = expandClasses(expr.arguments)
        result.classType = (catchErrorClosure {
            try expandClasses(expr.classType) as! AstClassType
        } ?? expr.classType)
        return result
    }
    
    func visitBinaryExprExpr(expr: BinaryExpr) -> Expr {
        let result = BinaryExpr(expr)
        result.left = (catchErrorClosure {
            try expandClasses(expr.left)
        } ?? expr.left)
        result.right = (catchErrorClosure {
            try expandClasses(expr.right)
        } ?? expr.right)
        return result
    }
    
    func visitLogicalExprExpr(expr: LogicalExpr) -> Expr {
        let result = LogicalExpr(expr)
        result.left = (catchErrorClosure {
            try expandClasses(expr.left)
        } ?? expr.left)
        result.right = (catchErrorClosure {
            try expandClasses(expr.right)
        } ?? expr.right)
        return result
    }
    
    func visitPropertySetExprExpr(expr: PropertySetExpr) throws -> Expr {
        let result = PropertySetExpr(expr)
        result.object = (catchErrorClosure {
            try expandClasses(expr.object)
        } ?? expr.object)
        result.value = (catchErrorClosure {
            try expandClasses(expr.value)
        } ?? expr.value)
        
        return result
    }
    
    func visitArraySetExprExpr(expr: SubscriptSetExpr) throws -> Expr {
        let result = SubscriptSetExpr(expr)
        result.expression = (catchErrorClosure {
            try expandClasses(expr.expression)
        } ?? expr.expression)
        result.index = (catchErrorClosure {
            try expandClasses(expr.index)
        } ?? expr.index)
        result.value = (catchErrorClosure {
            try expandClasses(expr.value)
        } ?? expr.value)
        
        return result
    }
    
    func visitAssignExprExpr(expr: AssignExpr) throws -> Expr {
        let result = AssignExpr.init(expr)
        result.to = (catchErrorClosure {
            try expandClasses(expr.to)
        } as? VariableExpr ?? expr.to)
        result.value = (catchErrorClosure {
            try expandClasses(expr.value)
        } ?? expr.value)
        if expr.annotation != nil {
            result.annotation = catchErrorClosure {
                try expandClasses(expr.annotation!)
            }
        }
        
        return result
    }
    
    func visitIsTypeExprExpr(expr: IsTypeExpr) throws -> Expr {
        let result = IsTypeExpr.init(expr)
        result.left = (catchErrorClosure({
            try expandClasses(result.left)
        }) ?? expr.left)
        result.right = (catchErrorClosure({
            expr.right
        }) ?? expr.right)
        
        return result
    }
    
    func visitImplicitCastExprExpr(expr: ImplicitCastExpr) throws -> Expr {
        assertionFailure("Unexpected implicit cast expr in Templater")
        return expr
    }
    
    private func expandClasses(_ expression: Expr) throws -> Expr {
        return try expression.accept(visitor: self)
    }
    
    private func expandClasses(_ statement: Stmt) -> Stmt {
        return statement.accept(visitor: self)
    }
    
    private func expandClasses(_ expressions: Expr...) -> [Expr] {
        return expandClasses(expressions)
    }
    
    private func expandClasses(_ statements: [Stmt]) -> [Stmt] {
        var expandedStatements: [Stmt] = []
        expandedStatements.reserveCapacity(statements.count)
        for statement in statements {
            expandedStatements.append(statement.accept(visitor: self))
        }
        return expandedStatements
    }
    
    private func expandClasses(_ expressions: [Expr]) -> [Expr] {
        var expandedExpressions: [Expr] = []
        expandedExpressions.reserveCapacity(expandedExpressions.count)
        for expression in expressions {
            let result = catchErrorClosure {
                try expression.accept(visitor: self)
            }
            if result != nil {
                expandedExpressions.append(result!)
            }
        }
        
        return expandedExpressions
    }
    
    private func expandClasses(_ astType: AstType) throws -> AstType {
        return try astType.accept(visitor: self)
    }
    
    private func gatherClasses(classStmts: [ClassStmt]) {
        // gathers classes and puts them into the classes array (only for global classes)
        for classStmt in classStmts {
            if classes[classStmt.name.lexeme] != nil {
                problems.append(.init(message: "Duplicate class name", token: classStmt.name))
                continue
            }
            
            classes[classStmt.name.lexeme] = classStmt
            
            if classStmt.templateParameters != nil {
                // now check if the template parameters clash
                var templateParameters = Set<String>()
                for templateParameter in classStmt.templateParameters! {
                    if templateParameters.contains(templateParameter.lexeme) {
                        problems.append(.init(message: "Duplicate template parameter identifier", token: templateParameter))
                    } else {
                        templateParameters.insert(templateParameter.lexeme)
                    }
                }
            }
        }
    }
    
    private func eraseClasses(_ statements: inout [Stmt]) {
        statements.removeAll { stmt in
            guard let stmt = stmt as? ClassStmt else {
                return false
            }
            if stmt.templateParameters != nil {
                if stmt.expandedTemplateParameters == nil {
                    return true
                }
            }
            return false
        }
    }
    
    func addEmptyInitializers(classStmts: [ClassStmt]) {
        for classStmt in classStmts {
            var canAddEmptyInitializer = true
            for field in classStmt.fields {
                if field.initializer == nil {
                    canAddEmptyInitializer = false
                    break
                }
            }
            if canAddEmptyInitializer {
                let newFunctionStmt = FunctionStmt(keyword: .dummyToken(tokenType: .FUNCTION, lexeme: "function"), name: classStmt.name, symbolTableIndex: nil, nameSymbolTableIndex: nil, scopeIndex: nil, params: [], annotation: nil, body: [], endOfFunction: .dummyToken(tokenType: .END, lexeme: "end"))
                let newMethodStmt = MethodStmt(isStatic: false, staticKeyword: nil, visibilityModifier: .PUBLIC, function: newFunctionStmt)
                classStmt.methods.append(newMethodStmt)
            }
        }
    }
    
    func expandClasses(statements: [Stmt]) -> ([Stmt], [InterpreterProblem]) {
        self.statements = statements
        problems = []
        classes = [:]
        var classStmts: [ClassStmt] = []
        for statement in statements {
            if statement is ClassStmt {
                classStmts.append(statement as! ClassStmt)
            }
        }
        addEmptyInitializers(classStmts: classStmts)
        gatherClasses(classStmts: classStmts)
        
        expandClasses(statements)
        
        eraseClasses(&self.statements)
        return (self.statements, problems)
    }
    
    private func error(message: String, token: Token) -> TemplaterError {
        problems.append(.init(message: message, token: token))
        return TemplaterError.error(message)
    }
    
    private func error(message: String, start: InterpreterLocation, end: InterpreterLocation) -> TemplaterError {
        problems.append(.init(message: message, start: start, end: end))
        return TemplaterError.error(message)
    }
}
