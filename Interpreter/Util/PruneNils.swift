func pruneNils<T>(_ array: [T?]) -> [T] {
    var result: [T] = []
    result.reserveCapacity(array.count)
    for item in array where item != nil {
        result.append(item!)
    }
    return result
}
