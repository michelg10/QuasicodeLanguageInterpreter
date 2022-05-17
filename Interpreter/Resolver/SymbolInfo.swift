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
struct FunctionSymbolInfo: SymbolInfo {
    // multiple overrided functions are under the same signature
    var id: Int
    var name: String
}

struct ClassSymbolInfo: SymbolInfo {
    var id: Int
    var name: String
    var classId: Int
}
