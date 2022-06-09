func generateClassSignature(className: String, templateAstTypes: [AstType]?) -> String {
    var templatesName = ""
    let astPrinter = AstPrinter()
    for templateAstType in templateAstTypes ?? [] {
        if templatesName != "" {
            templatesName += ", "
        }
        templatesName += astPrinter.printAst(templateAstType)
    }
    return "\(className)<\(templatesName)>"
}
