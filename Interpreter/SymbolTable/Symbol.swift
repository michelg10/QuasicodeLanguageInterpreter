protocol Symbol {
    var id: Int { get set }
    var belongsToTable: Int { get set }
    var name: String { get }
}
protocol FunctionLikeSymbol: Symbol {
    var returnType: QsType { get set }
    var paramRange: ClosedRange<Int> { get }
    var functionParams: [FunctionParam] { get set }
}

enum VariableStatus {
    case uninit, initing, globalIniting, fieldIniting, finishedInit
}
enum VariableType {
    case global, local, instance, staticVar
}

class VariableSymbol: Symbol {
    init(type: QsType? = nil, name: String, variableStatus: VariableStatus, variableType: VariableType) {
        self.id = -1
        self.belongsToTable = -1
        self.type = type
        self.name = name
        self.variableStatus = variableStatus
        self.variableType = variableType
    }
    
    var id: Int
    var belongsToTable: Int
    var type: QsType?
    let name: String
    var variableStatus: VariableStatus
    var variableType: VariableType
}
class GlobalVariableSymbol: VariableSymbol {
    init(type: QsType? = nil, name: String, globalDefiningAssignExpr: AssignExpr, variableStatus: VariableStatus) {
        self.globalDefiningAssignExpr = globalDefiningAssignExpr
        super.init(type: type, name: name, variableStatus: variableStatus, variableType: .global)
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
    let name: String
    var belongingFunctions: [Int]
}
func getParamRangeForFunction(functionStmt: FunctionStmt) -> ClosedRange<Int> {
    var lowerBound = functionStmt.params.count
    for i in 0..<functionStmt.params.count {
        let index = functionStmt.params.count-i-1
        if functionStmt.params[index].initializer != nil {
            lowerBound=index
        }
    }
    return lowerBound...functionStmt.params.count
}
struct FunctionParam {
    var name: String
    var type: QsType
}
class FunctionSymbol: FunctionLikeSymbol {
    init(name: String, functionStmt: FunctionStmt, returnType: QsType) {
        self.id = -1
        self.belongsToTable = -1
        self.name = name
        self.functionStmt = functionStmt
        self.returnType = returnType
        self.paramRange = getParamRangeForFunction(functionStmt: functionStmt)
        self.functionParams = []
    }
    
    init(name: String, functionParams: [FunctionParam], paramRange: ClosedRange<Int>, returnType: QsType) {
        self.id = -1
        self.belongsToTable = -1
        self.name = name
        self.functionParams = functionParams
        self.paramRange = paramRange
        self.returnType = returnType
        self.functionStmt = nil
    }
    
    var id: Int
    var belongsToTable: Int
    let name: String
    let functionStmt: FunctionStmt?
    var functionParams: [FunctionParam]
    let paramRange: ClosedRange<Int>
    var returnType: QsType
}
class MethodSymbol: FunctionLikeSymbol {
    init(name: String, withinClass: Int, overridedBy: [Int], methodStmt: MethodStmt, returnType: QsType, finishedInit: Bool, isConstructor: Bool) {
        self.id = -1
        self.belongsToTable = -1
        self.name = name
        self.withinClass = withinClass
        self.overridedBy = overridedBy
        self.methodStmt = methodStmt
        self.paramRange = getParamRangeForFunction(functionStmt: methodStmt.function)
        self.returnType = returnType
        self.finishedInit = finishedInit
        self.isConstructor = isConstructor
        self.isStatic = methodStmt.isStatic
        self.visibility = methodStmt.visibilityModifier
        self.functionParams = []
    }
    
    init(name: String, withinClass: Int, overridedBy: [Int], isStatic: Bool, visibility: VisibilityModifier, functionParams: [FunctionParam], paramRange: ClosedRange<Int>, returnType: QsType, isConstructor: Bool) {
        self.id = -1
        self.belongsToTable = -1
        self.name = name
        self.withinClass = withinClass
        self.overridedBy = overridedBy
        self.methodStmt = nil
        self.isStatic = isStatic
        self.visibility = visibility
        self.functionParams = functionParams
        self.paramRange = paramRange
        self.returnType = returnType
        self.finishedInit = true
        self.isConstructor = isConstructor
    }
    
    var id: Int
    var belongsToTable: Int
    let name: String
    let withinClass: Int
    var overridedBy: [Int]
    let methodStmt: MethodStmt?
    let isStatic: Bool
    let visibility: VisibilityModifier
    var functionParams: [FunctionParam]
    let paramRange: ClosedRange<Int>
    var returnType: QsType
    var finishedInit: Bool
    let isConstructor: Bool
}
class ClassChain {
    init(upperClass: Int?, depth: Int, classStmt: ClassStmt, parentOf: [Int]) {
        self.upperClass = upperClass
        self.classStmt = classStmt
        self.parentOf = parentOf
        self.depth = depth
    }
    
    var upperClass: Int?
    var depth: Int
    var classStmt: ClassStmt
    var parentOf: [Int]
}
class ClassSymbol: Symbol {
    init(name: String, classId: Int, classChain: ClassChain?, classStmt: ClassStmt) {
        self.id = -1
        self.belongsToTable = -1
        self.name = name
        self.nonSignatureName = classStmt.name.lexeme
        if classStmt.expandedTemplateParameters == nil || classStmt.expandedTemplateParameters!.count == 0 {
            displayName = classStmt.name.lexeme
        } else {
            displayName = name
        }
        self.classId = classId
        self.classChain = classChain
        self.classStmt = classStmt
    }
    
    var id: Int
    var belongsToTable: Int
    let name: String // is actually its signature
    let displayName: String
    let nonSignatureName: String
    var classId: Int
    var classChain: ClassChain?
    var classStmt: ClassStmt
//    let instanceMethods: [] // idk what yet
//    let classMethods: []
    
}
class ClassNameSymbol: Symbol {
    init(name: String) {
        self.id = -1
        self.belongsToTable = -1
        self.name = name
    }
    
    var id: Int
    var belongsToTable: Int
    let name: String
}
