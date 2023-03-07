internal protocol QsType {
    var assignable: Bool { get set }
}

internal class QsArray: QsType {
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

internal protocol QsNativeType: QsType {}

internal func isNumericType(_ type: QsType) -> Bool {
    return type is QsInt || type is QsDouble
}

internal class QsInt: QsNativeType {
    init(assignable: Bool) {
        self.assignable = assignable
    }
    init() {
        self.assignable = false
    }
    
    var assignable: Bool
}

internal class QsDouble: QsNativeType {
    init(assignable: Bool) {
        self.assignable = assignable
    }
    init() {
        self.assignable = false
    }
    
    var assignable: Bool
}

internal class QsBoolean: QsNativeType {
    init(assignable: Bool) {
        self.assignable = assignable
    }
    init() {
        self.assignable = false
    }
    
    var assignable: Bool
}

internal class QsAnyType: QsType {
    init(assignable: Bool) {
        self.assignable = assignable
    }
    init() {
        self.assignable = false
    }
    
    var assignable: Bool
}

internal let builtinClassNames = ["Collection", "Stack", "Queue"]
internal class QsClass: QsType {
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

internal class QsErrorType: QsType {
    init(assignable: Bool) {
        self.assignable = assignable
    }
    init() {
        self.assignable = false
    }
    
    var assignable: Bool
}

internal class QsVoidType: QsType {
    init() {
        self.assignable = false
    }
    
    var assignable: Bool {
        get {
            false
        }
        // swiftlint:ignore:next unused_setter_value
        set {
            // do nothing: QsVoidType should always be unsettable but the protocol requires that assignable be settable
        }
    }
}
