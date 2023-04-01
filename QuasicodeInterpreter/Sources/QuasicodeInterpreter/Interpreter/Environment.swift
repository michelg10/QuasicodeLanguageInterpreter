internal struct StoredVariable {
    var name: String // for debugging purposes
    var value: Any?
}

internal class Environment {
    public var enclosing: Environment?
    private var variables: [Int : StoredVariable] = [:]
    
    init(enclosing: Environment? = nil) {
        self.enclosing = enclosing
    }
    
    func add(symbolTableId: Int, name: String, value: Any?) {
        add(symbolTableId: symbolTableId, variable: .init(name: name, value: value))
    }
    
    func add(symbolTableId: Int, variable: StoredVariable) {
        variables[symbolTableId] = variable
    }
    
    func fetch(symbolTableId: Int) -> StoredVariable? {
        let result = variables[symbolTableId]
        if result == nil && enclosing != nil {
            return enclosing!.fetch(symbolTableId: symbolTableId)
        }
        return result
    }
}
