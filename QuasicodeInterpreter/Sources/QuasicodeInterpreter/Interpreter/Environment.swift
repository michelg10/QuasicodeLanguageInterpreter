internal struct StoredVariable {
    var name: String // for debugging purposes
    var value: Any?
}

internal class Environment {
    private var variables: [Int : StoredVariable] = [:]
    
    func add(symbolTableId: Int, name: String, value: Any?) {
        add(symbolTableId: symbolTableId, variable: .init(name: name, value: value))
    }
    
    func add(symbolTableId: Int, variable: StoredVariable) {
        variables[symbolTableId] = variable
    }
    
    func fetch(symbolTableId: Int) -> StoredVariable? {
        return variables[symbolTableId]
    }
}
