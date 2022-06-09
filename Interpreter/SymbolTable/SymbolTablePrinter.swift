func printSymbol(symbol: Symbol) -> [String] {
    var result = ""
    var symbolType = ""
    switch symbol {
    case is GlobalVariableSymbol:
        symbolType = "GlobalVariable"
        result = printGlobalVariableInfo(symbol as! GlobalVariableSymbol)
    case is VariableSymbol:
        symbolType = "Variable"
        result = printVariableInfo(symbol as! VariableSymbol)
    case is FunctionNameSymbol:
        symbolType = "FunctionName"
        result = printFunctionNameInfo(symbol as! FunctionNameSymbol)
    case is FunctionSymbol:
        symbolType = "Function"
        result = printFunctionInfo(symbol as! FunctionSymbol)
    case is MethodSymbol:
        symbolType = "Method"
        result = printMethodInfo(symbol as! MethodSymbol)
    case is ClassSymbol:
        symbolType = "Class"
        result = printClassInfo(symbol as! ClassSymbol)
    case is ClassNameSymbol:
        symbolType = "ClassName"
        result = printClassNameInfo(symbol as! ClassNameSymbol)
    default:
        result = "Unexpected symbol type \(type(of: symbol))"
    }
    return [String(symbol.id), String(symbol.name), symbolType, result]
}
func printGlobalVariableInfo(_ symbol: GlobalVariableSymbol) -> String {
    return "\(printVariableInfo(symbol)), status: \(symbol.globalStatus)"
}
func printVariableInfo(_ symbol: VariableSymbol) -> String {
    return "type: \(printType(symbol.type))"
}
func printFunctionNameInfo(_ symbol: FunctionNameSymbol) -> String {
    return "belongingFunctions: \(symbol.belongingFunctions)"
}
func printFunctionInfo(_ symbol: FunctionSymbol) -> String {
    return ""
}
func printMethodInfo(_ symbol: MethodSymbol) -> String {
    return "withinClass: \(stringifyOptionalInt(symbol.withinClass)), overridedBy: \(symbol.overridedBy)"
}
func printClassInfo(_ symbol: ClassSymbol) -> String {
    return "classId: \(symbol.classId), depth: \(stringifyOptionalInt(symbol.classChain?.depth)), parentOf: \(stringifyOptionalIntArray(symbol.classChain?.parentOf)), upperClass: \(stringifyOptionalInt(symbol.classChain?.upperClass))"
}
func printClassNameInfo(_ symbol: ClassNameSymbol) -> String {
    return ""
}
