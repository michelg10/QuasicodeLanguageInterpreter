struct MethodAstTypeSignature: Hashable {
    let name: String
    let parameters: [AstType]
    
    static func == (lhs: MethodAstTypeSignature, rhs: MethodAstTypeSignature) -> Bool {
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
    
    init(functionStmt: FunctionStmt) {
        self.name = functionStmt.name.lexeme
        self.parameters = functionStmt.params.map({ functionParam in
            functionParam.astType!
        })
    }
}
