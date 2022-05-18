enum SymbolLocation {
    case Global, Local, Field(String), StaticField(String)
}

protocol SymbolInfo {
    var id: Int { get set }
    var name: String { get set }
}

enum SymbolType {
    case Variable, Function, Class
}

class VariableSymbolInfo: SymbolInfo {
    init(id: Int, type: QsType? = nil, name: String, symbolLocation: SymbolLocation) {
        self.id = id
        self.type = type
        self.name = name
        self.symbolLocation = symbolLocation
    }
    
    var id: Int
    var type: QsType?
    var name: String
    var symbolLocation: SymbolLocation
}
class FunctionNameSymbolInfo: SymbolInfo {
    init(id: Int, name: String, belongingFunctions: [Int]) {
        self.id = id
        self.name = name
        self.belongingFunctions = belongingFunctions
    }
    
    // multiple overrided functions are under the same signature
    var id: Int
    var name: String
    var belongingFunctions: [Int]
}
class FunctionSymbolInfo: SymbolInfo {
    init(id: Int, name: String, parameters: [QsType], functionStmt: FunctionStmt) {
        self.id = id
        self.name = name
        self.parameters = parameters
        self.functionStmt = functionStmt
    }
    
    var id: Int
    var name: String
    var parameters: [QsType]
    var functionStmt: FunctionStmt
}
class ClassSymbolInfo: SymbolInfo {
    init(id: Int, name: String, classId: Int) {
        self.id = id
        self.name = name
        self.classId = classId
    }
    
    var id: Int
    var name: String
    var classId: Int
}
