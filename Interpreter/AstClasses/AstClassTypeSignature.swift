func generateClassSignature(className: String, templateAstTypes: [AstType]?) -> String {
    var templatesName = ""
    for templateAstType in templateAstTypes ?? [] {
        if templatesName != "" {
            templatesName += ", "
        }
        templatesName += astTypeToStringSingleton.stringify(templateAstType)
    }
    return "\(className)<\(templatesName)>"
}
