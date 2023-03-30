internal func printSymbol(symbol: Symbol) -> [String] {
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
    return [String(symbol.id), String(symbol.belongsToTable), String(symbol.name), symbolType, result]
}
internal func printGlobalVariableInfo(_ symbol: GlobalVariableSymbol) -> String {
    printVariableInfo(symbol)
}
internal func printVariableInfo(_ symbol: VariableSymbol) -> String {
    "type: \(printType(symbol.type)), status: \(symbol.variableStatus), variableType: \(symbol.variableType)"
}
internal func printFunctionNameInfo(_ symbol: FunctionNameSymbol) -> String {
    "belongingFunctions: \(symbol.belongingFunctions), isForMethods: \(symbol.isForMethods)"
}
internal func debugClosedIntRangeToString(_ range: ClosedRange<Int>) -> String {
    "\(range.lowerBound)...\(range.upperBound)"
}
internal func debugFunctionParamsToString(_ functionParams: [FunctionParam]) -> String {
    "[" + functionParams.reduce(into: "", { result, functionParam in
        if !result.isEmpty {
            result += ", "
        }
        result += "\(functionParam.name): \(printType(functionParam.type))"
    }) + "]"
}
internal func printFunctionInfo(_ symbol: FunctionSymbol) -> String {
    "functionParams: \(debugFunctionParamsToString(symbol.functionParams)), " +
    "paramRange: \(debugClosedIntRangeToString(symbol.paramRange)), " +
    "returnType: \(printType(symbol.returnType))"
}
internal func printMethodInfo(_ symbol: MethodSymbol) -> String {
    "functionParams: \(debugFunctionParamsToString(symbol.functionParams)), " +
    "paramRange: \(debugClosedIntRangeToString(symbol.paramRange)), " +
    "returnType: \(printType(symbol.returnType)), " +
    "isStatic: \(symbol.isStatic), " +
    "visibility: \(symbol.visibility), " +
    "withinClass: \(stringifyOptionalInt(symbol.withinClass)), " +
    "overridedBy: \(symbol.overridedBy), " +
    "finishedInit: \(symbol.finishedInit), " +
    "isConstructor: \(symbol.isConstructor)"
}
internal func printClassInfo(_ symbol: ClassSymbol) -> String {
    "displayName: \(symbol.displayName), " +
    "nonSignatureName: \(symbol.nonSignatureName), " +
    "builtin: \(symbol.builtin), " +
    "runtimeId: \(symbol.runtimeId), " +
    "depth: \(stringifyOptionalInt(symbol.depth)), " +
    "parentOf: \(symbol.parentOf)), " +
    "upperClass: \(stringifyOptionalInt(symbol.upperClass)), " +
    "classScopeSymbolTableIndex: \(stringifyOptionalInt(symbol.classScopeSymbolTableIndex))"
}
internal func printClassNameInfo(_ symbol: ClassNameSymbol) -> String {
    "builtin: \(symbol.builtin)"
}
