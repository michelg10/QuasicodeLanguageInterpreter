public struct InterpreterProblem {
    public var message: String
    public var startLocation: InterpreterLocation
    public var endLocation: InterpreterLocation
    
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
