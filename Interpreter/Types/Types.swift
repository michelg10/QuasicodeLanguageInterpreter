protocol QsType {
    var assignable: Bool { get set }
}

class QsArray: QsType {
    init(contains: QsType, assignable: Bool) {
        self.assignable = assignable
        self.contains = contains
    }
    
    var assignable: Bool
    let contains: QsType
}

protocol QsNativeType: QsType {}

func isNumericType(_ type: QsType) -> Bool {
    return type is QsInt || type is QsDouble
}

class QsInt: QsNativeType {
    init(assignable: Bool) {
        self.assignable = assignable
    }
    
    var assignable: Bool
}

class QsDouble: QsNativeType {
    init(assignable: Bool) {
        self.assignable = assignable
    }
    
    var assignable: Bool
}

class QsBoolean: QsNativeType {
    init(assignable: Bool) {
        self.assignable = assignable
    }
    
    var assignable: Bool
}

class QsFunction: QsType {
    let nameId: Int
    var assignable: Bool {
        get {
            return false
        }
        set {
            
        }
    }
    
    init(nameId: Int) {
        self.nameId = nameId
    }
}

class QsAnyType: QsType {
    init(assignable: Bool) {
        self.assignable = assignable
    }
    
    var assignable: Bool
}

class QsClass: QsType {
    init(name: String, id: Int, assignable: Bool) {
        self.assignable = assignable
        self.name = name
        self.id = id
    }
    
    var assignable: Bool
    let name: String
    let id: Int
}

class QsErrorType: QsType {
    internal init(assignable: Bool) {
        self.assignable = assignable
    }
    
    var assignable: Bool
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
