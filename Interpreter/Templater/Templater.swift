class Templater: StmtVisitor, ExprThrowVisitor, AstTypeAstTypeThrowVisitor {
    enum TemplaterError: Error {
        case error(String)
    }
    
    private struct TypedClassTemplate: Hashable {
        var name: String
        var templateParameters: [AstType]
        
        static func == (lhs: Templater.TypedClassTemplate, rhs: Templater.TypedClassTemplate) -> Bool {
            if lhs.name != rhs.name {
                return false
            }
            
            if lhs.templateParameters.count != rhs.templateParameters.count {
                assertionFailure("Same class identifier but different template type count!")
                return false
            }
            
            for i in 0..<lhs.templateParameters.count {
                if !typesIsEqual(lhs.templateParameters[i], rhs.templateParameters[i]) {
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
    private var templatedClasses: Set<TypedClassTemplate> = [] // keeps track of all the classes that have already been templated
    private var templateParameterMappings: [[String : AstType]] = [] // maps a template parameter to a concrete type
    
    func visitAstArrayTypeAstType(asttype: AstArrayType) throws -> AstType {
        return try AstArrayType(contains: expandClasses(asttype.contains))
    }
    
    func visitAstClassTypeAstType(asttype: AstClassType) throws -> AstType {
        guard let belongingClass = classes[asttype.name.lexeme] else {
            assertionFailure("Class \(asttype.name.lexeme) does not exist in classes")
            return asttype
        }
        let belongingClassTemplateParameterCount = belongingClass.templateParameters?.count ?? 0
        let givenArguments = asttype.templateArguments?.count ?? 0
        if belongingClassTemplateParameterCount != givenArguments {
            throw error(token: asttype.name, message: "Expected \(belongingClassTemplateParameterCount) template parameters, got \(givenArguments)")
        }
        
        let templateArguments = asttype.templateArguments ?? []
        var computedTemplateArguments: [AstType] = []
        for templateArgument in templateArguments {
            computedTemplateArguments.append(try expandClasses(templateArgument))
        }
        
        // compute and expand the class
        let classToGenerateTemplate = TypedClassTemplate(name: asttype.name.lexeme, templateParameters: computedTemplateArguments)
        if !templatedClasses.contains(classToGenerateTemplate) {
            templatedClasses.insert(classToGenerateTemplate)
            if (DEBUG) {
                let templateParametersDesc = classToGenerateTemplate.templateParameters.reduce("") { partialResult, next in
                    var result = partialResult
                    if result != "" {
                        result += ", "
                    }
                    result += astPrinter.printAst(next)
                    return result
                }
                print("Generate class \(classToGenerateTemplate.name)<\(templateParametersDesc)>")
            }
            
            // expand the class
            // TODO: Remember to expand our everything within a class too, like references within its fields and all of its methods.
            
            
        }
        
        return AstClassType(name: asttype.name, templateArguments: computedTemplateArguments)
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
        return AstIntType()
    }
    
    func visitAstDoubleTypeAstType(asttype: AstDoubleType) -> AstType {
        return AstDoubleType()
    }
    
    func visitAstBooleanTypeAstType(asttype: AstBooleanType) -> AstType {
        return AstBooleanType()
    }
    
    func visitAstAnyTypeAstType(asttype: AstAnyType) -> AstType {
        return AstBooleanType()
    }
    
    func catchErrorClosure<T>(_ closure: () throws -> T) -> T? {
        do {
            return try closure()
        } catch {
            
        }
        return nil
    }
    
    func visitClassStmt(stmt: ClassStmt) {
        // do nothing
        return
    }
    
    func visitMethodStmt(stmt: MethodStmt) {
        expandClasses(stmt.function)
    }
    
    func visitFunctionStmt(stmt: FunctionStmt) {
        if stmt.annotation != nil {
            catchErrorClosure {
                try expandClasses(stmt.annotation!)
            }
        }
        
        for param in stmt.params {
            if param.astType != nil {
                catchErrorClosure {
                    try expandClasses(param.astType!)
                }
            }
            if param.initializer != nil {
                catchErrorClosure {
                    try expandClasses(param.initializer!)
                }
            }
        }
        expandClasses(stmt.body)
    }
    
    func visitExpressionStmt(stmt: ExpressionStmt) {
        catchErrorClosure {
            try expandClasses(stmt.expression)
        }
    }
    
    func visitIfStmt(stmt: IfStmt) {
        catchErrorClosure {
            try expandClasses(stmt.condition)
        }
        expandClasses(stmt.thenBranch)
        expandClasses(stmt.elseIfBranches)
        if stmt.elseBranch != nil {
            expandClasses(stmt.elseBranch!)
        }
    }
    
    func visitOutputStmt(stmt: OutputStmt) {
        expandClasses(stmt.expressions)
    }
    
    func visitInputStmt(stmt: InputStmt) {
        expandClasses(stmt.expressions)
    }
    
    func visitReturnStmt(stmt: ReturnStmt) {
        if stmt.value != nil {
            catchErrorClosure {
                try expandClasses(stmt.value!)
            }
        }
    }
    
    func visitLoopFromStmt(stmt: LoopFromStmt) {
        expandClasses(stmt.variable, stmt.lRange, stmt.rRange)
        expandClasses(stmt.statements)
    }
    
    func visitWhileStmt(stmt: WhileStmt) {
        catchErrorClosure {
            try expandClasses(stmt.expression)
        }
        expandClasses(stmt.statements)
    }
    
    func visitBreakStmt(stmt: BreakStmt) {
        return
    }
    
    func visitContinueStmt(stmt: ContinueStmt) {
        return
    }
    
    func visitGroupingExpr(expr: GroupingExpr) throws {
        try expandClasses(expr.expression)
    }
    
    func visitLiteralExpr(expr: LiteralExpr) {
        return
    }
    
    func visitArrayLiteralExpr(expr: ArrayLiteralExpr) throws {
        expandClasses(expr.values)
    }
    
    func visitThisExpr(expr: ThisExpr) {
        return
    }
    
    func visitSuperExpr(expr: SuperExpr) {
        return
    }
    
    func visitVariableExpr(expr: VariableExpr) {
        return
    }
    
    func visitSubscriptExpr(expr: SubscriptExpr) throws {
        try expandClasses(expr.expression)
        try expandClasses(expr.index)
    }
    
    func visitCallExpr(expr: CallExpr) throws {
        try expandClasses(expr.callee)
        expandClasses(expr.arguments)
    }
    
    func visitGetExpr(expr: GetExpr) throws {
        try expandClasses(expr.object)
    }
    
    func visitUnaryExpr(expr: UnaryExpr) throws {
        try expandClasses(expr.right)
    }
    
    func visitCastExpr(expr: CastExpr) throws {
        try expandClasses(expr.value)
        try expandClasses(expr.toType)
    }
    
    func visitArrayAllocationExpr(expr: ArrayAllocationExpr) {
        expandClasses(expr.capacity)
        catchErrorClosure {
            try expandClasses(expr.contains)
        }
    }
    
    func visitClassAllocationExpr(expr: ClassAllocationExpr) {
        expandClasses(expr.arguments)
        catchErrorClosure {
            try expandClasses(expr.classType)
        }
    }
    
    func visitBinaryExpr(expr: BinaryExpr) {
        expandClasses(expr.left, expr.right)
    }
    
    func visitLogicalExpr(expr: LogicalExpr) {
        expandClasses(expr.left, expr.right)
    }
    
    func visitSetExpr(expr: SetExpr) {
        expandClasses(expr.to, expr.value)
        if expr.annotation != nil {
            catchErrorClosure {
                expr.annotation!
            }
        }
    }
    
    private func expandClasses(_ expression: Expr) throws {
        try expression.accept(visitor: self)
    }
    
    private func expandClasses(_ statement: Stmt) {
        statement.accept(visitor: self)
    }
    
    private func expandClasses(_ expressions: Expr...) {
        expandClasses(expressions)
    }
    
    private func expandClasses(_ statements: [Stmt]) {
        for statement in statements {
            statement.accept(visitor: self)
        }
    }
    
    private func expandClasses(_ expressions: [Expr]) {
        for expression in expressions {
            catchErrorClosure {
                try expression.accept(visitor: self)
            }
        }
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
    
    func expandClasses(statements: [Stmt], classStmts: [ClassStmt]) -> ([Stmt], [InterpreterProblem]) {
        self.statements = statements
        problems = []
        classes = [:]
        gatherClasses(classStmts: classStmts)
        
        expandClasses(statements)
        
        return (self.statements, problems)
    }
    
    private func error(token: Token, message: String) -> TemplaterError {
        problems.append(.init(message: message, line: token.line, inlineLocation: .init(column: token.column, length: token.lexeme.count)))
        return TemplaterError.error(message)
    }
}
