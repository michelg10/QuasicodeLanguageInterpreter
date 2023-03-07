internal func debugPrint(purpose: String, _ message: String) {
    #if DEBUG
        print("[DEBUG][\(purpose)] \(message)")
    #endif
}
