func printSymbol(symbol: SymbolInfo) -> [String] {
    var result = ""
    var symbolType = ""
    switch symbol {
    case is GlobalVariableSymbolInfo:
        symbolType = "GlobalVariable"
        result = printGlobalVariableInfo(symbol as! GlobalVariableSymbolInfo)
    case is VariableSymbolInfo:
        symbolType = "Variable"
        result = printVariableInfo(symbol as! VariableSymbolInfo)
    case is FunctionNameSymbolInfo:
        symbolType = "FunctionName"
        result = printFunctionNameInfo(symbol as! FunctionNameSymbolInfo)
    case is FunctionSymbolInfo:
        symbolType = "Function"
        result = printFunctionInfo(symbol as! FunctionSymbolInfo)
    case is MethodSymbolInfo:
        symbolType = "Method"
        result = printMethodInfo(symbol as! MethodSymbolInfo)
    case is ClassSymbolInfo:
        symbolType = "Class"
        result = printClassInfo(symbol as! ClassSymbolInfo)
    case is ClassNameSymbolInfo:
        symbolType = "ClassName"
        result = printClassNameInfo(symbol as! ClassNameSymbolInfo)
    default:
        result = "Unexpected symbol type \(type(of: symbol))"
    }
    return [String(symbol.id), String(symbol.name), symbolType, result]
}
func printGlobalVariableInfo(_ symbol: GlobalVariableSymbolInfo) -> String {
    return "\(printVariableInfo(symbol)), status: \(symbol.globalStatus)"
}
func printVariableInfo(_ symbol: VariableSymbolInfo) -> String {
    return "type: \(printType(symbol.type))"
}
func printFunctionNameInfo(_ symbol: FunctionNameSymbolInfo) -> String {
    return "belongingFunctions: \(symbol.belongingFunctions)"
}
func printFunctionInfo(_ symbol: FunctionSymbolInfo) -> String {
    return ""
}
func printMethodInfo(_ symbol: MethodSymbolInfo) -> String {
    return "withinClass: \(stringifyOptionalInt(symbol.withinClass)), overridedBy: \(symbol.overridedBy)"
}
func printClassInfo(_ symbol: ClassSymbolInfo) -> String {
    return "classId: \(symbol.classId), depth: \(stringifyOptionalInt(symbol.classChain?.depth)), parentOf: \(stringifyOptionalIntArray(symbol.classChain?.parentOf)), upperClass: \(stringifyOptionalInt(symbol.classChain?.upperClass))"
}
func printClassNameInfo(_ symbol: ClassNameSymbolInfo) -> String {
    return ""
}
