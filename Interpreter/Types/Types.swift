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

class QsClass {
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
    if type(of: lhs) is QsNativeType {
        if type(of: rhs) is QsNativeType {
            return type(of: lhs) == type(of: rhs)
        } else {
            return false
        }
    }
    
    return true
}

func hashTypeIntoHasher(_ value: QsType, _ hasher: inout Hasher) {
    switch type(of: value) {
    case is QsInt.Type:
        hasher.combine(1)
    case is QsDouble.Type:
        hasher.combine(2)
    case is QsBoolean.Type:
        hasher.combine(3)
    case is QsAnyType.Type:
        hasher.combine(4)
    case is QsClass.Type:
        hasher.combine((value as! QsClass).id)
    case is QsArray.Type:
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
