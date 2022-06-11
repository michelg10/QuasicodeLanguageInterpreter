class AstTypeToString: AstTypeStringVisitor {
    internal func visitAstTemplateTypeNameString(asttype: AstTemplateTypeName) -> String {
        return "<TemplateType \(asttype.belongingClass).\(asttype.name.lexeme)>"
    }
    
    internal func visitAstArrayTypeString(asttype: AstArrayType) -> String {
        return "<Array\(asttype.contains.accept(visitor: self))>"
    }
    
    internal func visitAstClassTypeString(asttype: AstClassType) -> String {
        var templateArgumentsString = ""
        if asttype.templateArguments != nil {
            for templateArguments in asttype.templateArguments! {
                if templateArgumentsString != "" {
                    templateArgumentsString += ", "
                }
                templateArgumentsString+=templateArguments.accept(visitor: self)
            }
        }
        return "<Class \(asttype.name.lexeme)\(asttype.templateArguments == nil ? "" : "<\(templateArgumentsString)>")>"
    }
    
    internal func visitAstIntTypeString(asttype: AstIntType) -> String {
        return "<Int>"
    }
    
    internal func visitAstDoubleTypeString(asttype: AstDoubleType) -> String {
        return "<Double>"
    }
    
    internal func visitAstBooleanTypeString(asttype: AstBooleanType) -> String {
        return "<Boolean>"
    }
    
    internal func visitAstAnyTypeString(asttype: AstAnyType) -> String {
        return "<Any>"
    }
    
    func stringify(_ asttype: AstType) -> String {
        return asttype.accept(visitor: self)
    }
}

let astTypeToStringSingleton = AstTypeToString()
