enum InterpreterProblemType {
    case error, warning, breakpoint
}

struct InterpreterProblemInlineLocation {
    var column: Int
    var length: Int
}

struct InterpreterProblem {
    var message: String
    var line: Int
    var inlineLocation: InterpreterProblemInlineLocation?
    
    init(message: String, line: Int, inlineLocation: InterpreterProblemInlineLocation? = nil) {
        self.message = message
        self.line = line
        self.inlineLocation = inlineLocation
    }
    
    init(message: String, token: Token) {
        self.message = message
        self.line = token.line
        self.inlineLocation = .init(column: token.column, length: token.lexeme.count)
    }
}
