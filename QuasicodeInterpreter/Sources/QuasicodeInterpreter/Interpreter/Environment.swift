internal struct StoredVariable {
    var name: String // for debugging purposes
    var value: Any?
}

internal class Environment {
    private class FrameEnvironment {
        private var variables: [Int : StoredVariable] = [:]
        
        init() {
            
        }
        
        func add(symbolTableId: Int, variable: StoredVariable) {
            variables[symbolTableId] = variable
        }
        
        func fetch(symbolTableId: Int) -> StoredVariable? {
            return variables[symbolTableId]
        }
    }
    
    private var frameEnvironments: [FrameEnvironment]
    
    init() {
        self.frameEnvironments = [.init()]
    }
    
    func add(symbolTableId: Int, name: String, value: Any?) {
        let topEnvironment = frameEnvironments.last!
        topEnvironment.add(symbolTableId: symbolTableId, variable: .init(name: name, value: value))
    }
    
    func add(symbolTableId: Int, variable: StoredVariable) {
        let topEnvironment = frameEnvironments.last!
        topEnvironment.add(symbolTableId: symbolTableId, variable: variable)
    }
    
    func fetch(symbolTableId: Int) -> StoredVariable? {
        var result: StoredVariable?
        for environment in frameEnvironments.reversed() {
            result = environment.fetch(symbolTableId: symbolTableId)
            if result != nil {
                return result
            }
        }
        
        return result
    }
    
    func pushFrame() {
        frameEnvironments.append(.init())
    }
    
    func popFrame() {
        frameEnvironments.popLast()
    }
}
