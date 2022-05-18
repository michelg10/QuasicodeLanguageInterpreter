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
        } else {
            return false
        }
    }
    
    if lhs is QsFunction {
        if rhs is QsFunction {
            return (lhs as! QsFunction).nameId == (rhs as! QsClass).id
        } else {
            return false
        }
    }
    
    assertionFailure("Type equality reached end")
    
    return true
}
