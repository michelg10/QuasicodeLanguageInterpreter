internal func debugPrintTokens(tokens: [Token], printLocation: Bool) {
    for i in 0..<tokens.count {
        print(
            tokens[i].tokenType,
            "(",
            "(i\(tokens[i].startLocation.index), r\(tokens[i].startLocation.row), c\(tokens[i].startLocation.column), lr\(tokens[i].startLocation.logicalRow), lc\(tokens[i].startLocation.logicalColumn))",
            " -> ",
            "(i\(tokens[i].endLocation.index), r\(tokens[i].endLocation.row), c\(tokens[i].endLocation.column), lr\(tokens[i].endLocation.logicalRow), lc\(tokens[i].endLocation.logicalColumn))",
            separator: "",
            terminator: " "
        )
        if tokens[i].value != nil {
            print(tokens[i].value!, terminator: " ")
        }
        if tokens[i].tokenType == .EOL {
            print("")
        }
    }
    print("")
}
