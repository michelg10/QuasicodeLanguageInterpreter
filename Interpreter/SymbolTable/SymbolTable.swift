class SymbolTables {
    class SymbolTable {
        var parent: SymbolTable?
        var childTables: [SymbolTable] = []
        var table: [String : SymbolInfo] = [:]
        init(parent: SymbolTable?) {
            self.parent = parent
        }
    }
    private var allSymbols: [SymbolInfo] = []
    private let rootTable: SymbolTable
    private var current: SymbolTable
    init() {
        rootTable = .init(parent: nil)
        current = rootTable
    }
    
    public func resetScope() {
        current = rootTable
    }
    
    public func createTableAtScope() -> Int {
        current.childTables.append(.init(parent: current))
        return current.childTables.count-1
    }
    
    public func createAndEnterScope() -> Int {
        let index = createTableAtScope()
        gotoSubTable(index)
        return index
    }
    
    public func gotoSubTable(_ index: Int) {
        current = current.childTables[index]
    }
    
    public func exitScope() {
        current = current.parent!
    }
    
    private func queryTable(table: SymbolTable, name: String) -> SymbolInfo? {
        return table.table[name]
    }
    
    public func queryAtScope(_ name: String) -> SymbolInfo? {
        return current.table[name]
    }
    
    public func queryGlobal(_ name: String) -> SymbolInfo? {
        return queryTable(table: rootTable, name: name)
    }
    
    public func query(_ name: String) -> SymbolInfo? {
        var queryingTable: SymbolTable? = current
        while (queryingTable != nil) {
            if let result = queryTable(table: queryingTable!, name: name) {
                return result
            }
            queryingTable = queryingTable?.parent
        }
        return nil
    }
    
    public func getSymbolIndex(name: String) -> Int? {
        return query(name)?.id ?? nil
    }
    
    public func addToSymbolTable(symbol: SymbolInfo) -> Int {
        var newSymbol = symbol
        newSymbol.id = allSymbols.count
        allSymbols.append(symbol)
        current.table[newSymbol.name] = newSymbol
        return newSymbol.id
    }
    
    public func getSymbol(id: Int) -> SymbolInfo {
        return allSymbols[id]
    }
    
    public func getAllSymbols() -> [SymbolInfo] {
        return allSymbols
    }
    
}
