internal enum InterpreterProblemType {
    case error, warning, breakpoint
}

internal struct StringLineAndColumnLocation {
    var line: Int
    var column: Int
}

internal struct InterpreterLocation {
    var index: Int
    init(index: Int) {
        self.index = index
    }
    init(start: Token) {
        index = start.startLocation.index
    }
    init(end: Token) {
        index = end.endLocation.index
    }
    static func dub() -> InterpreterLocation {
        return .init(index: -1)
    }
}

internal struct InterpreterProblem {
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
