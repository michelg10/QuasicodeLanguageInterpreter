struct Token {
    let tokenType: TokenType
    let lexeme: String
    let line: Int
    let column: Int
    let value: Any?
    
    static func dummyToken(tokenType: TokenType, lexeme: String) -> Token {
        return .init(tokenType: tokenType, lexeme: lexeme, line: -1, column: -1)
    }
    
    init(tokenType: TokenType, lexeme: String, line: Int, column: Int, value: Any? = nil) {
        self.tokenType = tokenType
        self.lexeme = lexeme
        self.line = line
        self.column = column
        self.value = value
    }
}
