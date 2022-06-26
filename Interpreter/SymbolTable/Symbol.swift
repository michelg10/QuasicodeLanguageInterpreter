protocol Symbol {
    var id: Int { get set }
    var belongsToTable: Int { get set }
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
    case uninit, initing, globalIniting, fieldIniting, finishedInit
}

class VariableSymbol: Symbol {
    init(type: QsType? = nil, name: String, variableStatus: VariableStatus, isInstanceVariable: Bool) {
        self.id = -1
        self.belongsToTable = -1
        self.type = type
        self.name = name
        self.variableStatus = variableStatus
        self.isInstanceVariable = isInstanceVariable
    }
    
    var id: Int
    var belongsToTable: Int
    var type: QsType?
    var name: String
    var variableStatus: VariableStatus
    var isInstanceVariable: Bool
}
class GlobalVariableSymbol: VariableSymbol {
    init(type: QsType? = nil, name: String, globalDefiningAssignExpr: AssignExpr, variableStatus: VariableStatus) {
        self.globalDefiningAssignExpr = globalDefiningAssignExpr
        super.init(type: type, name: name, variableStatus: variableStatus, isInstanceVariable: false)
    }
    
    var globalDefiningAssignExpr: AssignExpr
}
class FunctionNameSymbol: Symbol {
    // Represents a collection of functions underneath the same name, in the same scope
    init(isForMethods: Bool, name: String, belongingFunctions: [Int]) {
        self.id = -1
        self.belongsToTable = -1
        self.isForMethods = isForMethods
        self.name = name
        self.belongingFunctions = belongingFunctions
    }
    
    // multiple overloaded functions are under the same signature
    var id: Int
    var belongsToTable: Int
    var isForMethods: Bool
    var name: String
    var belongingFunctions: [Int]
}
class FunctionSymbol: FunctionLikeSymbol {
    init(name: String, functionStmt: FunctionStmt, returnType: QsType) {
        self.id = -1
        self.belongsToTable = -1
        self.name = name
        self.functionStmt = functionStmt
        self.returnType = returnType
    }
    
    var id: Int
    var belongsToTable: Int
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
    init(name: String, withinClass: Int, overridedBy: [Int], methodStmt: MethodStmt, returnType: QsType, finishedInit: Bool) {
        self.id = -1
        self.belongsToTable = -1
        self.name = name
        self.withinClass = withinClass
        self.overridedBy = overridedBy
        self.methodStmt = methodStmt
        self.returnType = returnType
        self.finishedInit = finishedInit
    }
    
    var id: Int
    var belongsToTable: Int
    var name: String
    var withinClass: Int
    var overridedBy: [Int]
    var methodStmt: MethodStmt
    var returnType: QsType
    var finishedInit: Bool
    
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
    init(name: String, classId: Int, classChain: ClassChain?, classStmt: ClassStmt) {
        self.id = -1
        self.belongsToTable = -1
        self.name = name
        self.classId = classId
        self.classChain = classChain
        self.classStmt = classStmt
    }
    
    var id: Int
    var belongsToTable: Int
    var name: String
    var classId: Int
    var classChain: ClassChain?
    var classStmt: ClassStmt
}
class ClassNameSymbol: Symbol {
    init(name: String) {
        self.id = -1
        self.belongsToTable = -1
        self.name = name
    }
    
    var id: Int
    var belongsToTable: Int
    var name: String
}
