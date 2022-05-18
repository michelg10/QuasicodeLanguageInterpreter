class Parser {
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
    private var isInGlobalScope: Bool = true
    private var classStmts: [ClassStmt] = []
    
    init(tokens: [Token]) {
        self.tokens = tokens
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
    
    func parse() -> ([Stmt], [ClassStmt], [InterpreterProblem]) {
        current = 0
        classNames = []
        parseUserDefinedTypes()
        current = 0
        var statements: [Stmt] = []
        isInGlobalScope = true
        classStmts = []
        while !isAtEnd() {
            if let newDeclaration = declaration() {
                statements.append(newDeclaration)
            }
        }
        
        return (statements, classStmts, problems)
    }
    
    private func declaration() -> Stmt? {
        do {
            if match(types: .EOL) {
                // its just an empty line, do nothing about it
                return nil
            }
            if match(types: .CLASS) {
                return try ClassDeclaration()
            }
            if match(types: .FUNCTION) {
                if !isInGlobalScope {
                    throw error(message: "Fucntion declaration must be in global scope or within a class", token: previous())
                }
                return try FunctionDeclaration()
            }
            return try statement()
        } catch {
            synchronize()
            return nil
        }
    }
    
    private func ClassDeclaration() throws -> Stmt {
        let keyword = previous()
        if !isInGlobalScope {
            throw error(message: "Class declaration must be global", token: keyword)
        }
        let name = try consume(type: .IDENTIFIER, message: "Expect class name.")
        currentClassName = name.lexeme
        var templateParameters: [Token]?
        var superclass: AstClassType? = nil
        
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
        
        if match(types: .EXTENDS) {
            let extendsKeyword = previous()
            let extendedClass = try typeSignature(matchArray: false)
            if extendedClass == nil {
                throw error(message: "Expect class name", token: extendsKeyword)
            }
            if !(extendedClass is AstClassType) {
                throw error(message: "Only classes can be extended!", token: previous())
            }
            superclass = extendedClass as? AstClassType
        }
        try consume(type: .EOL, message: "Expect end-of-line after class signature")
        
        var methods: [MethodStmt] = []
        var staticMethods: [MethodStmt] = []
        var fields: [ClassField] = []
        var staticFields: [ClassField] = []
        
        while !check(type: .END) && !isAtEnd() {
            var visibilityModifer: VisibilityModifier? = nil
            var isStatic: Bool? = nil
            
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
                let function = try FunctionDeclaration()
                let method = MethodStmt.init(isStatic: isStatic!, visibilityModifier: visibilityModifer!, function: function as! FunctionStmt)
                if isStatic! {
                    staticMethods.append(method)
                } else {
                    methods.append(method)
                }
            } else if match(types: .IDENTIFIER) {
                let fieldName = previous()
                var typeAnnotation: AstType? = nil
                var initializer: Expr? = nil
                if match(types: .COLON) {
                    typeAnnotation = try typeSignature(matchArray: true)
                }
                if match(types: .EQUAL) {
                    initializer = try expression()
                }
                let field = ClassField(isStatic: isStatic!, visibilityModifier: visibilityModifer!, name: fieldName, astType: typeAnnotation, initializer: initializer, type: nil, symbolTableIndex: nil)
                try consume(type: .EOL, message: "Expect end-of-line after field declaration")
                if isStatic! {
                    staticFields.append(field)
                } else {
                    fields.append(field)
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
        
        currentClassName = nil
        currentClassTemplateParameters = []
        let result = ClassStmt(keyword: keyword, name: name, symbolTableIndex: nil, thisSymbolTableIndex: nil, templateParameters: templateParameters, expandedTemplateParameters: nil, superclass: superclass, methods: methods, staticMethods: staticMethods, fields: fields, staticFields: staticFields)
        classStmts.append(result)
        return result
    }
    
    private func FunctionDeclaration() throws -> Stmt {
        let keyword = previous()
        let name = try consume(type: .IDENTIFIER, message: "Expect function name")
        try consume(type: .LEFT_PAREN, message: "Expect '(' after function declaration")
        var parameters: [FunctionParam] = []
        var functionType: AstType? = nil
        if !check(type: .RIGHT_PAREN) {
            repeat {
                let parameterName = try consume(type: .IDENTIFIER, message: "Expect parameter name")
                var parameterType: AstType? = nil
                var initializer: Expr? = nil
                if match(types: .COLON) {
                    parameterType = try typeSignature(matchArray: true)
                }
                if match(types: .EQUAL) {
                    initializer = try expression()
                }
                parameters.append(.init(name: parameterName, astType: parameterType, initializer: initializer, type: nil))
            } while match(types: .COMMA)
        }
        try consume(type: .RIGHT_PAREN, message: "Expect ')' after parameters")
        
        if match(types: .COLON) {
            functionType = try typeSignature(matchArray: true)
        }
        try consume(type: .EOL, message: "Expect end-of-line after function signature")
        
        let body = block(additionalEndMarkers: [])
        
        try consume(type: .END, message: "Expect 'end function' after function declaration")
        try consume(type: .FUNCTION, message: "Expect 'end function' after function declaration")
        try consume(type: .EOL, message: "Expect end-of-line after 'end function'")

        return FunctionStmt(keyword: keyword, name: name, symbolTableIndex: nil, nameSymbolTableIndex: nil, params: parameters, annotation: functionType, body: body)
    }
    
    private func statement() throws -> Stmt {
        if match(types: .IF) {
            return try IfStatement()
        }
        if match(types: .OUTPUT) {
            return try OutputStatement()
        }
        if match(types: .INPUT) {
            return try InputStatement()
        }
        if match(types: .RETURN) {
            return try ReturnStatement()
        }
        if match(types: .LOOP) {
            return try LoopStatement()
        }
        if match(types: .CONTINUE) {
            return ContinueStatement()
        }
        if match(types: .BREAK) {
            return BreakStatement()
        }
        
        return try expressionStatement()
    }
    
    private func BreakStatement() -> Stmt {
        let keyword = previous()
        return BreakStmt(keyword: keyword)
    }
    
    private func ContinueStatement() -> Stmt {
        let keyword = previous()
        return ContinueStmt(keyword: keyword)
    }
    
    private func whileLoop() throws -> Stmt {
        let whileOrUntil = previous()
        var condition = try expression()
        if whileOrUntil.tokenType == .UNTIL {
            let untilAsUnaryNotOpr = Token.init(tokenType: .NOT, lexeme: whileOrUntil.lexeme, start: .init(start: whileOrUntil), end: .init(end: whileOrUntil), value: whileOrUntil.value)
            condition = UnaryExpr(opr: untilAsUnaryNotOpr, right: condition, type: nil, startLocation: .init(start: whileOrUntil), endLocation: .init(end: whileOrUntil))
        }
        let statements = block(additionalEndMarkers: [])
        
        return WhileStmt(expression: condition, statements: statements)
    }
    
    private func loopFrom() throws -> Stmt {
        let iteratingVariable = try secondary()
        try consume(type: .FROM, message: "Expect 'from' after looping variable")
        let lRange = try expression()
        try consume(type: .TO, message: "Expect 'to' after lower looping range")
        let rRange = try expression()
        try consume(type: .EOL, message: "Expect end-of-line after upper looping range")
        
        let statements = block(additionalEndMarkers: [])
        
        return LoopFromStmt(variable: iteratingVariable, lRange: lRange, rRange: rRange, statements: statements)
    }
    
    private func LoopStatement() throws -> Stmt {
        var stmt: Stmt? = nil
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
    
    private func OutputStatement() throws -> Stmt {
        let expressions = try commaSeparatedExpressions()
        try consume(type: .EOL, message: "Expect end-of-line after output statement")
        return OutputStmt(expressions: expressions)
    }
    
    private func InputStatement() throws -> Stmt {
        let expressions = try commaSeparatedExpressions()
        try consume(type: .EOL, message: "Expect end-of-line after input statement")
        return InputStmt(expressions: expressions)
    }
    
    private func ReturnStatement() throws -> Stmt {
        let keyword = previous()
        var value: Expr? = nil
        
        if !check(type: .EOL) {
            value = try expression()
        }
        
        try consume(type: .EOL, message: "Expect end-of-line after return statement")
        return ReturnStmt(keyword: keyword, value: value)
    }
    
    private func commaSeparatedExpressions() throws -> [Expr] {
        var expressions: [Expr] = []
        repeat {
            expressions.append(try expression())
        } while match(types: .COMMA)
        return expressions
    }
    
    private func block(additionalEndMarkers: [TokenType]) -> [Stmt] {
        let previousIsInGlobalScope = isInGlobalScope
        isInGlobalScope = true
        var statements: [Stmt] = []
        while !check(types: additionalEndMarkers) && !check(type: .END) && !isAtEnd() {
            if let toInsert = declaration() {
                statements.append(toInsert)
            }
        }
        isInGlobalScope = previousIsInGlobalScope
        return statements
    }
    
    private func IfStatement() throws -> Stmt {
        let condition = try expression()
        try consume(type: .THEN, message: "Expect 'then' after if condition")
        try consume(type: .EOL, message: "Expect end-of-line after if condition")
        let thenBranch: [Stmt] = block(additionalEndMarkers: [.ELSE])
        var elseIfBranches: [IfStmt] = []
        var elseBranch: [Stmt]? = nil
        
        while match(types: .ELSE) {
            if match(types: .IF) {
                let condition = try expression()
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
    
    private func expressionStatement() throws -> Stmt {
        let expr = try expression()
        try consume(type: .EOL, message: "Expect end-of-line after expression")
        return ExpressionStmt(expression: expr)
    }
    
    private func expression() throws -> Expr {
        return try assign()
    }
    
    private func assign() throws -> Expr {
        var expr = try or()
        
        var annotation: AstType? = nil
        var annotationColon: Token? = nil
        if match(types: .COLON) {
            annotationColon = previous()
            annotation = try typeSignature(matchArray: true)
        }
        
        if match(types: .EQUAL) {
            let equals = previous()
            let value = try expression()
            
            return SetExpr(to: expr, annotationColon: annotationColon, annotation: annotation, value: value, isFirstAssignment: nil, type: nil, startLocation: expr.startLocation, endLocation: .init(end: previous()))
        } else {
            if annotation != nil {
                throw error(message: "Expect '=' after type annotation", token: peek())
            }
        }
        
        return expr
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
        var expr = try term()
        
        while match(types: .GREATER, .GREATER_EQUAL, .LESS, .LESS_EQUAL) {
            let opr = previous()
            let right = try term()
            expr = BinaryExpr(left: expr, opr: opr, right: right, type: nil, startLocation: expr.startLocation, endLocation: .init(end: previous()))
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
                expr = BinaryExpr(left: expr, opr: opr, right: right, type: nil, startLocation: expr.startLocation, endLocation: .init(end: previous()))
            }
        }
        
        return expr
    }
    
    private func allocation() throws -> Expr {
        let newKeyword = previous()
        // consume the base type
        let baseType = peek()
        var allocationType = try typeSignature(matchArray: false)
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
            return ArrayAllocationExpr(contains: allocationType!, capacity: capacity, type: nil, startLocation: .init(start: baseType), endLocation: .init(end: previous()))
        } else if match(types: .LEFT_PAREN) {
            let argumentsList = try arguments()
            if !(allocationType! is AstClassType) {
                throw error(message: "Expect class", token: baseType)
            }
            try consume(type: .RIGHT_PAREN, message: "Expect ')' after '('")
            return ClassAllocationExpr(classType: allocationType as! AstClassType, arguments: argumentsList, type: nil, startLocation: .init(start: baseType), endLocation: .init(end: previous()))
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
            let typeCastTo = try typeSignature(matchArray: true)
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
        if !check(type: .RIGHT_PAREN) {
            repeat {
                argumentsList.append(try expression())
            } while match(types: .COMMA)
        }
        return argumentsList
    }
    
    private func finishCall(callee: Expr) throws -> Expr {
        var argumentsList: [Expr] = try arguments()
        
        let paren = try consume(type: .RIGHT_PAREN, message: "Expect ')' after arguments.")
        return CallExpr(callee: callee, paren: paren, arguments: argumentsList, type: nil, startLocation: callee.startLocation, endLocation: .init(end: previous()))
    }
    
    private func secondary() throws -> Expr {
        var expr = try primary()
        
        while true {
            if match(types: .LEFT_PAREN) {
                expr = try finishCall(callee: expr)
            } else if match(types: .DOT) {
                let name = try consume(type: .IDENTIFIER, message: "Expect property name after '.'.")
                expr = GetExpr(object: expr, name: name, type: nil, startLocation: expr.startLocation, endLocation: .init(end: name))
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
            return LiteralExpr(value: true, type: QsBoolean(), startLocation: .init(start: previous()), endLocation: .init(end: previous()))
        }
        if match(types: .FALSE) {
            return LiteralExpr(value: false, type: QsBoolean(), startLocation: .init(start: previous()), endLocation: .init(end: previous()))
        }
        if match(types: .NULL) {
            return LiteralExpr(value: nil, type: QsAnyType(), startLocation: .init(start: previous()), endLocation: .init(end: previous()))
        }
        if match(types: .THIS) {
            return ThisExpr(keyword: previous(), symbolTableIndex: nil, type: nil, startLocation: .init(start: previous()), endLocation: .init(end: previous()))
        }
        if match(types: .INTEGER) {
            return LiteralExpr(value: previous().value, type: QsInt(), startLocation: .init(start: previous()), endLocation: .init(end: previous()))
        }
        if match(types: .FLOAT) {
            return LiteralExpr(value: previous().value, type: QsDouble(), startLocation: .init(start: previous()), endLocation: .init(end: previous()))
        }
        if match(types: .STRING) {
            // TODO: define the string class
            return LiteralExpr(value: previous().value, type: QsClass(name: "String", id: 0), startLocation: .init(start: previous()), endLocation: .init(end: previous()))
        }
        let statePrior = current
        if match(types: .IDENTIFIER) {
            if tokenToAstType(previous()) is AstClassType {
                current = statePrior
                let classSignature = try typeSignature(matchArray: false)
                try consume(type: .DOT, message: "Expected member name or constructor call after type name")
                let property = try consume(type: .IDENTIFIER, message: "Expect member name following '.'")
                return StaticClassExpr(classType: classSignature as! AstClassType, property: property, type: nil, startLocation: classSignature!.startLocation, endLocation: property.endLocation)
            }
            return VariableExpr(name: previous(), symbolTableIndex: nil, type: nil, startLocation: .init(start: previous()), endLocation: .init(end: previous()))
        }
        if match(types: .LEFT_BRACE) {
            return try arrayLiteral()
        }
        if match(types: .SUPER) {
            let keyword = previous()
            try consume(type: .DOT, message: "Expected '.' after 'super'.")
            let property = try consume(type: .IDENTIFIER, message: "Expect member name following '.'")
            return SuperExpr(keyword: keyword, property: property, symbolTableIndex: nil, type: nil, startLocation: .init(start: keyword), endLocation: .init(end: previous()))
        }
        if match(types: .LEFT_PAREN) {
            let leftParen = previous()
            let expr = try expression()
            try consume(type: .RIGHT_PAREN, message: "Expect ')' after expression.")
            return GroupingExpr(expression: expr, type: nil, startLocation: .init(start: leftParen), endLocation: .init(end: previous()))
        }
        
        throw error(message: "Expect expression", token: peek())
    }
    
    private func arrayLiteral() throws -> Expr {
        let leftBracket = previous()
        var values: [Expr] = []
        repeat {
            values.append(try expression())
        } while match(types: .COMMA)
        try consume(type: .RIGHT_BRACKET, message: "Expect ']' after '['")
        
        return ArrayLiteralExpr(values: values, type: nil, startLocation: .init(start: leftBracket), endLocation: .init(end: previous()))
    }
    
    private func typeSignature(matchArray: Bool) throws -> AstType? {
        guard var astType = tokenToAstType(peek()) else {
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
                guard let typeArgument = try typeSignature(matchArray: true) else {
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
        var astType: AstType? = nil
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
                astType = AstTemplateTypeName(belongingClass: currentClassName!, name: token, startLocation: .init(start: peek()), endLocation: .init(end: peek()))
            }
        default:
            astType = nil
        }
        
        return astType
    }
    
    // MARK: Utils
    private func match(types: TokenType...) -> Bool {
        for type in types {
            if check(type: type) {
                advance()
                return true
            }
        }
        
        return false
    }
    
    private func consume(type: TokenType, message: String) throws -> Token {
        if check(type: type) {
            return advance()
        }
        
        throw error(message: message, token: peek())
    }
    
    private func check(type: TokenType) -> Bool {
        if isAtEnd() {
            return false
        }
        return peek().tokenType == type
    }
    
    private func check(types: [TokenType]) -> Bool {
        for type in types {
            if check(type: type) {
                return true
            }
        }
        return false
    }
    
    private func advance() -> Token {
        if !isAtEnd() {
            current+=1
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
        return tokens[current+1]
    }
    
    private func previous() -> Token {
        return tokens[current-1]
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
            default:
                advance()
            }
        }
    }
}
