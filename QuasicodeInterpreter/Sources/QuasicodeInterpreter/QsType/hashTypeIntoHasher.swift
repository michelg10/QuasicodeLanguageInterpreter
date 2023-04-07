internal func hashTypeIntoHasher(_ value: QsType, _ hasher: inout Hasher) {
    // reserve non-negative numbers for class IDs
    switch value {
    case is QsInt:
        hasher.combine(TypeHashValues.INT)
    case is QsDouble:
        hasher.combine(TypeHashValues.DOUBLE)
    case is QsBoolean:
        hasher.combine(TypeHashValues.BOOLEAN)
    case is QsAnyType:
        hasher.combine(TypeHashValues.ANY)
    case is QsClass:
        hasher.combine(TypeHashValues.CLASS)
        hasher.combine((value as! QsClass).id)
    case is QsArray:
        hasher.combine(TypeHashValues.ARRAY)
        hashTypeIntoHasher((value as! QsArray).contains, &hasher)
    case is QsErrorType:
        hasher.combine(TypeHashValues.ERROR)
        hasher.combine(Int.random(in: Int.min...Int.max))
    default:
        assertionFailure("Attempting to hash unknown type \"\(type(of: value))\"")
    }
}
