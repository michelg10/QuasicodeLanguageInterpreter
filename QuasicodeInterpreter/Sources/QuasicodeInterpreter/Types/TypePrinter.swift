internal func printType(_ value: QsType?) -> String {
    if value == nil {
        return "nil"
    }
    // reserve non-negative numbers for class IDs
    switch value! {
    case is QsInt:
        return "int"
    case is QsDouble:
        return "double"
    case is QsBoolean:
        return "boolean"
    case is QsAnyType:
        return "any"
    case is QsClass:
        return "\((value as! QsClass).name)"
    case is QsArray:
        return "[\(printType((value as! QsArray).contains))]"
    case is QsErrorType:
        return "<Error>"
    case is QsVoidType:
        return "<Void>"
    default:
        return "<Unknown \"\(type(of: value))\">"
    }
}
