protocol SymbolInfo {
    var id: Int { get set }
    var name: String { get set }
}
protocol FunctionLikeSymbol: SymbolInfo {
    var returnType: QsType { get set }
    func getParamCount() -> Int
    func getUnderlyingFunctionStmt() -> FunctionStmt
}

enum SymbolType {
    case Variable, Function, Class
}
enum GlobalStatus {
    case uninit, initing, finishedInit
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
class GlobalVariableSymbolInfo: VariableSymbolInfo {
    init(id: Int, type: QsType? = nil, name: String, globalDefiningAssignExpr: AssignExpr, globalStatus: GlobalStatus) {
        self.globalDefiningAssignExpr = globalDefiningAssignExpr
        self.globalStatus = globalStatus
        super.init(id: id, type: type, name: name)
    }
    
    var globalDefiningAssignExpr: AssignExpr
    var globalStatus: GlobalStatus
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
class FunctionSymbolInfo: FunctionLikeSymbol {
    init(id: Int, name: String, functionStmt: FunctionStmt, returnType: QsType) {
        self.id = id
        self.name = name
        self.functionStmt = functionStmt
        self.returnType = returnType
    }
    
    var id: Int
    var name: String
    var functionStmt: FunctionStmt
    var returnType: QsType
    
    func getParamCount() -> Int {
        return functionStmt.params.count
    }
    
    func getUnderlyingFunctionStmt() -> FunctionStmt {
        return functionStmt
    }
}
class MethodSymbolInfo: FunctionLikeSymbol {
    init(id: Int, name: String, withinClass: Int, overridedBy: [Int], methodStmt: MethodStmt, returnType: QsType) {
        self.id = id
        self.name = name
        self.withinClass = withinClass
        self.overridedBy = overridedBy
        self.methodStmt = methodStmt
        self.returnType = returnType
    }
    
    var id: Int
    var name: String
    var withinClass: Int
    var overridedBy: [Int]
    var methodStmt: MethodStmt
    var returnType: QsType
    
    func getParamCount() -> Int {
        return methodStmt.function.params.count
    }
    
    func getUnderlyingFunctionStmt() -> FunctionStmt {
        return methodStmt.function
    }
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
