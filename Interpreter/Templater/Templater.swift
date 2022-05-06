class Templater: StmtVisitor, ExprVisitor, AstTypeAstTypeThrowVisitor {
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
    
    // TODO: Remember to expand our everything within a class too, like references within its fields and all of its methods.
    
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
        if belongingClassTemplateParameterCount == 0 {
            return asttype
        }
        let templateArguments = asttype.templateArguments!
        var computedTemplateArguments: [AstType] = []
        for templateArgument in templateArguments {
            computedTemplateArguments.append(try expandClasses(templateArgument))
        }
        
        // compute and expand the class
        let classToGenerateTemplate = TypedClassTemplate(name: asttype.name.lexeme, templateParameters: computedTemplateArguments)
        if !templatedClasses.contains(classToGenerateTemplate) {
            templatedClasses.insert(classToGenerateTemplate)
            if (DEBUG) {
                print("Generate class \(classToGenerateTemplate.name)<")
            }
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
    
    func visitClassStmt(stmt: ClassStmt) {
        
    }
    
    func visitMethodStmt(stmt: MethodStmt) {
        expandClasses(stmt.function)
    }
    
    func visitFunctionStmt(stmt: FunctionStmt) {
        
    }
    
    func visitExpressionStmt(stmt: ExpressionStmt) {
        
    }
    
    func visitIfStmt(stmt: IfStmt) {
        
    }
    
    func visitOutputStmt(stmt: OutputStmt) {
        
    }
    
    func visitInputStmt(stmt: InputStmt) {
        
    }
    
    func visitReturnStmt(stmt: ReturnStmt) {
        
    }
    
    func visitLoopFromStmt(stmt: LoopFromStmt) {
        
    }
    
    func visitWhileStmt(stmt: WhileStmt) {
        
    }
    
    func visitBreakStmt(stmt: BreakStmt) {
        
    }
    
    func visitContinueStmt(stmt: ContinueStmt) {
        
    }
    
    func visitGroupingExpr(expr: GroupingExpr) {
        
    }
    
    func visitLiteralExpr(expr: LiteralExpr) {
        
    }
    
    func visitArrayLiteralExpr(expr: ArrayLiteralExpr) {
        
    }
    
    func visitThisExpr(expr: ThisExpr) {
        
    }
    
    func visitSuperExpr(expr: SuperExpr) {
        
    }
    
    func visitVariableExpr(expr: VariableExpr) {
        
    }
    
    func visitSubscriptExpr(expr: SubscriptExpr) {
        
    }
    
    func visitCallExpr(expr: CallExpr) {
        
    }
    
    func visitGetExpr(expr: GetExpr) {
        
    }
    
    func visitUnaryExpr(expr: UnaryExpr) {
        
    }
    
    func visitCastExpr(expr: CastExpr) {
        
    }
    
    func visitArrayAllocationExpr(expr: ArrayAllocationExpr) {
        
    }
    
    func visitClassAllocationExpr(expr: ClassAllocationExpr) {
        
    }
    
    func visitBinaryExpr(expr: BinaryExpr) {
        
    }
    
    func visitLogicalExpr(expr: LogicalExpr) {
        
    }
    
    func visitSetExpr(expr: SetExpr) {
        
    }
    
    private func expandClasses(_ expression: Expr) {
        expression.accept(visitor: self)
    }
    
    private func expandClasses(_ statement: Stmt) {
        statement.accept(visitor: self)
    }
    
    private func expandClasses(_ statements: [Stmt]) {
        for statement in statements {
            statement.accept(visitor: self)
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
        
        
        
        return (self.statements, problems)
    }
    
    private func error(token: Token, message: String) -> TemplaterError {
        problems.append(.init(message: message, line: token.line, inlineLocation: .init(column: token.column, length: token.lexeme.count)))
        return TemplaterError.error(message)
    }
}
