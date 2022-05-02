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
            if match(types: .EOL) {
                // its just an empty line, do nothing about it
                return nil
            }
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
            let untilAsUnaryNotOpr = Token.init(tokenType: .NOT, lexeme: whileOrUntil.lexeme, line: whileOrUntil.line, column: whileOrUntil.column, value: whileOrUntil.value)
            condition = UnaryExpr(opr: untilAsUnaryNotOpr, right: condition, type: nil)
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
        var statements: [Stmt] = []
        while !check(types: additionalEndMarkers) && !check(type: .END) && !isAtEnd() {
            if let toInsert = declaration() {
                statements.append(toInsert)
            }
        }
        return statements
    }
    
    private func IfStatement() throws -> Stmt {
        let condition = try expression()
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
        if match(types: .COLON) {
            annotation = try typeSignature(matchArray: true)
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
            expr = try allocation()
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
    
    private func allocation() throws -> Expr {
        let newKeyword = previous()
        // consume the base type
        let baseType = peek()
        var allocationType = try typeSignature(matchArray: false)
        if allocationType == nil {
            throw error(token: newKeyword, message: "Expect type after 'new'")
        }
        if match(types: .LEFT_BRACKET) {
            var capacity: [Expr] = []
            repeat {
                capacity.append(try expression())
                allocationType = AstArrayType(contains: allocationType!)
                try consume(type: .RIGHT_BRACKET, message: "Expect ']' after '['")
            } while match(types: .LEFT_BRACKET)
            return ArrayAllocationExpr(contains: allocationType!, capacity: capacity, type: nil)
        } else if match(types: .LEFT_PAREN) {
            let argumentsList = try arguments()
            if !(allocationType! is AstClassType) {
                throw error(token: baseType, message: "Expect class")
            }
            return ClassAllocationExpr(classType: allocationType as! AstClassType, arguments: argumentsList, type: nil)
        }
        
        return LiteralExpr(value: 3, type: nil)
    }
    
    private func unary() throws -> Expr {
        let statePrior = current
        if match(types: .LEFT_PAREN) {
            if isAtEnd() {
                throw error(token: previous(), message: "Expect ')' after '('")
            }
            // determine if its a type cast
            let typeCastTo = try typeSignature(matchArray: true)
            if typeCastTo != nil {
                try consume(type: .RIGHT_PAREN, message: "Expect ')' after '('")
                let right = try unary()
                return CastExpr(toType: typeCastTo!, value: right, type: nil)
            } else {
                // restore state
                current = statePrior
            }
        }
        if match(types: .MINUS, .NOT) {
            let opr = previous()
            let right = try unary()
            return UnaryExpr(opr: opr, right: right, type: nil)
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
        return CallExpr(callee: callee, paren: paren, arguments: argumentsList, type: nil)
    }
    
    private func secondary() throws -> Expr {
        var expr = try primary()
        
        while true {
            if match(types: .LEFT_PAREN) {
                expr = try finishCall(callee: expr)
            } else if match(types: .DOT) {
                let name = try consume(type: .IDENTIFIER, message: "Expect property name after '.'.")
                expr = GetExpr(object: expr, name: name, type: nil)
            } else if match(types: .LEFT_BRACKET) {
                let index = try expression()
                expr = SubscriptExpr(expression: expr, index: index, type: nil)
                try consume(type: .RIGHT_BRACKET, message: "Expect ']' after '['")
            } else {
                break
            }
        }
        
        return expr
    }
    
    private func primary() throws -> Expr {
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
        if match(types: .STRING) {
            return LiteralExpr(value: previous().value, type: QsClass(name: "String", id: 0, superclass: nil, methodTypes: [:], fieldTypes: [:]))
        }
        if match(types: .IDENTIFIER) {
            return VariableExpr(name: previous(), type: nil)
        }
        if match(types: .LEFT_BRACE) {
            return try arrayLiteral()
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
    
    private func arrayLiteral() throws -> Expr {
        var values: [Expr] = []
        repeat {
            values.append(try expression())
        } while match(types: .COMMA)
        
        return ArrayLiteralExpr(values: values, type: nil)
    }
    
    private func typeSignature(matchArray: Bool) throws -> AstType? {
        var astType = tokenToAstType(peek())
        if astType == nil {
            return nil
        }
        advance()
        if match(types: .LESS) {
            if !(type(of: astType!) is AstClassType) {
                throw error(token: peek(), message: "Non-classes cannot be templated")
            }
            let templateType = try typeSignature(matchArray: true)
            (astType as! AstClassType).templateType = templateType
            try consume(type: .GREATER, message: "Expect '>' after template")
        }
        
        if matchArray {
            while match(types: .LEFT_BRACKET) {
                astType = AstArrayType(contains: astType!)
                try consume(type: .RIGHT_BRACKET, message: "Expect ']' after '['")
            }
        }
        
        return astType
    }
    
    private func tokenToAstType(_ token: Token) -> AstType? {
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
                advance()
            }
        }
    }
}
