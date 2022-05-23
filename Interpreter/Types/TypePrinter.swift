func printType(_ value: QsType?) -> String {
    if value == nil {
        return "nil"
    }
    // reserve non-negative numbers for class IDs
    switch value! {
    case is QsInt:
        return "<Int>"
    case is QsDouble:
        return "<Double>"
    case is QsBoolean:
        return "<Boolean>"
    case is QsAnyType:
        return "<Any>"
    case is QsClass:
        return "<Class \((value as! QsClass).id)>"
    case is QsArray:
        return "<Array(contains: \(printType(value)))>"
    case is QsFunction:
        return "<Function \((value as! QsFunction).nameId)>"
    default:
        return "<Unknown \"\(type(of: value))\">"
    }
}
