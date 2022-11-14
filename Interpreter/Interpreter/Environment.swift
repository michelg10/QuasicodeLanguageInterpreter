struct StoredVariable {
    var name: String // for debugging purposes
    var value: Any?
}

class Environment {
    private var variables: [Int : StoredVariable] = [:]
    
    func add(symbolTableId: Int, name: String, value: Any?) {
        add(symbolTableId: symbolTableId, variable: .init(name: name, value: value))
    }
    
    func add(symbolTableId: Int, variable: StoredVariable) {
        // TODO: check if it exists in the previous environments
        
        variables[symbolTableId] = variable
    }
    
    func fetch(symbolTableId: Int) -> StoredVariable? {
        // TODO: check if it exists in previous environments
        
        return variables[symbolTableId]
    }
}
