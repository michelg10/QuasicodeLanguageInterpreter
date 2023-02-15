class AstTypeToString: AstTypeStringVisitor {
    func visitAstTemplateTypeNameString(asttype: AstTemplateTypeName) -> String {
        return "<TemplateType \(asttype.belongingClass).\(asttype.name.lexeme)>"
    }
    
    func visitAstArrayTypeString(asttype: AstArrayType) -> String {
        return "<Array\(asttype.contains.accept(visitor: self))>"
    }
    
    func visitAstClassTypeString(asttype: AstClassType) -> String {
        var templateArgumentsString = ""
        if asttype.templateArguments != nil {
            for templateArguments in asttype.templateArguments! {
                if !templateArgumentsString.isEmpty {
                    templateArgumentsString += ", "
                }
                templateArgumentsString += templateArguments.accept(visitor: self)
            }
        }
        return "<Class \(asttype.name.lexeme)\(asttype.templateArguments == nil ? "" : "<\(templateArgumentsString)>")>"
    }
    
    func visitAstIntTypeString(asttype: AstIntType) -> String {
        return "<Int>"
    }
    
    func visitAstDoubleTypeString(asttype: AstDoubleType) -> String {
        return "<Double>"
    }
    
    func visitAstBooleanTypeString(asttype: AstBooleanType) -> String {
        return "<Boolean>"
    }
    
    func visitAstAnyTypeString(asttype: AstAnyType) -> String {
        return "<Any>"
    }
    
    func stringify(_ asttype: AstType) -> String {
        return asttype.accept(visitor: self)
    }
}

let astTypeToStringSingleton = AstTypeToString()
