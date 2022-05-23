protocol SymbolInfo {
    var id: Int { get set }
    var name: String { get set }
}

enum SymbolType {
    case Variable, Function, Class
}

class VariableSymbolInfo: SymbolInfo {
    init(id: Int, type: QsType? = nil, name: String) {
        self.id = id
        self.type = type
        self.name = name
    }
    
    var id: Int
    var type: QsType?
    var name: String
}
class FunctionNameSymbolInfo: SymbolInfo {
    // Represents a collection of functions underneath the same name, in the same scope
    init(id: Int, name: String, belongingFunctions: [Int]) {
        self.id = id
        self.name = name
        self.belongingFunctions = belongingFunctions
    }
    
    // multiple overloaded functions are under the same signature
    var id: Int
    var name: String
    var belongingFunctions: [Int]
}
class FunctionSymbolInfo: SymbolInfo {
    init(id: Int, name: String, parameters: [QsType], functionStmt: FunctionStmt, withinClass: Int?, overridedBy: [Int]) {
        self.id = id
        self.name = name
        self.parameters = parameters
        self.functionStmt = functionStmt
        self.withinClass = withinClass
        self.overridedBy = overridedBy
    }
    
    var id: Int
    var name: String
    var parameters: [QsType]
    var functionStmt: FunctionStmt
    var withinClass: Int?
    var overridedBy: [Int]
}
class ClassChain {
    init(upperClass: Int, depth: Int, classStmt: ClassStmt, parentOf: [Int]) {
        self.upperClass = upperClass
        self.classStmt = classStmt
        self.parentOf = parentOf
        self.depth = depth
    }
    
    var upperClass: Int
    var depth: Int
    var classStmt: ClassStmt
    var parentOf: [Int]
}
class ClassSymbolInfo: SymbolInfo {
    init(id: Int, name: String, classId: Int, classChain: ClassChain?) {
        self.id = id
        self.name = name
        self.classId = classId
        self.classChain = classChain
    }
    
    var id: Int
    var name: String
    var classId: Int
    var classChain: ClassChain?
}
class ClassNameSymbolInfo: SymbolInfo {
    init(id: Int, name: String) {
        self.id = id
        self.name = name
    }
    
    var id: Int
    var name: String
}
