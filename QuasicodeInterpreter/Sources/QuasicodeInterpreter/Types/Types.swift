public protocol QsType {
    var assignable: Bool { get set }
}

public class QsArray: QsType {
    init(contains: QsType, assignable: Bool) {
        self.assignable = assignable
        self.contains = contains
    }
    init(contains: QsType) {
        self.assignable = false
        self.contains = contains
    }
    
    public var assignable: Bool
    public let contains: QsType
}

public protocol QsNativeType: QsType {}

internal func isNumericType(_ type: QsType) -> Bool {
    return type is QsInt || type is QsDouble
}

public class QsInt: QsNativeType {
    init(assignable: Bool) {
        self.assignable = assignable
    }
    init() {
        self.assignable = false
    }
    
    public var assignable: Bool
}

public class QsDouble: QsNativeType {
    init(assignable: Bool) {
        self.assignable = assignable
    }
    init() {
        self.assignable = false
    }
    
    public var assignable: Bool
}

public class QsBoolean: QsNativeType {
    init(assignable: Bool) {
        self.assignable = assignable
    }
    init() {
        self.assignable = false
    }
    
    public var assignable: Bool
}

public class QsAnyType: QsType {
    init(assignable: Bool) {
        self.assignable = assignable
    }
    init() {
        self.assignable = false
    }
    
    public var assignable: Bool
}

public let builtinClassNames = ["Collection", "Stack", "Queue"]
public class QsClass: QsType {
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
    
    public var assignable: Bool
    public let name: String
    public let id: Int
}

public class QsErrorType: QsType {
    init(assignable: Bool) {
        self.assignable = assignable
    }
    init() {
        self.assignable = false
    }
    
    public var assignable: Bool
}

public class QsVoidType: QsType {
    init() {
        self.assignable = false
    }
    
    public var assignable: Bool {
        get {
            false
        }
        // swiftlint:ignore:next unused_setter_value
        set {
            // do nothing: QsVoidType should always be unsettable but the protocol requires that assignable be settable
        }
    }
}
