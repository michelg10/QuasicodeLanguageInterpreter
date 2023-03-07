internal func stringifyOptionalInt(_ val: Int?) -> String {
    return (val == nil ? "nil" : String(val!))
}
internal func stringifyOptionalIntArray(_ val: [Int]?) -> String {
    return (val == nil ? "nil" : val!.description)
}
