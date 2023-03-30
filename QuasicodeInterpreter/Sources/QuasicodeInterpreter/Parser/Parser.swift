// swiftlint:disable:next type_body_length
public class Parser {
    enum ParserError: Error {
        case error(String)
    }
    
    private let tokens: [Token]
    private var problems: [InterpreterProblem] = []
    private var current = 0
    private var currentClassTemplateParameters: [String] = []
    private var classNames: Set<String> = []
    private var functionNames: Set<String> = []
    private var currentClassName: String?
    private var isInGlobalScope = true
    private var stringClassIndex: Int
    private var builtinClasses: [String]
    
    public init(tokens: [Token], stringClassIndex: Int, builtinClasses: [String]) {
        self.tokens = tokens.filter { token in
            token.tokenType != .COMMENT
        }
        self.stringClassIndex = stringClassIndex
        self.builtinClasses = builtinClasses
    }
    
    private func parseUserDefinedTypes() {
        while !isAtEnd() {
            let currentToken = advance()
            if currentToken.tokenType == .CLASS {
                if !isAtEnd() {
                    if peek().tokenType == .IDENTIFIER {
                        classNames.insert(advance().lexeme)
                    }
                }
            }
            
            if currentToken.tokenType == .FUNCTION {
                if !isAtEnd() {
                    if peek().tokenType == .IDENTIFIER {
                        functionNames.insert(advance().lexeme)
                    }
                }
            }
        }
    }
    
    public func parse(addBuiltinclassesToAst: Bool, debugPrint: Bool = false) -> ([Stmt], [InterpreterProblem]) {
        if debugPrint {
            print("----- Parser -----")
        }
        current = 0
        classNames = Set(builtinClasses)
        parseUserDefinedTypes()
        current = 0
        var statements: [Stmt] = []
        
        if addBuiltinclassesToAst {
            statements = Builtins.addBuiltinClassesToAst(statements)
        }
        
        isInGlobalScope = true
        while !isAtEnd() {
            if let newDeclaration = declaration() {
                statements.append(newDeclaration)
            }
        }
        
        if debugPrint {
            print("Parsed AST")
            print(astPrinterSingleton.printAst(statements, printWithTypes: false))
            print("\nErrors", problems)
        }
        
        return (statements, problems)
    }
    
    private func declaration() -> Stmt? {
        do {
            if match(types: .EOL) {
                // its just an empty line, do nothing about it
                return nil
            }
            if match(types: .CLASS) {
                return try classDeclaration()
            }
            if match(types: .FUNCTION) {
                if !isInGlobalScope {
                    throw error(message: "Fucntion declaration must be in global scope or within a class", token: previous())
                }
                return try functionDeclaration()
            }
            return try statement()
        } catch {
            synchronize()
            return nil
        }
    }
    
    private func classDeclaration() throws -> Stmt {
        let keyword = previous()
        if !isInGlobalScope {
            throw error(message: "Class declaration must be global", token: keyword)
        }
        let name = try consume(type: .IDENTIFIER, message: "Expect class name.")
        
        currentClassName = name.lexeme
        currentClassTemplateParameters = []
        defer {
            currentClassName = nil
            currentClassTemplateParameters = []
        }
        
        var templateParameters: [Token]?
        var superclass: AstClassType?
        
        // MARK: Template parameters
        if match(types: .LESS) {
            templateParameters = []
            repeat {
                templateParameters?.append(try consume(type: .IDENTIFIER, message: "Expect template parameter"))
            } while match(types: .COMMA)
            try consume(type: .GREATER, message: "Expect '>' following template parameters")
            for templateParameter in templateParameters! {
                currentClassTemplateParameters.append(templateParameter.lexeme)
            }
        }
        
        // MARK: Inheritance
        if match(types: .EXTENDS) {
            let extendsKeyword = previous()
            let extendedClass = try typeSignature(matchArray: false, optional: false)
            if extendedClass == nil {
                throw error(message: "Expect class name", token: extendsKeyword)
            }
            if !(extendedClass is AstClassType) {
                throw error(message: "Only classes can be extended!", token: previous())
            }
            superclass = extendedClass as? AstClassType
        }
        try consume(type: .EOL, message: "Expect end-of-line after class signature")
        
        // MARK: The class's fields and methods
        
        var methods: [MethodStmt] = []
        var fields: [AstClassField] = []
        var staticKeyword: Token?
        
        while !checkTokenType(is: .END) && !isAtEnd() {
            var visibilityModifer: VisibilityModifier?
            var isStatic: Bool?
            
            while match(types: .PUBLIC, .PRIVATE, .STATIC) {
                switch previous().tokenType {
                case .PUBLIC:
                    if visibilityModifer != nil {
                        throw error(message: "Repeated visibility modifier", token: previous())
                    }
                    visibilityModifer = .PUBLIC
                case .PRIVATE:
                    if visibilityModifer != nil {
                        throw error(message: "Repeated visibility modifier", token: previous())
                    }
                    visibilityModifer = .PRIVATE
                case .STATIC:
                    if isStatic != nil {
                        throw error(message: "Repeated static modifier", token: previous())
                    }
                    staticKeyword = previous()
                    isStatic = true
                default:
                    continue
                }
            }
            
            if isStatic == nil {
                isStatic = false
            }
            if visibilityModifer == nil {
                visibilityModifer = .PUBLIC
            }
            
            if match(types: .FUNCTION) {
                let function = try functionDeclaration()
                let method: MethodStmt = .init(
                    isStatic: isStatic!,
                    staticKeyword: staticKeyword,
                    visibilityModifier: visibilityModifer!,
                    function: function as! FunctionStmt
                )
                methods.append(method)
            } else if match(types: .IDENTIFIER) {
                let fieldName = previous()
                var initializer: Expr?
                do {
                    try consume(type: .COLON, message: "Expect type annotation for field declaration")
                    guard let typeAnnotation = try typeSignature(matchArray: true, optional: false) else {
                        throw ParserError.error("Expected non-nil")
                    }
                    if match(types: .EQUAL) {
                        initializer = try expression()
                    }
                    if isStatic! && initializer == nil {
                        error(message: "Static field requires an initial value", token: fieldName)
                    }
                    let field = AstClassField(
                        isStatic: isStatic!,
                        visibilityModifier: visibilityModifer!,
                        name: fieldName,
                        astType: typeAnnotation,
                        initializer: initializer,
                        symbolTableIndex: nil
                    )
                    try consume(type: .EOL, message: "Expect end-of-line after field declaration")
                    fields.append(field)
                } catch {
                    synchronize()
                }
            } else if match(types: .EOL) {
                // ignore
            } else {
                throw error(message: "Expect method or field declaration", token: peek())
            }
        }
        
        try consume(type: .END, message: "Expect 'end class' after class declaration")
        try consume(type: .CLASS, message: "Expect 'end class' after class declaration")
        try consume(type: .EOL, message: "Expect end-of-line after 'end class'")
        
        let result = ClassStmt(
            keyword: keyword,
            name: name,
            builtin: false,
            symbolTableIndex: nil,
            instanceThisSymbolTableIndex: nil,
            staticThisSymbolTableIndex: nil,
            scopeIndex: nil,
            templateParameters: templateParameters,
            expandedTemplateParameters: nil,
            superclass: superclass,
            methods: methods,
            fields: fields
        )
        return result
    }
    
    private func functionDeclaration() throws -> Stmt {
        // MARK: Function signature
        let keyword = previous()
        let name = try consume(type: .IDENTIFIER, message: "Expect function name")
        try consume(type: .LEFT_PAREN, message: "Expect '(' after function declaration")
        var parameters: [AstFunctionParam] = []
        var functionType: AstType?
        if !checkTokenType(is: .RIGHT_PAREN) {
            repeat {
                let parameterName = try consume(type: .IDENTIFIER, message: "Expect parameter name")
                var parameterType: AstType? = AstAnyType(startLocation: .init(end: previous()), endLocation: .init(end: previous()))
                var initializer: Expr?
                if match(types: .COLON) {
                    parameterType = try typeSignature(matchArray: true, optional: false)
                }
                if match(types: .EQUAL) {
                    initializer = try expression()
                }
                parameters.append(.init(name: parameterName, astType: parameterType, initializer: initializer))
            } while match(types: .COMMA)
        }
        try consume(type: .RIGHT_PAREN, message: "Expect ')' after parameters")
        
        // MARK: Function return type
        if match(types: .COLON) {
            functionType = try typeSignature(matchArray: true, optional: false)
        }
        try consume(type: .EOL, message: "Expect end-of-line after function signature")
        
        // MARK: Function body
        let body = block(additionalEndMarkers: [])
        
        let endOfFunction = try consume(type: .END, message: "Expect 'end function' after function declaration")
        try consume(type: .FUNCTION, message: "Expect 'end function' after function declaration")
        try consume(type: .EOL, message: "Expect end-of-line after 'end function'")

        return FunctionStmt(
            keyword: keyword,
            name: name,
            symbolTableIndex: nil,
            nameSymbolTableIndex: nil,
            scopeIndex: nil,
            params: parameters,
            annotation: functionType,
            body: body.statements,
            endOfFunction: endOfFunction
        )
    }
    
    private func statement() throws -> Stmt {
        if match(types: .IF) {
            return try ifStatement()
        }
        if match(types: .OUTPUT) {
            return try outputStatement()
        }
        if match(types: .INPUT) {
            return try inputStatement()
        }
        if match(types: .RETURN) {
            return try returnStatement()
        }
        if match(types: .LOOP) {
            return try loopStatement()
        }
        if match(types: .CONTINUE) {
            return continueStatement()
        }
        if match(types: .BREAK) {
            return breakStatement()
        }
        if match(types: .EXIT) {
            return exitStatement()
        }
        
        return try expressionOrSetStatement()
    }
    
    private func ifStatement() throws -> Stmt {
        let condition = try expression()
        try consume(type: .THEN, message: "Expect 'then' after if condition")
        try consume(type: .EOL, message: "Expect end-of-line after if condition")
        let thenBranch: BlockStmt = block(additionalEndMarkers: [.ELSE])
        var elseIfBranches: [IfStmt] = []
        var elseBranch: BlockStmt?
        
        while match(types: .ELSE) {
            if match(types: .IF) {
                let condition = try expression()
                try consume(type: .THEN, message: "Expect 'then' after if condition")
                try consume(type: .EOL, message: "Expect end-of-line after if condition")
                let thisElseIfBranch = block(additionalEndMarkers: [.ELSE])
                elseIfBranches.append(.init(condition: condition, thenBranch: thisElseIfBranch, elseIfBranches: [], elseBranch: nil))
            } else {
                try consume(type: .EOL, message: "Expect end-of-line after else")
                elseBranch = block(additionalEndMarkers: [.ELSE])
                break
            }
        }
        
        try consume(type: .END, message: "Expect 'end if' after if statement")
        try consume(type: .IF, message: "Expect 'end if' after if statement")
        try consume(type: .EOL, message: "Expect end-of-line after 'end if'")
        
        return IfStmt(condition: condition, thenBranch: thenBranch, elseIfBranches: elseIfBranches, elseBranch: elseBranch)
    }
    
    private func outputStatement() throws -> Stmt {
        var expressions: [Expr] = []
        repeat {
            expressions.append(try expression())
        } while match(types: .COMMA)
        try consume(type: .EOL, message: "Expect end-of-line after output statement")
        return OutputStmt(expressions: expressions)
    }
    
    private func inputStatement() throws -> Stmt {
        var expressions: [Expr] = []
        repeat {
            expressions.append(try writableExpression())
        } while match(types: .COMMA)
        try consume(type: .EOL, message: "Expect end-of-line after input statement")
        return InputStmt(expressions: expressions)
    }
    
    private func returnStatement() throws -> Stmt {
        let keyword = previous()
        var value: Expr?
        
        if !checkTokenType(is: .EOL) {
            value = try expression()
        }
        
        try consume(type: .EOL, message: "Expect end-of-line after return statement")
        return ReturnStmt(keyword: keyword, value: value, isTerminator: false)
    }
    
    private func loopStatement() throws -> Stmt {
        var stmt: Stmt?
        if match(types: .WHILE, .UNTIL) {
            stmt = try whileLoop()
        } else {
            stmt = try loopFrom()
        }
        
        try consume(type: .END, message: "Expect 'end loop' after loop statement")
        try consume(type: .LOOP, message: "Expect 'end loop' after loop statement")
        try consume(type: .EOL, message: "Expect end-of-line after 'end loop'")
        
        return stmt!
    }
    
    private func loopFrom() throws -> Stmt {
        let iteratingVariableIdentifier = try consume(type: .IDENTIFIER, message: "Expect looping variable")
        
        // check if the identifier of the looping variable is a class type
        if tokenToAstType(previous()) is AstClassType {
            error(message: "Expect looping variable", token: previous())
        }
        let iteratingVariable = VariableExpr(
            name: iteratingVariableIdentifier,
            symbolTableIndex: nil,
            type: nil,
            startLocation: .init(start: previous()),
            endLocation: .init(end: previous())
        )
        
        try consume(type: .FROM, message: "Expect 'from' after looping variable")
        
        let lRange = try expression()
        try consume(type: .TO, message: "Expect 'to' after lower looping range")
        
        let rRange = try expression()
        try consume(type: .EOL, message: "Expect end-of-line after upper looping range")
        
        let body = block(additionalEndMarkers: [])
        
        return LoopFromStmt(variable: iteratingVariable, lRange: lRange, rRange: rRange, body: body)
    }
    
    private func whileLoop() throws -> Stmt {
        let whileOrUntil = previous()
        var condition = try expression()
        if whileOrUntil.tokenType == .UNTIL {
            // desugar the "do until" statement into a "do while not" statement
            let untilAsUnaryNotOpr: Token = .init(
                tokenType: .NOT,
                lexeme: whileOrUntil.lexeme,
                start: .init(start: whileOrUntil),
                end: .init(end: whileOrUntil),
                value: whileOrUntil.value
            )
            condition = UnaryExpr(
                opr: untilAsUnaryNotOpr,
                right: condition,
                type: nil,
                startLocation: .init(start: whileOrUntil),
                endLocation: .init(end: whileOrUntil)
            )
        }
        let body = block(additionalEndMarkers: [])
        
        return WhileStmt(expression: condition, isDesugaredUntil: whileOrUntil.tokenType == .UNTIL, body: body)
    }
    
    private func continueStatement() -> Stmt {
        let keyword = previous()
        return ContinueStmt(keyword: keyword)
    }
    
    private func breakStatement() -> Stmt {
        let keyword = previous()
        return BreakStmt(keyword: keyword)
    }
    
    private func exitStatement() -> Stmt {
        let keyword = previous()
        return ExitStmt(keyword: keyword)
    }
    
    private func expressionOrSetStatement() throws -> Stmt {
        let expr = try expression()
        if match(types: .EOL) {
            return ExpressionStmt(expression: expr)
        } else if checkTokenType(isAnyOf: [.COLON, .EQUAL]) {
            // it's a assignment statement
            return try multiSetStatement(continueWithLeft: expr)
        }
        try consume(type: .EOL, message: "Expect end-of-line after expression")
        return ExpressionStmt(expression: expr)
    }
    
    private func multiSetStatement(continueWithLeft: Expr?) throws -> Stmt {
        let singleStmt = try setStatement(continueWithLeft: continueWithLeft)
        if match(types: .COMMA) {
            var setStmts: [SetStmt] = [singleStmt]
            repeat {
                setStmts.append(try setStatement(continueWithLeft: nil))
            } while (match(types: .COMMA))
            return MultiSetStmt(setStmts: setStmts)
        } else {
            return singleStmt
        }
    }
    
    private func setStatement(continueWithLeft: Expr?) throws -> SetStmt {
        var leftExpr: Expr
        if continueWithLeft != nil {
            leftExpr = continueWithLeft!
        } else {
            leftExpr = try writableExpression()
        }
        
        var annotation: AstType?
        var annotationColon: Token?
        if match(types: .COLON) {
            annotationColon = previous()
            annotation = try typeSignature(matchArray: true, optional: false)
        }
        
        try consume(type: .EQUAL, message: "Expect '='")
        var chains: [Expr] = []
        var value: Expr?
        while true {
            let nextExpr = try expression()
            if value == nil {
                value = nextExpr
            } else {
                chains.append(value!)
                value = nextExpr
            }
            
            if !match(types: .EQUAL) {
                // convert a VariableExpr to a VariableToSetExpr if it is on the lhs of a set statement
                if leftExpr is VariableExpr {
                    var endLocation = leftExpr.endLocation
                    if annotationColon != nil {
                        endLocation = annotationColon!.endLocation
                    }
                    if annotation != nil {
                        endLocation = annotation!.endLocation
                    }
                    leftExpr = VariableToSetExpr(
                        to: leftExpr as! VariableExpr,
                        annotationColon: annotationColon,
                        annotation: annotation,
                        isFirstAssignment: nil,
                        type: nil,
                        startLocation: leftExpr.startLocation,
                        endLocation: endLocation
                    )
                } else {
                    if annotation != nil || annotationColon != nil {
                        error(message: "Cannot retype expression", token: annotationColon!)
                    }
                }
                return SetStmt(left: leftExpr, chained: chains, value: value!)
            }
        }
    }
    
    private func block(additionalEndMarkers: [TokenType]) -> BlockStmt {
        let previousIsInGlobalScope = isInGlobalScope
        isInGlobalScope = true
        var statements: [Stmt] = []
        while !checkTokenType(isAnyOf: additionalEndMarkers) && !checkTokenType(is: .END) && !isAtEnd() {
            if let toInsert = declaration() {
                statements.append(toInsert)
            }
        }
        isInGlobalScope = previousIsInGlobalScope
        return .init(statements: statements, scopeIndex: nil)
    }
    
    private func expression() throws -> Expr {
        try or()
    }
    
    private func writableExpression() throws -> Expr {
        // This does not guarantee a writable expression.
        // However, using this when the syntax demands a writable expression should make parsing faster and have the parser spit out better errors
        // since any operator above secondary is read-only,
        // simply limiting writable expressions to secondary() eliminates many
        // redundant calls.
        try secondary()
    }
    
    private func or() throws -> Expr {
        var expr = try and()
        
        while match(types: .OR) {
            let opr = previous()
            let right = try and()
            expr = LogicalExpr(left: expr, opr: opr, right: right, type: nil, startLocation: expr.startLocation, endLocation: .init(end: previous()))
        }
        
        return expr
    }
    
    private func and() throws -> Expr {
        var expr = try equality()
        
        while match(types: .AND) {
            let opr = previous()
            let right = try equality()
            expr = LogicalExpr(left: expr, opr: opr, right: right, type: nil, startLocation: expr.startLocation, endLocation: .init(end: previous()))
        }
        
        return expr
    }
    
    private func equality() throws -> Expr {
        var expr = try comparison()
        
        while match(types: .EQUAL_EQUAL, .BANG_EQUAL) {
            let opr = previous()
            let right = try comparison()
            expr = BinaryExpr(left: expr, opr: opr, right: right, type: nil, startLocation: expr.startLocation, endLocation: .init(end: previous()))
        }
        
        return expr
    }
    
    private func comparison() throws -> Expr {
        var expr = try isType()
        
        while match(types: .GREATER, .GREATER_EQUAL, .LESS, .LESS_EQUAL) {
            let opr = previous()
            let right = try isType()
            expr = BinaryExpr(left: expr, opr: opr, right: right, type: nil, startLocation: expr.startLocation, endLocation: .init(end: previous()))
        }
        
        return expr
    }
    
    private func isType() throws -> Expr {
        var expr = try term()
        if match(types: .IS) {
            let keyword = previous()
            let type = try typeSignature(matchArray: true, optional: false)
            expr = IsTypeExpr(
                left: expr,
                keyword: keyword,
                right: type!,
                rightType: nil,
                type: nil,
                startLocation: expr.startLocation,
                endLocation: type!.endLocation
            )
        }
        return expr
    }
    
    private func term() throws -> Expr {
        var expr = try factor()
        
        while match(types: .MINUS, .PLUS) {
            let opr = previous()
            let right = try factor()
            expr = BinaryExpr(left: expr, opr: opr, right: right, type: nil, startLocation: expr.startLocation, endLocation: .init(end: previous()))
        }
        
        return expr
    }
    
    private func factor() throws -> Expr {
        var expr: Expr
        if match(types: .NEW) {
            expr = try allocation()
        } else {
            expr = try unary()
            while match(types: .SLASH, .STAR, .DIV, .MOD) {
                let opr = previous()
                let right = try unary()
                expr = BinaryExpr(
                    left: expr,
                    opr: opr,
                    right: right,
                    type: nil,
                    startLocation: expr.startLocation,
                    endLocation: .init(end: previous())
                )
            }
        }
        
        return expr
    }
    
    private func allocation() throws -> Expr {
        let newKeyword = previous()
        // consume the base type
        let baseType = peek()
        var allocationType = try typeSignature(matchArray: false, optional: false)
        if allocationType == nil {
            throw error(message: "Expect type after 'new'", token: newKeyword)
        }
        
        if match(types: .LEFT_BRACKET) {
            var capacity: [Expr] = []
            repeat {
                capacity.append(try expression())
                allocationType = AstArrayType(contains: allocationType!, startLocation: .init(start: baseType), endLocation: .init(end: peek()))
                try consume(type: .RIGHT_BRACKET, message: "Expect ']' after '['")
            } while match(types: .LEFT_BRACKET)
            return ArrayAllocationExpr(
                contains: allocationType!,
                capacity: capacity,
                type: nil,
                startLocation: .init(start: newKeyword),
                endLocation: .init(end: previous())
            )
        } else if match(types: .LEFT_PAREN) {
            let argumentsList = try arguments()
            if !(allocationType! is AstClassType) {
                throw error(message: "Expect class", token: baseType)
            }
            try consume(type: .RIGHT_PAREN, message: "Expect ')' after '('")
            return ClassAllocationExpr(
                classType: allocationType as! AstClassType,
                arguments: argumentsList,
                callsFunction: nil,
                type: nil,
                startLocation: .init(start: newKeyword),
                endLocation: .init(end: previous())
            )
        }
        
        throw error(message: "Expect expression", token: previous())
    }
    
    private func unary() throws -> Expr {
        let statePrior = current
        if match(types: .LEFT_PAREN) {
            let leftParen = previous()
            if isAtEnd() {
                throw error(message: "Expect ')' after '('", token: previous())
            }
            // determine if its a type cast
            let typeCastTo = try typeSignature(matchArray: true, optional: true)
            if typeCastTo != nil {
                try consume(type: .RIGHT_PAREN, message: "Expect ')' after '('")
                let right = try unary()
                return CastExpr(toType: typeCastTo!, value: right, type: nil, startLocation: .init(start: leftParen), endLocation: right.endLocation)
            } else {
                // restore state
                current = statePrior
            }
        }
        if match(types: .MINUS, .NOT) {
            let opr = previous()
            let right = try unary()
            return UnaryExpr(opr: opr, right: right, type: nil, startLocation: .init(start: opr), endLocation: right.endLocation)
        }
        
        return try secondary()
    }
    
    private func arguments() throws -> [Expr] {
        var argumentsList: [Expr] = []
        if !checkTokenType(is: .RIGHT_PAREN) {
            repeat {
                argumentsList.append(try expression())
            } while match(types: .COMMA)
        }
        return argumentsList
    }
    
    private func finishCall(callee: Expr) throws -> Expr {
        let argumentsList: [Expr] = try arguments()
        
        let paren = try consume(type: .RIGHT_PAREN, message: "Expect ')' after arguments.")
        var object: Expr?
        var property: Token?
        if callee is VariableExpr {
            object = nil
            property = (callee as! VariableExpr).name
        } else if callee is GetExpr {
            object = (callee as! GetExpr).object
            property = (callee as! GetExpr).property
        } else if callee is SuperExpr {
            object = VariableExpr(
                name: (callee as! SuperExpr).keyword,
                symbolTableIndex: nil,
                type: nil,
                startLocation: (callee as! SuperExpr).keyword.startLocation,
                endLocation: (callee as! SuperExpr).keyword.endLocation
            )
            property = (callee as! SuperExpr).property
        }
        return CallExpr(
            object: object,
            property: property!,
            paren: paren,
            arguments: argumentsList,
            uniqueFunctionCall: nil,
            polymorphicCallClassIdToIdDict: nil,
            type: nil,
            startLocation: callee.startLocation,
            endLocation: .init(end: previous())
        )
    }
    
    private func secondary() throws -> Expr {
        var expr = try primary()
        
        while true {
            if match(types: .LEFT_PAREN) {
                if expr is GetExpr || expr is VariableExpr || expr is SuperExpr {
                    expr = try finishCall(callee: expr)
                }
            } else if match(types: .DOT) {
                let name = try consume(type: .IDENTIFIER, message: "Expect property name after '.'.")
                expr = GetExpr(
                    object: expr,
                    property: name,
                    propertyId: nil,
                    type: nil,
                    startLocation: expr.startLocation,
                    endLocation: .init(end: name)
                )
            } else if match(types: .LEFT_BRACKET) {
                let index = try expression()
                expr = SubscriptExpr(expression: expr, index: index, type: nil, startLocation: expr.startLocation, endLocation: index.endLocation)
                try consume(type: .RIGHT_BRACKET, message: "Expect ']' after '['")
            } else {
                break
            }
        }
        
        return expr
    }
    
    private func primary() throws -> Expr {
        if match(types: .TRUE) {
            return LiteralExpr(
                value: true,
                type: QsBoolean(assignable: false),
                startLocation: .init(start: previous()),
                endLocation: .init(end: previous())
            )
        }
        
        if match(types: .FALSE) {
            return LiteralExpr(
                value: false,
                type: QsBoolean(assignable: false),
                startLocation: .init(start: previous()),
                endLocation: .init(end: previous())
            )
        }
        
        if match(types: .THIS) {
            return ThisExpr(
                keyword: previous(),
                symbolTableIndex: nil,
                type: nil,
                startLocation: .init(start: previous()),
                endLocation: .init(end: previous())
            )
        }
        
        if match(types: .INTEGER) {
            return LiteralExpr(
                value: previous().value,
                type: QsInt(assignable: false),
                startLocation: .init(start: previous()),
                endLocation: .init(end: previous())
            )
        }
        
        if match(types: .FLOAT) {
            return LiteralExpr(
                value: previous().value,
                type: QsDouble(assignable: false),
                startLocation: .init(start: previous()),
                endLocation: .init(end: previous())
            )
        }
        
        if match(types: .STRING) {
            return LiteralExpr(
                value: previous().value,
                type: QsClass(name: "String", id: stringClassIndex, assignable: false),
                startLocation: .init(start: previous()),
                endLocation: .init(end: previous())
            )
        }
        
        let statePrior = current
        if match(types: .IDENTIFIER) {
            if tokenToAstType(previous()) is AstClassType {
                // it's a static get expression. Though this is a get expression and should be in the secondary() function,
                // I put it here because a static get expression is the only possible thing to follow a class identifier as a primary() element
                // (its only other possible use is with the "is" operator.
                current = statePrior
                let classSignature = try typeSignature(matchArray: false, optional: false)
                
                let staticClassExpr = StaticClassExpr(
                    classType: classSignature as! AstClassType,
                    classId: nil,
                    type: nil,
                    startLocation: classSignature!.startLocation,
                    endLocation: classSignature!.endLocation
                )
                
                try consume(type: .DOT, message: "Expected member name or constructor call after type name")
                let property = try consume(type: .IDENTIFIER, message: "Expect member name following '.'")
                return GetExpr(
                    object: staticClassExpr,
                    property: property,
                    propertyId: nil,
                    type: nil,
                    startLocation: staticClassExpr.startLocation,
                    endLocation: property.endLocation
                )
            }
            
            return VariableExpr(
                name: previous(),
                symbolTableIndex: nil,
                type: nil,
                startLocation: .init(start: previous()),
                endLocation: .init(end: previous())
            )
        }
        
        if match(types: .LEFT_BRACE) {
            return try arrayLiteral()
        }
        
        if match(types: .SUPER) {
            let keyword = previous()
            if match(types: .DOT) {
                let property = try consume(type: .IDENTIFIER, message: "Expect member name following '.'")
                return SuperExpr(
                    keyword: keyword,
                    property: property,
                    superClassId: nil,
                    propertyId: nil,
                    type: nil,
                    startLocation: .init(start: keyword),
                    endLocation: .init(end: previous())
                )
            } else if match(types: .LEFT_PAREN) {
                return try finishCall(
                    callee: VariableExpr(
                        name: keyword,
                        symbolTableIndex: nil,
                        type: nil,
                        startLocation: keyword.startLocation,
                        endLocation: keyword.endLocation
                    )
                )
            } else {
                throw error(message: "Expect property name or call after 'super'.", token: peek())
            }
        }
        
        if match(types: .LEFT_PAREN) {
            let leftParen = previous()
            let expr = try expression()
            try consume(type: .RIGHT_PAREN, message: "Expect ')' after expression.")
            if expr is VariableExpr {
                return expr
            }
            return GroupingExpr(expression: expr, type: nil, startLocation: .init(start: leftParen), endLocation: .init(end: previous()))
        }
        
        throw error(message: "Expect expression", token: peek())
    }
    
    private func arrayLiteral() throws -> Expr {
        let leftBrace = previous()
        var values: [Expr] = []
        if !match(types: .RIGHT_BRACE) {
            repeat {
                values.append(try expression())
            } while match(types: .COMMA)
            try consume(type: .RIGHT_BRACE, message: "Expect '}' after '{'")
        }
        
        return ArrayLiteralExpr(values: values, type: nil, startLocation: .init(start: leftBrace), endLocation: .init(end: previous()))
    }
    
    private func typeSignature(matchArray: Bool, optional: Bool) throws -> AstType? {
        guard var astType = tokenToAstType(peek()) else {
            if !optional {
                throw error(message: "Expect type", token: peek())
            }
            return nil
        }
        advance()
        if match(types: .LESS) {
            if !(astType is AstClassType) {
                throw error(message: "Non-classes cannot be templated", token: peek())
            }
            var templateArguments: [AstType] = []
            repeat {
                let nextToken = peek()
                guard let typeArgument = try typeSignature(matchArray: true, optional: true) else {
                    throw error(message: "Expect type", token: nextToken)
                }
                templateArguments.append(typeArgument)
            } while match(types: .COMMA)
            (astType as! AstClassType).templateArguments = templateArguments
            try consume(type: .GREATER, message: "Expect '>' after template")
            astType.endLocation = .init(end: previous())
        }
        
        if matchArray {
            while match(types: .LEFT_BRACKET) {
                try consume(type: .RIGHT_BRACKET, message: "Expect ']' after '['")
                astType = AstArrayType(contains: astType, startLocation: astType.startLocation, endLocation: .init(end: previous()))
            }
        }
        
        return astType
    }
    
    private func tokenToAstType(_ token: Token) -> AstType? {
        // in case of a class, the template field is left blank.
        var astType: AstType?
        switch token.tokenType {
        case .INT:
            astType = AstIntType(startLocation: .init(start: peek()), endLocation: .init(end: peek()))
        case .DOUBLE:
            astType = AstDoubleType(startLocation: .init(start: peek()), endLocation: .init(end: peek()))
        case .BOOLEAN:
            astType = AstBooleanType(startLocation: .init(start: peek()), endLocation: .init(end: peek()))
        case .ANY:
            astType = AstAnyType(startLocation: .init(start: peek()), endLocation: .init(end: peek()))
        case .IDENTIFIER:
            if classNames.contains(token.lexeme) {
                astType = AstClassType(name: token, templateArguments: nil, startLocation: .init(start: peek()), endLocation: .init(end: peek()))
            } else if currentClassTemplateParameters.contains(token.lexeme) {
                assert(currentClassName != nil, "Template should not exist when class name is nil!")
                astType = AstTemplateTypeName(
                    belongingClass: currentClassName!,
                    name: token,
                    startLocation: .init(start: peek()),
                    endLocation: .init(end: peek())
                )
            }
        default:
            astType = nil
        }
        
        return astType
    }
    
    // MARK: Utils
    private func match(types: TokenType...) -> Bool {
        if types.contains(peek().tokenType) {
            advance()
            return true
        }
        
        return false
    }
    
    private func consume(type: TokenType, message: String) throws -> Token {
        if checkTokenType(is: type) {
            return advance()
        }
        
        throw error(message: message, token: peek())
    }
    
    private func checkTokenType(is type: TokenType) -> Bool {
        if isAtEnd() {
            return false
        }
        return peek().tokenType == type
    }
    
    private func checkTokenType(isAnyOf types: [TokenType]) -> Bool {
        if types.contains(peek().tokenType) {
            return true
        }
        return false
    }
    
    private func advance() -> Token {
        if !isAtEnd() {
            current += 1
        }
        return previous()
    }
    
    private func isAtEnd() -> Bool {
        return peek().tokenType == .EOF
    }
    
    private func peek() -> Token {
        return tokens[current]
    }
    
    private func peekNext() -> Token? {
        if isAtEnd() {
            return nil
        }
        return tokens[current + 1]
    }
    
    private func previous() -> Token {
        return tokens[current - 1]
    }
    
    private func error(message: String, token: Token) -> ParserError {
        problems.append(.init(message: message, token: token))
        return ParserError.error(message)
    }
    
    private func synchronize() {
        advance()
        
        while !isAtEnd() {
            if previous().tokenType == .EOL {
                return // synchronize on line boundaries
            }
            
            switch peek().tokenType {
            case .IF:
                return
            case .OUTPUT:
                return
            case .INPUT:
                return
            case .RETURN:
                return
            case .LOOP:
                return
            case .CONTINUE:
                return
            case .BREAK:
                return
            case .EXIT:
                return
            default:
                advance()
            }
        }
    }
}
