func createFunctionAstTypeSignature(functionStmt: FunctionStmt) -> String {
    return createFunctionAstTypeSignature(functionName: functionStmt.name.lexeme, functionParams: functionStmt.params.map({ astFunctionParam in
        astFunctionParam.astType
    }))
}
func createFunctionAstTypeSignature(functionName: String, functionParams: [AstType?]) -> String {
    var paramsName = ""
    for param in functionParams {
        if !paramsName.isEmpty {
            paramsName += ", "
        }
        paramsName += astTypeToStringSingleton.stringify(param ?? AstAnyType(startLocation: .dub(), endLocation: .dub()))
    }
    return "\(functionName)(\(paramsName))"
}
