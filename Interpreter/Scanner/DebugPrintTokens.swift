func debugPrintTokens(tokens: [Token]) {
    for i in 0..<tokens.count {
        print(tokens[i].tokenType, terminator: " ")
        if tokens[i].value != nil {
            print(tokens[i].value!, terminator: " ")
        }
        if tokens[i].tokenType == .EOL {
            print("")
        }
    }
    print("")
}
