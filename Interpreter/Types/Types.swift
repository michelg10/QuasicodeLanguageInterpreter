protocol QsType {}

class QsArray: QsType {
    init(contains: QsType) {
        self.contains = contains
    }
    
    let contains: QsType
}

protocol QsNativeType: QsType {}

class QsInt: QsNativeType {}

class QsDouble: QsNativeType {}

class QsBoolean: QsNativeType {}

class QsFunction: QsType {
    let nameId: Int
    
    init(nameId: Int) {
        self.nameId = nameId
    }
}

class QsAnyType: QsType {}

class QsClass: QsType {
    init(name: String, id: Int) {
        self.name = name
        self.id = id
    }
    
    let name: String
    let id: Int
}

struct MethodSignature: Hashable {
    let name: String
    let parameters: [QsType]
    
    static func == (lhs: MethodSignature, rhs: MethodSignature) -> Bool {
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
        for i in parameters {
            hashTypeIntoHasher(i, &hasher)
        }
    }
    
    init(functionStmt: FunctionStmt) {
        self.name = functionStmt.name.lexeme
        self.parameters = functionStmt.params.map({ functionParam in
            functionParam.type!
        })
    }
}
