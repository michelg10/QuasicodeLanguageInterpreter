public struct Token {
    public let tokenType: TokenType
    public let lexeme: String
    private(set) public var startLocation: InterpreterLocation
    private(set) public var endLocation: InterpreterLocation
    let value: Any?
    
    public func isDummy() -> Bool {
        return startLocation.index == -1
    }
    
    static func dummyToken(tokenType: TokenType, lexeme: String) -> Token {
        return .init(tokenType: tokenType, lexeme: lexeme, start: .dub(), end: .dub())
    }
    
    public func containsLocation(_ location: InterpreterLocation) -> Bool {
        return startLocation <= location && location < endLocation
    }
    
    public mutating func shiftLocation(by shift: Int) {
        self.startLocation.index += shift
        self.endLocation.index += shift
    }
    
    public init(tokenType: TokenType, lexeme: String, start: InterpreterLocation, end: InterpreterLocation, value: Any? = nil) {
        self.tokenType = tokenType
        self.lexeme = lexeme
        self.startLocation = start
        self.endLocation = end
        self.value = value
    }
}
