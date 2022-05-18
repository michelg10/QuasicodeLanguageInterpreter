enum InterpreterProblemType {
    case error, warning, breakpoint
}

struct InterpreterLocation {
    var line: Int
    var column: Int
    init(line: Int, column: Int) {
        self.line = line
        self.column = column
    }
    init(start: Token) {
        line = start.startLocation.line
        column = start.startLocation.column
    }
    init(end: Token) {
        line = end.endLocation.line
        column = end.endLocation.column
    }
    static func dub() -> InterpreterLocation {
        return .init(line: -1, column: -1)
    }
}

struct InterpreterProblem {
    var message: String
    var startLocation: InterpreterLocation
    var endLocation: InterpreterLocation
    
    init(message: String, start: InterpreterLocation, end: InterpreterLocation) {
        self.message = message
        self.startLocation = start
        self.endLocation = end
    }
    
    init(message: String, token: Token) {
        self.message = message
        self.startLocation = token.startLocation
        self.endLocation = token.endLocation
    }
}
