func hashTypeIntoHasher(_ value: AstType, _ hasher: inout Hasher) {
    switch value {
    case is AstIntType:
        hasher.combine(TypeHashValues.INT)
    case is AstDoubleType:
        hasher.combine(TypeHashValues.DOUBLE)
    case is AstBooleanType:
        hasher.combine(TypeHashValues.BOOLEAN)
    case is AstAnyType:
        hasher.combine(TypeHashValues.ANY)
    case is AstClassType:
        hasher.combine(TypeHashValues.CLASS)
        let asClass = value as! AstClassType
        hasher.combine(asClass.name.lexeme)
        hasher.combine(asClass.templateArguments?.count ?? 0)
        if asClass.templateArguments != nil {
            for templateArgument in asClass.templateArguments! {
                hashTypeIntoHasher(templateArgument, &hasher)
            }
        }
    case is AstArrayType:
        hasher.combine(TypeHashValues.ARRAY)
        hashTypeIntoHasher((value as! AstArrayType).contains, &hasher)
    default:
        assertionFailure("Attempting to hash unknown type \"\(type(of: value))\"")
    }
}
