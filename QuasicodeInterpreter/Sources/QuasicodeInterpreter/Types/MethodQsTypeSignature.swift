// i don't know what this is going to be used for but i already wrote it so... lets keep it for now
internal struct MethodQsTypeSignature: Hashable {
    let name: String
    let parameters: [QsType]
    
    static func == (lhs: MethodQsTypeSignature, rhs: MethodQsTypeSignature) -> Bool {
        if lhs.name != rhs.name {
            return false
        }
        
        if lhs.parameters.count != rhs.parameters.count {
            return false
        }
        
        if lhs.parameters.elementsEqual(rhs.parameters, by: { parameter1, parameter2 in
            typesEqual(parameter1, parameter2, anyEqAny: true)
        }) {
            return true
        } else {
            return false
        }
    }
    
    func hash(into hasher: inout Hasher) {
        for parameter in parameters {
            hashTypeIntoHasher(parameter, &hasher)
        }
    }
    
    init(functionStmt: FunctionStmt, symbolTable: SymbolTable) {
        self.name = functionStmt.name.lexeme
        self.parameters = functionStmt.params.map({ functionParam in
            functionParam.getType(symbolTable: symbolTable)!
        })
    }
}
