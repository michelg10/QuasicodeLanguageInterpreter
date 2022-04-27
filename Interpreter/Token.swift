struct Token {
    let tokenType: TokenType
    let lexeme: String
    let line: Int
    let column: Int
    let value: Any?
    
    init(tokenType: TokenType, lexeme: String, line: Int, column: Int, value: Any? = nil) {
        self.tokenType = tokenType
        self.lexeme = lexeme
        self.line = line
        self.column = column
        self.value = value
    }
}
