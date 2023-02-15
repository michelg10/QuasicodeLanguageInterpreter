func generateClassSignature(className: String, templateAstTypes: [AstType]?) -> String {
    var templatesName = ""
    for templateAstType in templateAstTypes ?? [] {
        if !templatesName.isEmpty {
            templatesName += ", "
        }
        templatesName += astTypeToStringSingleton.stringify(templateAstType)
    }
    return "\(className)<\(templatesName)>"
}
