class SymbolTables {
    private class SymbolTable {
        let id: Int
        let parent: SymbolTable?
        var childTables: [SymbolTable] = []
        private var table: [String : Symbol] = [:]
        init(parent: SymbolTable?, id: Int) {
            self.parent = parent
            self.id = id
        }
        
        public func queryTable(name: String) -> Symbol? {
            return table[name]
        }
        public func addToTable(symbol: Symbol) {
            table[symbol.name] = symbol
        }
    }
    private var allSymbols: [Symbol] = []
    private var tables: [SymbolTable] = []
    private var current: SymbolTable
    init() {
        current = .init(parent: nil, id: 0)
        tables.append(current)
    }
    
    public func resetScope() {
        current = tables[0]
    }
    
    public func createTableAtScope() -> Int {
        let newTable = SymbolTable.init(parent: current, id: tables.count)
        current.childTables.append(newTable)
        tables.append(newTable)
        return newTable.id
    }
    
    public func createAndEnterScope() -> Int {
        let index = createTableAtScope()
        gotoTable(index)
        return index
    }
    
    public func gotoTable(_ index: Int) {
        current = tables[index]
    }
    
    public func exitScope() {
        current = current.parent!
    }
    
    public func queryAtScopeOnly(_ name: String) -> Symbol? {
        return current.queryTable(name: name)
    }
    
    public func queryAtGlobalOnly(_ name: String) -> Symbol? {
        return tables[0].queryTable(name: name)
    }
    
    public func query(_ name: String) -> Symbol? {
        var queryingTable: SymbolTable? = current
        while (queryingTable != nil) {
            if let result = queryingTable!.queryTable(name: name) {
                return result
            }
            queryingTable = queryingTable?.parent
        }
        return nil
    }
    
    public func getSymbolIndex(name: String) -> Int? {
        return query(name)?.id ?? nil
    }
    
    public func getClassChain(id: Int) -> ClassChain? {
        return (getSymbol(id: id) as? ClassSymbol)?.classChain
    }
    
    public func addToSymbolTable(symbol: Symbol) -> Int {
        var newSymbol = symbol
        newSymbol.id = allSymbols.count
        allSymbols.append(symbol)
        current.addToTable(symbol: newSymbol)
        return newSymbol.id
    }
    
    public func getSymbol(id: Int) -> Symbol {
        return allSymbols[id]
    }
    
    public func getAllSymbols() -> [Symbol] {
        return allSymbols
    }
    
    public func printTable() {
        var tableToPrint: [[String]] = []
        for symbol in allSymbols {
            tableToPrint.append(printSymbol(symbol: symbol))
        }
        if tableToPrint.count == 0 {
            return
        }
        var lengths: [Int] = Array(repeating: 0, count: tableToPrint[0].count)
        for row in tableToPrint {
            for i in 0..<row.count {
                lengths[i] = max(lengths[i], row[i].count)
            }
        }
        
        // output it
        for row in tableToPrint {
            for i in 0..<row.count {
                let isLastColumn = i==row.count-1
                var output = ""
                let whitespaceCount = lengths[i]-row[i].count
                if i==0 {
                    // its the ID, deal with it separately
                    for j in 0..<whitespaceCount {
                        output+="0"
                    }
                    output+=row[i]
                } else {
                    output=row[i]
                    for j in 0..<whitespaceCount {
                        output+=" "
                    }
                }
                print(output, terminator: (isLastColumn ? "\n" : " | "))
            }
        }
    }
}
