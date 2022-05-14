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

struct VariableSymbolInfo: SymbolInfo {
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
}
