enum ParserError: Error {
    case error(String)
}

class Parser {
    private let tokens: [Token]
    private var problems: [InterpreterProblem] = []
    private var current = 0
    private var userDefinedTypes: Set<String> = []
    
    init(tokens: [Token]) {
        self.tokens = tokens
    }
    
    private func parseUserDefinedTypes() {
        while !isAtEnd() {
            let currentToken = advance()
            if currentToken.tokenType == .CLASS {
                if !isAtEnd() {
                    if peek().tokenType == .IDENTIFIER {
                        userDefinedTypes.insert(advance().lexeme)
                    }
                }
            }
        }
    }
    
    func parse() -> ([Stmt], [InterpreterProblem]) {
        current = 0
        userDefinedTypes = []
        parseUserDefinedTypes()
        current = 0
        var statements: [Stmt] = []
        while !isAtEnd() {
            if let newDeclaration = declaration() {
                statements.append(newDeclaration)
            }
        }
        
        return (statements, problems)
    }
    
    private func declaration() -> Stmt? {
        do {
            /*
            if match(types: .CLASS) {
                return classDeclaration()
            }
            if match(types: .FUNCTION) {
                return functionDeclaration()
            }
             */
            
            return try statement()
        } catch {
            synchronize()
            return nil
        }
        return nil
    }
    
    /*
    private func classDeclaration() -> Class {
        
    }
    
    private func functionDeclaration() -> Function {
        
    }
     */
    
    private func statement() throws -> Stmt {
        if match(types: .IF) {
            
        }
        if match(types: .OUTPUT) {
            
        }
        if match(types: .INPUT) {
            
        }
        if match(types: .RETURN) {
            
        }
        if match(types: .LOOP) {
            
        }
        if match(types: .CONTINUE) {
            
        }
        if match(types: .BREAK) {
            
        }
        
        return try expressionStatement()
    }
    
    private func expressionStatement() throws -> Stmt {
        let expr = try expression()
        return ExpressionStmt(expression: expr)
    }
    
    private func expression() throws -> Expr {
        return try assign()
    }
    
    private func assign() throws -> Expr {
        var expr = try or()
        
        var annotation: AstType? = nil
        if match(types: .COLON) {
            annotation = try typeSignature()
        }
        
        if match(types: .EQUAL) {
            let equals = previous()
            let value = try expression()
            
            return SetExpr(to: expr, annotation: annotation, value: value, type: nil)
        } else {
            if annotation != nil {
                throw error(token: peek(), message: "Expect '=' after type annotation")
            }
        }
        
        return expr
    }
    
    private func or() throws -> Expr {
        var expr = try and()
        
        while match(types: .OR) {
            let opr = previous()
            let right = try and()
            expr = LogicalExpr(left: expr, opr: opr, right: right, type: nil)
        }
        
        return expr
    }
    
    private func and() throws -> Expr {
        var expr = try equality()
        
        while match(types: .AND) {
            let opr = previous()
            let right = try equality()
            expr = LogicalExpr(left: expr, opr: opr, right: right, type: nil)
        }
        
        return expr
    }
    
    private func equality() throws -> Expr {
        var expr = try comparison()
        
        while match(types: .EQUAL_EQUAL, .BANG_EQUAL) {
            let opr = previous()
            let right = try comparison()
            expr = BinaryExpr(left: expr, opr: opr, right: right, type: nil)
        }
        
        return expr
    }
    
    private func comparison() throws -> Expr {
        var expr = try term()
        
        while match(types: .GREATER, .GREATER_EQUAL, .LESS, .LESS_EQUAL) {
            let opr = previous()
            let right = try term()
            expr = BinaryExpr(left: expr, opr: opr, right: right, type: nil)
        }
        
        return expr
    }
    
    private func term() throws -> Expr {
        var expr = try factor()
        
        while match(types: .MINUS, .PLUS) {
            let opr = previous()
            let right = try factor()
            expr = BinaryExpr(left: expr, opr: opr, right: right, type: nil)
        }
        
        return expr
    }
    
    private func factor() throws -> Expr {
        var expr: Expr
        if match(types: .NEW) {
            expr = allocation()
        } else {
            expr = try unary()
            while match(types: .SLASH, .STAR, .DIV, .MOD) {
                let opr = previous()
                let right = try unary()
                expr = BinaryExpr(left: expr, opr: opr, right: right, type: nil)
            }
        }
        
        return expr
    }
    
    private func allocation() -> Expr {
        // TODO: this
        return LiteralExpr(value: 3, type: nil)
    }
    
    private func unary() throws -> Expr {
        if match(types: .LEFT_PAREN) {
            if isAtEnd() {
                throw error(token: previous(), message: "Expect ')' after '('")
            }
            // determine if its a type cast
            let typeCastTo = try typeSignature()
            if typeCastTo != nil {
                try consume(type: .RIGHT_PAREN, message: "Expect ')' after '('")
                let right = try unary()
                return CastExpr(toType: typeCastTo!, value: right, type: nil)
            }
        }
        if match(types: .MINUS, .NOT) {
            let opr = previous()
            let right = try unary()
            return UnaryExpr(opr: opr, right: right, type: nil)
        }
        
        return try secondary()
    }
    
    func secondary() throws -> Expr {
        let expr = try primary()
        
        // TODO: this
        
        return expr
    }
    
    func primary() throws -> Expr {
        if match(types: .TRUE) {
            return LiteralExpr(value: true, type: QsBoolean())
        }
        if match(types: .FALSE) {
            return LiteralExpr(value: false, type: QsBoolean())
        }
        if match(types: .NULL) {
            return LiteralExpr(value: nil, type: QsAnyType())
        }
        if match(types: .THIS) {
            return ThisExpr(keyword: previous(), type: nil)
        }
        if match(types: .INTEGER) {
            return LiteralExpr(value: previous().value, type: QsInt())
        }
        if match(types: .FLOAT) {
            return LiteralExpr(value: previous().value, type: QsDouble())
        }
        if match(types: .IDENTIFIER) {
            return VariableExpr(name: previous(), type: nil)
        }
        if match(types: .LEFT_BRACE) {
            // TODO: array literal
        }
        if match(types: .SUPER) {
            let keyword = previous()
            try consume(type: .DOT, message: "Expect '.' after 'super'.")
            let property = try consume(type: .IDENTIFIER, message: "Expect superclass method name or field")
            return SuperExpr(keyword: keyword, property: property, type: nil)
        }
        if match(types: .LEFT_PAREN) {
            let expr = try expression()
            try consume(type: .RIGHT_PAREN, message: "Expect ')' after expression.")
            return GroupingExpr(expression: expr, type: nil)
        }
        
        throw error(token: peek(), message: "Expect expression")
    }
    
    func typeSignature() throws -> AstType? {
        var astType = tokenToAstType(peek())
        if astType == nil {
            return nil
        }
        advance()
        if match(types: .LESS) {
            if !(type(of: astType!) is AstClassType) {
                throw error(token: peek(), message: "Non-classes cannot be templated")
            }
            let templateType = try typeSignature()
            (astType as! AstClassType).templateType = templateType
            try consume(type: .GREATER, message: "Expect '>' after template")
        }
        while match(types: .LEFT_BRACKET) {
            astType = AstArrayType(contains: astType!)
            try consume(type: .RIGHT_BRACKET, message: "Expect ']' after '['")
        }
        
        return astType
    }
    
    func tokenToAstType(_ token: Token) -> AstType? {
        // in case of a class, the template field is left blank.
        var astType: AstType? = nil
        switch token.tokenType {
        case .INT:
            astType = AstIntType()
        case .DOUBLE:
            astType = AstDoubleType()
        case .BOOLEAN:
            astType = AstBooleanType()
        case .ANY:
            astType = AstAnyType()
        case .IDENTIFIER:
            if userDefinedTypes.contains(token.lexeme) {
                astType = AstClassType(name: token, templateType: nil)
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
        
        throw error(token: peek(), message: message)
    }
    
    private func check(type: TokenType) -> Bool {
        if isAtEnd() {
            return false
        }
        return peek().tokenType == type
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
    
    private func error(token: Token, message: String) -> ParserError {
        problems.append(.init(message: message, line: token.line, inlineLocation: .init(column: token.column, length: token.lexeme.count)))
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
                continue
            }
        }
    }
}
