protocol Symbol {
    var id: Int { get set }
    var name: String { get set }
}
protocol FunctionLikeSymbol: Symbol {
    var returnType: QsType { get set }
    func getParamCount() -> Int
    func getUnderlyingFunctionStmt() -> FunctionStmt
}

enum SymbolType {
    case Variable, Function, Class
}
enum VariableStatus {
    case uninit, initing, globalIniting, finishedInit
}

class VariableSymbol: Symbol {
    init(id: Int, type: QsType? = nil, name: String, variableStatus: VariableStatus) {
        self.id = id
        self.type = type
        self.name = name
        self.variableStatus = variableStatus
    }
    
    var id: Int
    var type: QsType?
    var name: String
    var variableStatus: VariableStatus
}
class GlobalVariableSymbol: VariableSymbol {
    init(id: Int, type: QsType? = nil, name: String, globalDefiningAssignExpr: AssignExpr, variableStatus: VariableStatus) {
        self.globalDefiningAssignExpr = globalDefiningAssignExpr
        super.init(id: id, type: type, name: name, variableStatus: variableStatus)
    }
    
    var globalDefiningAssignExpr: AssignExpr
}
class FunctionNameSymbol: Symbol {
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
class FunctionSymbol: FunctionLikeSymbol {
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
class MethodSymbol: FunctionLikeSymbol {
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
class ClassSymbol: Symbol {
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
class ClassNameSymbol: Symbol {
    init(id: Int, name: String) {
        self.id = id
        self.name = name
    }
    
    var id: Int
    var name: String
}
