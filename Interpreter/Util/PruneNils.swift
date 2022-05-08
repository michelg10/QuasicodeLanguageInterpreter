func pruneNils<T>(_ array: [T?]) -> [T] {
    var result: [T] = []
    result.reserveCapacity(array.count)
    for item in array {
        if item != nil {
            result.append(item!)
        }
    }
    return result
}
