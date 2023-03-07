internal func typesEqual(_ lhs: AstType, _ rhs: AstType) -> Bool {
    if lhs is AstArrayType {
        if rhs is AstArrayType {
            return typesEqual((lhs as! AstArrayType).contains, (rhs as! AstArrayType).contains)
        } else {
            return false
        }
    }
    
    if lhs is AstClassType {
        if rhs is AstClassType {
            let lhsClass = lhs as! AstClassType
            let rhsClass = rhs as! AstClassType
            
            if lhsClass.name.lexeme == rhsClass.name.lexeme {
                if lhsClass.templateArguments == nil || rhsClass.templateArguments == nil {
                    if lhsClass.templateArguments != nil || rhsClass.templateArguments != nil {
                        // one of them isn't nil
                        return false
                    } else {
                        return true
                    }
                }
                
                // compare their template types
                if lhsClass.templateArguments!.count != rhsClass.templateArguments!.count {
                    // this shouldn't happen because its the same class identifier
                    // but if i dont do this the next one might crash so...
                    // the safest route is to just return false
                    return false
                }
                
                if lhsClass.templateArguments!.elementsEqual(rhsClass.templateArguments!, by: { lhs, rhs in
                    typesEqual(lhs, rhs)
                }) {
                    return true
                } else {
                    return false
                }
            } else {
                return false
            }
        } else {
            return false
        }
    }
    
    if lhs is AstTemplateTypeName {
        if rhs is AstTemplateTypeName {
            return (lhs as! AstTemplateTypeName).name.lexeme == (rhs as! AstTemplateTypeName).name.lexeme
        } else {
            return false
        }
    }
    
    // for int, double, boolean, any
    return type(of: lhs) == type(of: rhs)
}
