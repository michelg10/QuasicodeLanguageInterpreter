public struct InterpreterLocation: Equatable, Comparable {
    public static func < (lhs: InterpreterLocation, rhs: InterpreterLocation) -> Bool {
        return lhs.index < rhs.index
    }
    
    public static func == (lhs: InterpreterLocation, rhs: InterpreterLocation) -> Bool {
        return lhs.index == rhs.index
    }
    
    public var index: Int
    public var row: Int
    public var column: Int
    public var logicalRow: Int
    public var logicalColumn: Int
    
    public init(index: Int, row: Int, column: Int, logicalRow: Int, logicalColumn: Int) {
        self.index = index
        self.row = row
        self.column = column
        self.logicalRow = logicalRow
        self.logicalColumn = logicalColumn
    }
    init(start: Token) {
        self = start.startLocation
    }
    init(end: Token) {
        self = end.endLocation
    }
    public static func dub() -> InterpreterLocation {
        return .init(index: -1, row: -1, column: -1, logicalRow: -1, logicalColumn: -1)
    }
    
    func offsetByOnSameLine(_ offset: Int) -> InterpreterLocation {
        return .init(index: index + offset, row: row, column: column + offset, logicalRow: logicalRow, logicalColumn: logicalColumn + offset)
    }
}
