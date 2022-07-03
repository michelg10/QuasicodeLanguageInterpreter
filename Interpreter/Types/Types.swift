protocol QsType {
    var assignable: Bool { get set }
}

class QsArray: QsType {
    init(contains: QsType, assignable: Bool) {
        self.assignable = assignable
        self.contains = contains
    }
    init(contains: QsType) {
        self.assignable = false
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
    init() {
        self.assignable = false
    }
    
    var assignable: Bool
}

class QsDouble: QsNativeType {
    init(assignable: Bool) {
        self.assignable = assignable
    }
    init() {
        self.assignable = false
    }
    
    var assignable: Bool
}

class QsBoolean: QsNativeType {
    init(assignable: Bool) {
        self.assignable = assignable
    }
    init() {
        self.assignable = false
    }
    
    var assignable: Bool
}

class QsAnyType: QsType {
    init(assignable: Bool) {
        self.assignable = assignable
    }
    init() {
        self.assignable = false
    }
    
    var assignable: Bool
}

class QsClass: QsType {
    init(name: String, id: Int, assignable: Bool) {
        self.assignable = assignable
        self.name = name
        self.id = id
    }
    init(name: String, id: Int) {
        self.assignable = false
        self.name = name
        self.id = id
    }
    
    var assignable: Bool
    let name: String
    let id: Int
}

class QsErrorType: QsType {
    init(assignable: Bool) {
        self.assignable = assignable
    }
    init() {
        self.assignable = false
    }
    
    var assignable: Bool
}

class QsVoidType: QsType {
    init() {
        self.assignable = false
    }
    
    var assignable: Bool
}
