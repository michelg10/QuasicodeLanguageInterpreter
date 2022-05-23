func stringifyOptionalInt(_ val: Int?) -> String {
    return (val == nil ? "nil" : String(val!))
}
func stringifyOptionalIntArray(_ val: [Int]?) -> String {
    return (val == nil ? "nil" : val!.description)
}
