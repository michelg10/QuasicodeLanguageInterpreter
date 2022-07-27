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
    return [String(symbol.id), String(symbol.belongsToTable), String(symbol.name), symbolType, result]
}
func printGlobalVariableInfo(_ symbol: GlobalVariableSymbol) -> String {
    return printVariableInfo(symbol)
}
func printVariableInfo(_ symbol: VariableSymbol) -> String {
    return "type: \(printType(symbol.type)), status: \(symbol.variableStatus), variableType: \(symbol.variableType)"
}
func printFunctionNameInfo(_ symbol: FunctionNameSymbol) -> String {
    return "belongingFunctions: \(symbol.belongingFunctions), isForMethods: \(symbol.isForMethods)"
}
func debugClosedIntRangeToString(_ range: ClosedRange<Int>) -> String {
    return "\(range.lowerBound)...\(range.upperBound)"
}
func debugFunctionParamsToString(_ functionParams: [FunctionParam]) -> String {
    return "["+functionParams.reduce("") { partialResult, functionParam in
        var nextResult = partialResult
        if nextResult != "" {
            nextResult += ", "
        }
        nextResult+="\(functionParam.name): \(printType(functionParam.type))"
        return nextResult
    }+"]"
}
func printFunctionInfo(_ symbol: FunctionSymbol) -> String {
    return "functionParams: \(debugFunctionParamsToString(symbol.functionParams)), paramRange: \(debugClosedIntRangeToString(symbol.paramRange)), returnType: \(printType(symbol.returnType))"
}
func printMethodInfo(_ symbol: MethodSymbol) -> String {
    return "functionParams: \(debugFunctionParamsToString(symbol.functionParams)), paramRange: \(debugClosedIntRangeToString(symbol.paramRange)), returnType: \(printType(symbol.returnType)), isStatic: \(symbol.isStatic), visibility: \(symbol.visibility), withinClass: \(stringifyOptionalInt(symbol.withinClass)), overridedBy: \(symbol.overridedBy), finishedInit: \(symbol.finishedInit), isConstructor: \(symbol.isConstructor)"
}
func printClassInfo(_ symbol: ClassSymbol) -> String {
    return "displayName: \(symbol.displayName), nonSignatureName: \(symbol.nonSignatureName), classId: \(symbol.classId), depth: \(stringifyOptionalInt(symbol.classChain?.depth)), parentOf: \(stringifyOptionalIntArray(symbol.classChain?.parentOf)), upperClass: \(stringifyOptionalInt(symbol.classChain?.upperClass)), classScopeSymbolTableIndex: \(stringifyOptionalInt(symbol.classScopeSymbolTableIndex))"
}
func printClassNameInfo(_ symbol: ClassNameSymbol) -> String {
    return ""
}
