// i don't know what this is going to be used for but i already wrote it so... lets keep it for now
struct MethodQsTypeSignature: Hashable {
    let name: String
    let parameters: [QsType]
    
    static func == (lhs: MethodQsTypeSignature, rhs: MethodQsTypeSignature) -> Bool {
        if lhs.name != rhs.name {
            return false
        }
        
        if lhs.parameters.count != rhs.parameters.count {
            return false
        }
        
        for i in 0..<lhs.parameters.count {
            if !typesIsEqual(lhs.parameters[i], rhs.parameters[i]) {
                return false
            }
        }
        return true
    }
    
    func hash(into hasher: inout Hasher) {
        for parameter in parameters {
            hashTypeIntoHasher(parameter, &hasher)
        }
    }
    
    init(functionStmt: FunctionStmt, symbolTable: SymbolTables) {
        self.name = functionStmt.name.lexeme
        self.parameters = functionStmt.params.map({ functionParam in
            functionParam.getType(symbolTable: symbolTable)!
        })
    }
}
