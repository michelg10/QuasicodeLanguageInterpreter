public class SymbolTables {
    private class SymbolTable {
        let id: Int
        var parent: SymbolTable?
        var childTables: [SymbolTable] = []
        private var table: [String : Symbol] = [:]
        private var allSymbolsCache: [Symbol]?
        init(parent: SymbolTable?, id: Int) {
            self.parent = parent
            self.id = id
        }
        
        public func queryTable(name: String) -> Symbol? {
            return table[name]
        }
        public func addToTable(symbol: Symbol) {
            if allSymbolsCache != nil {
                allSymbolsCache!.append(symbol)
            }
            table[symbol.name] = symbol
        }
        public func linkTableToParent(_ parent: SymbolTable) {
            self.parent = parent
        }
        public func getAllSymbolsInTable() -> [Symbol] {
            if allSymbolsCache == nil {
                allSymbolsCache = []
                for symbol in table.values {
                    allSymbolsCache!.append(symbol)
                }
            }
            return allSymbolsCache!
        }
    }
    private var allSymbols: [Symbol] = []
    private var tables: [SymbolTable] = []
    private var current: SymbolTable
    private var classRuntimeIdCount = 0
    private var classSymbolTableIndexToRuntimeIdDict: [Int : Int] = [:]
    public func getClassRuntimeIdCount() -> Int {
        return classRuntimeIdCount
    }
    public func getClassRuntimeId(symbolTableIndex: Int) -> Int {
        return classSymbolTableIndexToRuntimeIdDict[symbolTableIndex]!
    }
    
    public func getClassSymbolTableIndexToRuntimeIdDict() -> [Int : Int] {
        return classSymbolTableIndexToRuntimeIdDict
    }
    
    public func getClassesRuntimeIdToClassNameArray() -> [String] {
        var result = Array(repeating: "", count: getClassRuntimeIdCount() + 1)
        classSymbolTableIndexToRuntimeIdDict.forEach { key, value in
            let symbol = getSymbol(id: key) as! ClassSymbol
            result[value] = symbol.displayName
        }
        return result
    }
    
    public init() {
        current = .init(parent: nil, id: 0)
        tables.append(current)
    }
    
    public func getAllSymbolsAtCurrentTable() -> [Symbol] {
        return current.getAllSymbolsInTable()
    }
    
    public func resetScope() {
        current = tables[0]
    }
    
    public func createTableAtScope() -> Int {
        let newTable: SymbolTable = .init(parent: current, id: tables.count)
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
    
    private func exitScope() {
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
        while queryingTable != nil {
            if let result = queryingTable!.queryTable(name: name) {
                return result
            }
            queryingTable = queryingTable?.parent
        }
        return nil
    }
    
    public func getSymbolIndex(name: String) -> Int? {
        query(name)?.id
    }
    
    public func addToSymbolTable(symbol: Symbol) -> Int {
        var newSymbol = symbol
        newSymbol.id = allSymbols.count
        newSymbol.belongsToTable = current.id
        if newSymbol is ClassSymbol {
            classRuntimeIdCount += 1
            classSymbolTableIndexToRuntimeIdDict[newSymbol.id] = classRuntimeIdCount
            (newSymbol as! ClassSymbol).runtimeId = classRuntimeIdCount
        }
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
    
    public func getCurrentTableId() -> Int {
        return current.id
    }
    
    public func getAllMethods(methodName: String) -> [Int] {
        let currentSymbolTableState = getCurrentTableId()
        var allMethods: [Int] = []
        while true {
            let functionNameSymbol = query("#FuncName#\(methodName)")
            if functionNameSymbol == nil {
                break
            } else {
                let functionNameSymbol = functionNameSymbol as! FunctionNameSymbol
                if functionNameSymbol.isForMethods {
                    allMethods.append(contentsOf: functionNameSymbol.belongingFunctions)
                    gotoTable(functionNameSymbol.belongsToTable)
                    exitScope()
                } else {
                    break
                }
            }
        }
        gotoTable(currentSymbolTableState)
        return allMethods
    }
    
    public func linkCurrentTableToParent(_ parent: Int) {
        current.linkTableToParent(tables[parent])
    }
    
    public func printTable() {
        var tableToPrint: [[String]] = []
        for symbol in allSymbols {
            tableToPrint.append(printSymbol(symbol: symbol))
        }
        if tableToPrint.isEmpty {
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
                let isLastColumn = (i == row.count - 1)
                var output = ""
                let whitespaceCount = lengths[i] - row[i].count
                if i == 0 {
                    // its the ID, deal with it separately
                    for _ in 0..<whitespaceCount {
                        output += "0"
                    }
                    output += row[i]
                } else {
                    output = row[i]
                    for _ in 0 ..< whitespaceCount {
                        output += " "
                    }
                }
                print(output, terminator: (isLastColumn ? "\n" : " | "))
            }
        }
    }
}
