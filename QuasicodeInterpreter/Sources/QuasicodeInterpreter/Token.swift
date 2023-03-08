public struct Token {
    let tokenType: TokenType
    let lexeme: String
    let startLocation: InterpreterLocation
    let endLocation: InterpreterLocation
    let value: Any?
    
    func isDummy() -> Bool {
        return startLocation.index == -1
    }
    
    static func dummyToken(tokenType: TokenType, lexeme: String) -> Token {
        return .init(tokenType: tokenType, lexeme: lexeme, start: .dub(), end: .dub())
    }
    
    init(tokenType: TokenType, lexeme: String, start: InterpreterLocation, end: InterpreterLocation, value: Any? = nil) {
        self.tokenType = tokenType
        self.lexeme = lexeme
        self.startLocation = start
        self.endLocation = end
        self.value = value
    }
}
