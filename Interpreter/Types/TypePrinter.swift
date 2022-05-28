func printType(_ value: QsType?) -> String {
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
        return "[\(printType(value))]"
    case is QsFunction:
        return "Function(\((value as! QsFunction).nameId))"
    default:
        return "<Unknown \"\(type(of: value))\">"
    }
}
