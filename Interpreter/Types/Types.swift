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

class QsAnyType: QsType {}

let builtInTypesCount = 5 // classes start counting from this number

class QsClass: QsType {
    init(name: String, id: Int, superclass: QsClass?, methodTypes: [MethodSignature : QsType], fieldTypes: [String : QsType]) {
        self.name = name
        self.id = id
        self.superclass = superclass
        self.methodTypes = methodTypes
        self.fieldTypes = fieldTypes
    }
    
    let name: String
    let id: Int
    let superclass: QsClass?
    let methodTypes: [MethodSignature : QsType]
    let fieldTypes: [String : QsType]
}

func typesIsEqual(_ lhs: QsType, _ rhs: QsType) -> Bool {
    if lhs is QsNativeType {
        if rhs is QsNativeType {
            return type(of: lhs) == type(of: rhs)
        } else {
            return false
        }
    }
    
    if lhs is QsAnyType {
        if rhs is QsAnyType {
            return true
        }
        return false
    }
    
    if lhs is QsArray {
        if rhs is QsArray {
            return typesIsEqual((lhs as! QsArray).contains, (rhs as! QsArray).contains)
        } else {
            return false
        }
    }
    
    if lhs is QsClass {
        if rhs is QsClass {
            return (lhs as! QsClass).id == (rhs as! QsClass).id
        }
    }
    
    assertionFailure("Type equality reached end")
    
    return true
}

func hashTypeIntoHasher(_ value: QsType, _ hasher: inout Hasher) {
    switch value {
    case is QsInt:
        hasher.combine(1)
    case is QsDouble:
        hasher.combine(2)
    case is QsBoolean:
        hasher.combine(3)
    case is QsAnyType:
        hasher.combine(4)
    case is QsClass:
        hasher.combine((value as! QsClass).id)
    case is QsArray:
        hasher.combine(0)
        hashTypeIntoHasher((value as! QsArray).contains, &hasher)
    default:
        assertionFailure("Attempting to hash type \"\(type(of: value))\"")
    }
}

struct MethodSignature: Hashable {
    let parameters: [QsType]
    
    static func == (lhs: MethodSignature, rhs: MethodSignature) -> Bool {
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
}
