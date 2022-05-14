func catchErrorClosure<T>(_ closure: () throws -> T) -> T? {
    do {
        return try closure()
    } catch {
        
    }
    return nil
}
