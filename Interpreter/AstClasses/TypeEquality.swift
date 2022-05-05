func typesIsEqual(_ lhs: AstType, _ rhs: AstType) -> Bool {
    if lhs is AstArrayType {
        if rhs is AstArrayType {
            return typesIsEqual((lhs as! AstArrayType).contains, (rhs as! AstArrayType).contains)
        } else {
            return false
        }
    }
    
    if lhs is AstClassType {
        if rhs is AstClassType {
            let lhsClass = lhs as! AstClassType
            let rhsClass = rhs as! AstClassType
            
            if lhsClass.name.lexeme == rhsClass.name.lexeme {
                if lhsClass.templateTypes == nil || rhsClass.templateTypes == nil {
                    if lhsClass.templateTypes != nil || rhsClass.templateTypes != nil {
                        // one of them isn't nil
                        return false
                    } else {
                        return true
                    }
                }
                
                // compare their template types
                if lhsClass.templateTypes!.count != rhsClass.templateTypes!.count {
                    return false // this shouldn't happen because its the same class identifier but if i dont do this the next one might crash so... safest route is to just return false
                }
                
                for i in 0..<lhsClass.templateTypes!.count {
                    if !typesIsEqual(lhsClass.templateTypes![i], rhsClass.templateTypes![i]) {
                        return false
                    }
                }
                return true
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
