protocol Expr {
    func accept(visitor: ExprVisitor)
    func accept(visitor: ExprThrowVisitor) throws
    func accept(visitor: ExprQsTypeThrowVisitor) throws -> QsType
    func accept(visitor: ExprExprThrowVisitor) throws -> Expr
    func accept(visitor: ExprStringVisitor) -> String
    var type: QsType? { get set }
    var startLocation: InterpreterLocation { get set }
    var endLocation: InterpreterLocation { get set }
}

protocol ExprVisitor {
    func visitGroupingExpr(expr: GroupingExpr) 
    func visitLiteralExpr(expr: LiteralExpr) 
    func visitArrayLiteralExpr(expr: ArrayLiteralExpr) 
    func visitStaticClassExpr(expr: StaticClassExpr) 
    func visitThisExpr(expr: ThisExpr) 
    func visitSuperExpr(expr: SuperExpr) 
    func visitVariableExpr(expr: VariableExpr) 
    func visitSubscriptExpr(expr: SubscriptExpr) 
    func visitCallExpr(expr: CallExpr) 
    func visitGetExpr(expr: GetExpr) 
    func visitUnaryExpr(expr: UnaryExpr) 
    func visitCastExpr(expr: CastExpr) 
    func visitArrayAllocationExpr(expr: ArrayAllocationExpr) 
    func visitClassAllocationExpr(expr: ClassAllocationExpr) 
    func visitBinaryExpr(expr: BinaryExpr) 
    func visitLogicalExpr(expr: LogicalExpr) 
    func visitSetExpr(expr: SetExpr) 
    func visitAssignExpr(expr: AssignExpr) 
    func visitIsTypeExpr(expr: IsTypeExpr) 
    func visitImplicitCastExpr(expr: ImplicitCastExpr) 
}

protocol ExprThrowVisitor {
    func visitGroupingExpr(expr: GroupingExpr) throws 
    func visitLiteralExpr(expr: LiteralExpr) throws 
    func visitArrayLiteralExpr(expr: ArrayLiteralExpr) throws 
    func visitStaticClassExpr(expr: StaticClassExpr) throws 
    func visitThisExpr(expr: ThisExpr) throws 
    func visitSuperExpr(expr: SuperExpr) throws 
    func visitVariableExpr(expr: VariableExpr) throws 
    func visitSubscriptExpr(expr: SubscriptExpr) throws 
    func visitCallExpr(expr: CallExpr) throws 
    func visitGetExpr(expr: GetExpr) throws 
    func visitUnaryExpr(expr: UnaryExpr) throws 
    func visitCastExpr(expr: CastExpr) throws 
    func visitArrayAllocationExpr(expr: ArrayAllocationExpr) throws 
    func visitClassAllocationExpr(expr: ClassAllocationExpr) throws 
    func visitBinaryExpr(expr: BinaryExpr) throws 
    func visitLogicalExpr(expr: LogicalExpr) throws 
    func visitSetExpr(expr: SetExpr) throws 
    func visitAssignExpr(expr: AssignExpr) throws 
    func visitIsTypeExpr(expr: IsTypeExpr) throws 
    func visitImplicitCastExpr(expr: ImplicitCastExpr) throws 
}

protocol ExprQsTypeThrowVisitor {
    func visitGroupingExprQsType(expr: GroupingExpr) throws -> QsType
    func visitLiteralExprQsType(expr: LiteralExpr) throws -> QsType
    func visitArrayLiteralExprQsType(expr: ArrayLiteralExpr) throws -> QsType
    func visitStaticClassExprQsType(expr: StaticClassExpr) throws -> QsType
    func visitThisExprQsType(expr: ThisExpr) throws -> QsType
    func visitSuperExprQsType(expr: SuperExpr) throws -> QsType
    func visitVariableExprQsType(expr: VariableExpr) throws -> QsType
    func visitSubscriptExprQsType(expr: SubscriptExpr) throws -> QsType
    func visitCallExprQsType(expr: CallExpr) throws -> QsType
    func visitGetExprQsType(expr: GetExpr) throws -> QsType
    func visitUnaryExprQsType(expr: UnaryExpr) throws -> QsType
    func visitCastExprQsType(expr: CastExpr) throws -> QsType
    func visitArrayAllocationExprQsType(expr: ArrayAllocationExpr) throws -> QsType
    func visitClassAllocationExprQsType(expr: ClassAllocationExpr) throws -> QsType
    func visitBinaryExprQsType(expr: BinaryExpr) throws -> QsType
    func visitLogicalExprQsType(expr: LogicalExpr) throws -> QsType
    func visitSetExprQsType(expr: SetExpr) throws -> QsType
    func visitAssignExprQsType(expr: AssignExpr) throws -> QsType
    func visitIsTypeExprQsType(expr: IsTypeExpr) throws -> QsType
    func visitImplicitCastExprQsType(expr: ImplicitCastExpr) throws -> QsType
}

protocol ExprExprThrowVisitor {
    func visitGroupingExprExpr(expr: GroupingExpr) throws -> Expr
    func visitLiteralExprExpr(expr: LiteralExpr) throws -> Expr
    func visitArrayLiteralExprExpr(expr: ArrayLiteralExpr) throws -> Expr
    func visitStaticClassExprExpr(expr: StaticClassExpr) throws -> Expr
    func visitThisExprExpr(expr: ThisExpr) throws -> Expr
    func visitSuperExprExpr(expr: SuperExpr) throws -> Expr
    func visitVariableExprExpr(expr: VariableExpr) throws -> Expr
    func visitSubscriptExprExpr(expr: SubscriptExpr) throws -> Expr
    func visitCallExprExpr(expr: CallExpr) throws -> Expr
    func visitGetExprExpr(expr: GetExpr) throws -> Expr
    func visitUnaryExprExpr(expr: UnaryExpr) throws -> Expr
    func visitCastExprExpr(expr: CastExpr) throws -> Expr
    func visitArrayAllocationExprExpr(expr: ArrayAllocationExpr) throws -> Expr
    func visitClassAllocationExprExpr(expr: ClassAllocationExpr) throws -> Expr
    func visitBinaryExprExpr(expr: BinaryExpr) throws -> Expr
    func visitLogicalExprExpr(expr: LogicalExpr) throws -> Expr
    func visitSetExprExpr(expr: SetExpr) throws -> Expr
    func visitAssignExprExpr(expr: AssignExpr) throws -> Expr
    func visitIsTypeExprExpr(expr: IsTypeExpr) throws -> Expr
    func visitImplicitCastExprExpr(expr: ImplicitCastExpr) throws -> Expr
}

protocol ExprStringVisitor {
    func visitGroupingExprString(expr: GroupingExpr) -> String
    func visitLiteralExprString(expr: LiteralExpr) -> String
    func visitArrayLiteralExprString(expr: ArrayLiteralExpr) -> String
    func visitStaticClassExprString(expr: StaticClassExpr) -> String
    func visitThisExprString(expr: ThisExpr) -> String
    func visitSuperExprString(expr: SuperExpr) -> String
    func visitVariableExprString(expr: VariableExpr) -> String
    func visitSubscriptExprString(expr: SubscriptExpr) -> String
    func visitCallExprString(expr: CallExpr) -> String
    func visitGetExprString(expr: GetExpr) -> String
    func visitUnaryExprString(expr: UnaryExpr) -> String
    func visitCastExprString(expr: CastExpr) -> String
    func visitArrayAllocationExprString(expr: ArrayAllocationExpr) -> String
    func visitClassAllocationExprString(expr: ClassAllocationExpr) -> String
    func visitBinaryExprString(expr: BinaryExpr) -> String
    func visitLogicalExprString(expr: LogicalExpr) -> String
    func visitSetExprString(expr: SetExpr) -> String
    func visitAssignExprString(expr: AssignExpr) -> String
    func visitIsTypeExprString(expr: IsTypeExpr) -> String
    func visitImplicitCastExprString(expr: ImplicitCastExpr) -> String
}

class GroupingExpr: Expr {
    var expression: Expr
    var type: QsType?
    var startLocation: InterpreterLocation
    var endLocation: InterpreterLocation
    
    init(expression: Expr, type: QsType?, startLocation: InterpreterLocation, endLocation: InterpreterLocation) {
        self.expression = expression
        self.type = type
        self.startLocation = startLocation
        self.endLocation = endLocation
    }
    init(_ objectToCopy: GroupingExpr) {
        self.expression = objectToCopy.expression
        self.type = objectToCopy.type
        self.startLocation = objectToCopy.startLocation
        self.endLocation = objectToCopy.endLocation
    }

    func accept(visitor: ExprVisitor) {
        visitor.visitGroupingExpr(expr: self)
    }
    func accept(visitor: ExprThrowVisitor) throws {
        try visitor.visitGroupingExpr(expr: self)
    }
    func accept(visitor: ExprQsTypeThrowVisitor) throws -> QsType {
        try visitor.visitGroupingExprQsType(expr: self)
    }
    func accept(visitor: ExprExprThrowVisitor) throws -> Expr {
        try visitor.visitGroupingExprExpr(expr: self)
    }
    func accept(visitor: ExprStringVisitor) -> String {
        visitor.visitGroupingExprString(expr: self)
    }
}

class LiteralExpr: Expr {
    var value: Any?
    var type: QsType?
    var startLocation: InterpreterLocation
    var endLocation: InterpreterLocation
    
    init(value: Any?, type: QsType?, startLocation: InterpreterLocation, endLocation: InterpreterLocation) {
        self.value = value
        self.type = type
        self.startLocation = startLocation
        self.endLocation = endLocation
    }
    init(_ objectToCopy: LiteralExpr) {
        self.value = objectToCopy.value
        self.type = objectToCopy.type
        self.startLocation = objectToCopy.startLocation
        self.endLocation = objectToCopy.endLocation
    }

    func accept(visitor: ExprVisitor) {
        visitor.visitLiteralExpr(expr: self)
    }
    func accept(visitor: ExprThrowVisitor) throws {
        try visitor.visitLiteralExpr(expr: self)
    }
    func accept(visitor: ExprQsTypeThrowVisitor) throws -> QsType {
        try visitor.visitLiteralExprQsType(expr: self)
    }
    func accept(visitor: ExprExprThrowVisitor) throws -> Expr {
        try visitor.visitLiteralExprExpr(expr: self)
    }
    func accept(visitor: ExprStringVisitor) -> String {
        visitor.visitLiteralExprString(expr: self)
    }
}

class ArrayLiteralExpr: Expr {
    var values: [Expr]
    var type: QsType?
    var startLocation: InterpreterLocation
    var endLocation: InterpreterLocation
    
    init(values: [Expr], type: QsType?, startLocation: InterpreterLocation, endLocation: InterpreterLocation) {
        self.values = values
        self.type = type
        self.startLocation = startLocation
        self.endLocation = endLocation
    }
    init(_ objectToCopy: ArrayLiteralExpr) {
        self.values = objectToCopy.values
        self.type = objectToCopy.type
        self.startLocation = objectToCopy.startLocation
        self.endLocation = objectToCopy.endLocation
    }

    func accept(visitor: ExprVisitor) {
        visitor.visitArrayLiteralExpr(expr: self)
    }
    func accept(visitor: ExprThrowVisitor) throws {
        try visitor.visitArrayLiteralExpr(expr: self)
    }
    func accept(visitor: ExprQsTypeThrowVisitor) throws -> QsType {
        try visitor.visitArrayLiteralExprQsType(expr: self)
    }
    func accept(visitor: ExprExprThrowVisitor) throws -> Expr {
        try visitor.visitArrayLiteralExprExpr(expr: self)
    }
    func accept(visitor: ExprStringVisitor) -> String {
        visitor.visitArrayLiteralExprString(expr: self)
    }
}

class StaticClassExpr: Expr {
    var classType: AstClassType
    var classId: Int?
    var type: QsType?
    var startLocation: InterpreterLocation
    var endLocation: InterpreterLocation
    
    init(classType: AstClassType, classId: Int?, type: QsType?, startLocation: InterpreterLocation, endLocation: InterpreterLocation) {
        self.classType = classType
        self.classId = classId
        self.type = type
        self.startLocation = startLocation
        self.endLocation = endLocation
    }
    init(_ objectToCopy: StaticClassExpr) {
        self.classType = objectToCopy.classType
        self.classId = objectToCopy.classId
        self.type = objectToCopy.type
        self.startLocation = objectToCopy.startLocation
        self.endLocation = objectToCopy.endLocation
    }

    func accept(visitor: ExprVisitor) {
        visitor.visitStaticClassExpr(expr: self)
    }
    func accept(visitor: ExprThrowVisitor) throws {
        try visitor.visitStaticClassExpr(expr: self)
    }
    func accept(visitor: ExprQsTypeThrowVisitor) throws -> QsType {
        try visitor.visitStaticClassExprQsType(expr: self)
    }
    func accept(visitor: ExprExprThrowVisitor) throws -> Expr {
        try visitor.visitStaticClassExprExpr(expr: self)
    }
    func accept(visitor: ExprStringVisitor) -> String {
        visitor.visitStaticClassExprString(expr: self)
    }
}

class ThisExpr: Expr {
    var keyword: Token
    var symbolTableIndex: Int?
    var type: QsType?
    var startLocation: InterpreterLocation
    var endLocation: InterpreterLocation
    
    init(keyword: Token, symbolTableIndex: Int?, type: QsType?, startLocation: InterpreterLocation, endLocation: InterpreterLocation) {
        self.keyword = keyword
        self.symbolTableIndex = symbolTableIndex
        self.type = type
        self.startLocation = startLocation
        self.endLocation = endLocation
    }
    init(_ objectToCopy: ThisExpr) {
        self.keyword = objectToCopy.keyword
        self.symbolTableIndex = objectToCopy.symbolTableIndex
        self.type = objectToCopy.type
        self.startLocation = objectToCopy.startLocation
        self.endLocation = objectToCopy.endLocation
    }

    func accept(visitor: ExprVisitor) {
        visitor.visitThisExpr(expr: self)
    }
    func accept(visitor: ExprThrowVisitor) throws {
        try visitor.visitThisExpr(expr: self)
    }
    func accept(visitor: ExprQsTypeThrowVisitor) throws -> QsType {
        try visitor.visitThisExprQsType(expr: self)
    }
    func accept(visitor: ExprExprThrowVisitor) throws -> Expr {
        try visitor.visitThisExprExpr(expr: self)
    }
    func accept(visitor: ExprStringVisitor) -> String {
        visitor.visitThisExprString(expr: self)
    }
}

class SuperExpr: Expr {
    var keyword: Token
    var property: Token
    var symbolTableIndex: Int?
    var propertyId: Int?
    var type: QsType?
    var startLocation: InterpreterLocation
    var endLocation: InterpreterLocation
    
    init(keyword: Token, property: Token, symbolTableIndex: Int?, propertyId: Int?, type: QsType?, startLocation: InterpreterLocation, endLocation: InterpreterLocation) {
        self.keyword = keyword
        self.property = property
        self.symbolTableIndex = symbolTableIndex
        self.propertyId = propertyId
        self.type = type
        self.startLocation = startLocation
        self.endLocation = endLocation
    }
    init(_ objectToCopy: SuperExpr) {
        self.keyword = objectToCopy.keyword
        self.property = objectToCopy.property
        self.symbolTableIndex = objectToCopy.symbolTableIndex
        self.propertyId = objectToCopy.propertyId
        self.type = objectToCopy.type
        self.startLocation = objectToCopy.startLocation
        self.endLocation = objectToCopy.endLocation
    }

    func accept(visitor: ExprVisitor) {
        visitor.visitSuperExpr(expr: self)
    }
    func accept(visitor: ExprThrowVisitor) throws {
        try visitor.visitSuperExpr(expr: self)
    }
    func accept(visitor: ExprQsTypeThrowVisitor) throws -> QsType {
        try visitor.visitSuperExprQsType(expr: self)
    }
    func accept(visitor: ExprExprThrowVisitor) throws -> Expr {
        try visitor.visitSuperExprExpr(expr: self)
    }
    func accept(visitor: ExprStringVisitor) -> String {
        visitor.visitSuperExprString(expr: self)
    }
}

class VariableExpr: Expr {
    var name: Token
    var symbolTableIndex: Int?
    var type: QsType?
    var startLocation: InterpreterLocation
    var endLocation: InterpreterLocation
    
    init(name: Token, symbolTableIndex: Int?, type: QsType?, startLocation: InterpreterLocation, endLocation: InterpreterLocation) {
        self.name = name
        self.symbolTableIndex = symbolTableIndex
        self.type = type
        self.startLocation = startLocation
        self.endLocation = endLocation
    }
    init(_ objectToCopy: VariableExpr) {
        self.name = objectToCopy.name
        self.symbolTableIndex = objectToCopy.symbolTableIndex
        self.type = objectToCopy.type
        self.startLocation = objectToCopy.startLocation
        self.endLocation = objectToCopy.endLocation
    }

    func accept(visitor: ExprVisitor) {
        visitor.visitVariableExpr(expr: self)
    }
    func accept(visitor: ExprThrowVisitor) throws {
        try visitor.visitVariableExpr(expr: self)
    }
    func accept(visitor: ExprQsTypeThrowVisitor) throws -> QsType {
        try visitor.visitVariableExprQsType(expr: self)
    }
    func accept(visitor: ExprExprThrowVisitor) throws -> Expr {
        try visitor.visitVariableExprExpr(expr: self)
    }
    func accept(visitor: ExprStringVisitor) -> String {
        visitor.visitVariableExprString(expr: self)
    }
}

class SubscriptExpr: Expr {
    var expression: Expr
    var index: Expr
    var type: QsType?
    var startLocation: InterpreterLocation
    var endLocation: InterpreterLocation
    
    init(expression: Expr, index: Expr, type: QsType?, startLocation: InterpreterLocation, endLocation: InterpreterLocation) {
        self.expression = expression
        self.index = index
        self.type = type
        self.startLocation = startLocation
        self.endLocation = endLocation
    }
    init(_ objectToCopy: SubscriptExpr) {
        self.expression = objectToCopy.expression
        self.index = objectToCopy.index
        self.type = objectToCopy.type
        self.startLocation = objectToCopy.startLocation
        self.endLocation = objectToCopy.endLocation
    }

    func accept(visitor: ExprVisitor) {
        visitor.visitSubscriptExpr(expr: self)
    }
    func accept(visitor: ExprThrowVisitor) throws {
        try visitor.visitSubscriptExpr(expr: self)
    }
    func accept(visitor: ExprQsTypeThrowVisitor) throws -> QsType {
        try visitor.visitSubscriptExprQsType(expr: self)
    }
    func accept(visitor: ExprExprThrowVisitor) throws -> Expr {
        try visitor.visitSubscriptExprExpr(expr: self)
    }
    func accept(visitor: ExprStringVisitor) -> String {
        visitor.visitSubscriptExprString(expr: self)
    }
}

class CallExpr: Expr {
    var object: Expr?
    var property: Token
    var paren: Token
    var arguments: [Expr]
    var uniqueFunctionCall: Int?
    var polymorphicCallClassIdToIdDict: [Int : Int]?
    var type: QsType?
    var startLocation: InterpreterLocation
    var endLocation: InterpreterLocation
    
    init(object: Expr?, property: Token, paren: Token, arguments: [Expr], uniqueFunctionCall: Int?, polymorphicCallClassIdToIdDict: [Int : Int]?, type: QsType?, startLocation: InterpreterLocation, endLocation: InterpreterLocation) {
        self.object = object
        self.property = property
        self.paren = paren
        self.arguments = arguments
        self.uniqueFunctionCall = uniqueFunctionCall
        self.polymorphicCallClassIdToIdDict = polymorphicCallClassIdToIdDict
        self.type = type
        self.startLocation = startLocation
        self.endLocation = endLocation
    }
    init(_ objectToCopy: CallExpr) {
        self.object = objectToCopy.object
        self.property = objectToCopy.property
        self.paren = objectToCopy.paren
        self.arguments = objectToCopy.arguments
        self.uniqueFunctionCall = objectToCopy.uniqueFunctionCall
        self.polymorphicCallClassIdToIdDict = objectToCopy.polymorphicCallClassIdToIdDict
        self.type = objectToCopy.type
        self.startLocation = objectToCopy.startLocation
        self.endLocation = objectToCopy.endLocation
    }

    func accept(visitor: ExprVisitor) {
        visitor.visitCallExpr(expr: self)
    }
    func accept(visitor: ExprThrowVisitor) throws {
        try visitor.visitCallExpr(expr: self)
    }
    func accept(visitor: ExprQsTypeThrowVisitor) throws -> QsType {
        try visitor.visitCallExprQsType(expr: self)
    }
    func accept(visitor: ExprExprThrowVisitor) throws -> Expr {
        try visitor.visitCallExprExpr(expr: self)
    }
    func accept(visitor: ExprStringVisitor) -> String {
        visitor.visitCallExprString(expr: self)
    }
}

class GetExpr: Expr {
    var object: Expr
    var property: Token
    var propertyId: Int?
    var type: QsType?
    var startLocation: InterpreterLocation
    var endLocation: InterpreterLocation
    
    init(object: Expr, property: Token, propertyId: Int?, type: QsType?, startLocation: InterpreterLocation, endLocation: InterpreterLocation) {
        self.object = object
        self.property = property
        self.propertyId = propertyId
        self.type = type
        self.startLocation = startLocation
        self.endLocation = endLocation
    }
    init(_ objectToCopy: GetExpr) {
        self.object = objectToCopy.object
        self.property = objectToCopy.property
        self.propertyId = objectToCopy.propertyId
        self.type = objectToCopy.type
        self.startLocation = objectToCopy.startLocation
        self.endLocation = objectToCopy.endLocation
    }

    func accept(visitor: ExprVisitor) {
        visitor.visitGetExpr(expr: self)
    }
    func accept(visitor: ExprThrowVisitor) throws {
        try visitor.visitGetExpr(expr: self)
    }
    func accept(visitor: ExprQsTypeThrowVisitor) throws -> QsType {
        try visitor.visitGetExprQsType(expr: self)
    }
    func accept(visitor: ExprExprThrowVisitor) throws -> Expr {
        try visitor.visitGetExprExpr(expr: self)
    }
    func accept(visitor: ExprStringVisitor) -> String {
        visitor.visitGetExprString(expr: self)
    }
}

class UnaryExpr: Expr {
    var opr: Token
    var right: Expr
    var type: QsType?
    var startLocation: InterpreterLocation
    var endLocation: InterpreterLocation
    
    init(opr: Token, right: Expr, type: QsType?, startLocation: InterpreterLocation, endLocation: InterpreterLocation) {
        self.opr = opr
        self.right = right
        self.type = type
        self.startLocation = startLocation
        self.endLocation = endLocation
    }
    init(_ objectToCopy: UnaryExpr) {
        self.opr = objectToCopy.opr
        self.right = objectToCopy.right
        self.type = objectToCopy.type
        self.startLocation = objectToCopy.startLocation
        self.endLocation = objectToCopy.endLocation
    }

    func accept(visitor: ExprVisitor) {
        visitor.visitUnaryExpr(expr: self)
    }
    func accept(visitor: ExprThrowVisitor) throws {
        try visitor.visitUnaryExpr(expr: self)
    }
    func accept(visitor: ExprQsTypeThrowVisitor) throws -> QsType {
        try visitor.visitUnaryExprQsType(expr: self)
    }
    func accept(visitor: ExprExprThrowVisitor) throws -> Expr {
        try visitor.visitUnaryExprExpr(expr: self)
    }
    func accept(visitor: ExprStringVisitor) -> String {
        visitor.visitUnaryExprString(expr: self)
    }
}

class CastExpr: Expr {
    var toType: AstType
    var value: Expr
    var type: QsType?
    var startLocation: InterpreterLocation
    var endLocation: InterpreterLocation
    
    init(toType: AstType, value: Expr, type: QsType?, startLocation: InterpreterLocation, endLocation: InterpreterLocation) {
        self.toType = toType
        self.value = value
        self.type = type
        self.startLocation = startLocation
        self.endLocation = endLocation
    }
    init(_ objectToCopy: CastExpr) {
        self.toType = objectToCopy.toType
        self.value = objectToCopy.value
        self.type = objectToCopy.type
        self.startLocation = objectToCopy.startLocation
        self.endLocation = objectToCopy.endLocation
    }

    func accept(visitor: ExprVisitor) {
        visitor.visitCastExpr(expr: self)
    }
    func accept(visitor: ExprThrowVisitor) throws {
        try visitor.visitCastExpr(expr: self)
    }
    func accept(visitor: ExprQsTypeThrowVisitor) throws -> QsType {
        try visitor.visitCastExprQsType(expr: self)
    }
    func accept(visitor: ExprExprThrowVisitor) throws -> Expr {
        try visitor.visitCastExprExpr(expr: self)
    }
    func accept(visitor: ExprStringVisitor) -> String {
        visitor.visitCastExprString(expr: self)
    }
}

class ArrayAllocationExpr: Expr {
    var contains: AstType
    var capacity: [Expr]
    var type: QsType?
    var startLocation: InterpreterLocation
    var endLocation: InterpreterLocation
    
    init(contains: AstType, capacity: [Expr], type: QsType?, startLocation: InterpreterLocation, endLocation: InterpreterLocation) {
        self.contains = contains
        self.capacity = capacity
        self.type = type
        self.startLocation = startLocation
        self.endLocation = endLocation
    }
    init(_ objectToCopy: ArrayAllocationExpr) {
        self.contains = objectToCopy.contains
        self.capacity = objectToCopy.capacity
        self.type = objectToCopy.type
        self.startLocation = objectToCopy.startLocation
        self.endLocation = objectToCopy.endLocation
    }

    func accept(visitor: ExprVisitor) {
        visitor.visitArrayAllocationExpr(expr: self)
    }
    func accept(visitor: ExprThrowVisitor) throws {
        try visitor.visitArrayAllocationExpr(expr: self)
    }
    func accept(visitor: ExprQsTypeThrowVisitor) throws -> QsType {
        try visitor.visitArrayAllocationExprQsType(expr: self)
    }
    func accept(visitor: ExprExprThrowVisitor) throws -> Expr {
        try visitor.visitArrayAllocationExprExpr(expr: self)
    }
    func accept(visitor: ExprStringVisitor) -> String {
        visitor.visitArrayAllocationExprString(expr: self)
    }
}

class ClassAllocationExpr: Expr {
    var classType: AstClassType
    var arguments: [Expr]
    var type: QsType?
    var startLocation: InterpreterLocation
    var endLocation: InterpreterLocation
    
    init(classType: AstClassType, arguments: [Expr], type: QsType?, startLocation: InterpreterLocation, endLocation: InterpreterLocation) {
        self.classType = classType
        self.arguments = arguments
        self.type = type
        self.startLocation = startLocation
        self.endLocation = endLocation
    }
    init(_ objectToCopy: ClassAllocationExpr) {
        self.classType = objectToCopy.classType
        self.arguments = objectToCopy.arguments
        self.type = objectToCopy.type
        self.startLocation = objectToCopy.startLocation
        self.endLocation = objectToCopy.endLocation
    }

    func accept(visitor: ExprVisitor) {
        visitor.visitClassAllocationExpr(expr: self)
    }
    func accept(visitor: ExprThrowVisitor) throws {
        try visitor.visitClassAllocationExpr(expr: self)
    }
    func accept(visitor: ExprQsTypeThrowVisitor) throws -> QsType {
        try visitor.visitClassAllocationExprQsType(expr: self)
    }
    func accept(visitor: ExprExprThrowVisitor) throws -> Expr {
        try visitor.visitClassAllocationExprExpr(expr: self)
    }
    func accept(visitor: ExprStringVisitor) -> String {
        visitor.visitClassAllocationExprString(expr: self)
    }
}

class BinaryExpr: Expr {
    var left: Expr
    var opr: Token
    var right: Expr
    var type: QsType?
    var startLocation: InterpreterLocation
    var endLocation: InterpreterLocation
    
    init(left: Expr, opr: Token, right: Expr, type: QsType?, startLocation: InterpreterLocation, endLocation: InterpreterLocation) {
        self.left = left
        self.opr = opr
        self.right = right
        self.type = type
        self.startLocation = startLocation
        self.endLocation = endLocation
    }
    init(_ objectToCopy: BinaryExpr) {
        self.left = objectToCopy.left
        self.opr = objectToCopy.opr
        self.right = objectToCopy.right
        self.type = objectToCopy.type
        self.startLocation = objectToCopy.startLocation
        self.endLocation = objectToCopy.endLocation
    }

    func accept(visitor: ExprVisitor) {
        visitor.visitBinaryExpr(expr: self)
    }
    func accept(visitor: ExprThrowVisitor) throws {
        try visitor.visitBinaryExpr(expr: self)
    }
    func accept(visitor: ExprQsTypeThrowVisitor) throws -> QsType {
        try visitor.visitBinaryExprQsType(expr: self)
    }
    func accept(visitor: ExprExprThrowVisitor) throws -> Expr {
        try visitor.visitBinaryExprExpr(expr: self)
    }
    func accept(visitor: ExprStringVisitor) -> String {
        visitor.visitBinaryExprString(expr: self)
    }
}

class LogicalExpr: Expr {
    var left: Expr
    var opr: Token
    var right: Expr
    var type: QsType?
    var startLocation: InterpreterLocation
    var endLocation: InterpreterLocation
    
    init(left: Expr, opr: Token, right: Expr, type: QsType?, startLocation: InterpreterLocation, endLocation: InterpreterLocation) {
        self.left = left
        self.opr = opr
        self.right = right
        self.type = type
        self.startLocation = startLocation
        self.endLocation = endLocation
    }
    init(_ objectToCopy: LogicalExpr) {
        self.left = objectToCopy.left
        self.opr = objectToCopy.opr
        self.right = objectToCopy.right
        self.type = objectToCopy.type
        self.startLocation = objectToCopy.startLocation
        self.endLocation = objectToCopy.endLocation
    }

    func accept(visitor: ExprVisitor) {
        visitor.visitLogicalExpr(expr: self)
    }
    func accept(visitor: ExprThrowVisitor) throws {
        try visitor.visitLogicalExpr(expr: self)
    }
    func accept(visitor: ExprQsTypeThrowVisitor) throws -> QsType {
        try visitor.visitLogicalExprQsType(expr: self)
    }
    func accept(visitor: ExprExprThrowVisitor) throws -> Expr {
        try visitor.visitLogicalExprExpr(expr: self)
    }
    func accept(visitor: ExprStringVisitor) -> String {
        visitor.visitLogicalExprString(expr: self)
    }
}

class SetExpr: Expr {
    var to: Expr
    var value: Expr
    var type: QsType?
    var startLocation: InterpreterLocation
    var endLocation: InterpreterLocation
    
    init(to: Expr, value: Expr, type: QsType?, startLocation: InterpreterLocation, endLocation: InterpreterLocation) {
        self.to = to
        self.value = value
        self.type = type
        self.startLocation = startLocation
        self.endLocation = endLocation
    }
    init(_ objectToCopy: SetExpr) {
        self.to = objectToCopy.to
        self.value = objectToCopy.value
        self.type = objectToCopy.type
        self.startLocation = objectToCopy.startLocation
        self.endLocation = objectToCopy.endLocation
    }

    func accept(visitor: ExprVisitor) {
        visitor.visitSetExpr(expr: self)
    }
    func accept(visitor: ExprThrowVisitor) throws {
        try visitor.visitSetExpr(expr: self)
    }
    func accept(visitor: ExprQsTypeThrowVisitor) throws -> QsType {
        try visitor.visitSetExprQsType(expr: self)
    }
    func accept(visitor: ExprExprThrowVisitor) throws -> Expr {
        try visitor.visitSetExprExpr(expr: self)
    }
    func accept(visitor: ExprStringVisitor) -> String {
        visitor.visitSetExprString(expr: self)
    }
}

class AssignExpr: Expr {
    var to: VariableExpr
    var annotationColon: Token?
    var annotation: AstType?
    var value: Expr
    var isFirstAssignment: Bool?
    var type: QsType?
    var startLocation: InterpreterLocation
    var endLocation: InterpreterLocation
    
    init(to: VariableExpr, annotationColon: Token?, annotation: AstType?, value: Expr, isFirstAssignment: Bool?, type: QsType?, startLocation: InterpreterLocation, endLocation: InterpreterLocation) {
        self.to = to
        self.annotationColon = annotationColon
        self.annotation = annotation
        self.value = value
        self.isFirstAssignment = isFirstAssignment
        self.type = type
        self.startLocation = startLocation
        self.endLocation = endLocation
    }
    init(_ objectToCopy: AssignExpr) {
        self.to = objectToCopy.to
        self.annotationColon = objectToCopy.annotationColon
        self.annotation = objectToCopy.annotation
        self.value = objectToCopy.value
        self.isFirstAssignment = objectToCopy.isFirstAssignment
        self.type = objectToCopy.type
        self.startLocation = objectToCopy.startLocation
        self.endLocation = objectToCopy.endLocation
    }

    func accept(visitor: ExprVisitor) {
        visitor.visitAssignExpr(expr: self)
    }
    func accept(visitor: ExprThrowVisitor) throws {
        try visitor.visitAssignExpr(expr: self)
    }
    func accept(visitor: ExprQsTypeThrowVisitor) throws -> QsType {
        try visitor.visitAssignExprQsType(expr: self)
    }
    func accept(visitor: ExprExprThrowVisitor) throws -> Expr {
        try visitor.visitAssignExprExpr(expr: self)
    }
    func accept(visitor: ExprStringVisitor) -> String {
        visitor.visitAssignExprString(expr: self)
    }
}

class IsTypeExpr: Expr {
    var left: Expr
    var keyword: Token
    var right: AstType
    var rightType: QsType?
    var type: QsType?
    var startLocation: InterpreterLocation
    var endLocation: InterpreterLocation
    
    init(left: Expr, keyword: Token, right: AstType, rightType: QsType?, type: QsType?, startLocation: InterpreterLocation, endLocation: InterpreterLocation) {
        self.left = left
        self.keyword = keyword
        self.right = right
        self.rightType = rightType
        self.type = type
        self.startLocation = startLocation
        self.endLocation = endLocation
    }
    init(_ objectToCopy: IsTypeExpr) {
        self.left = objectToCopy.left
        self.keyword = objectToCopy.keyword
        self.right = objectToCopy.right
        self.rightType = objectToCopy.rightType
        self.type = objectToCopy.type
        self.startLocation = objectToCopy.startLocation
        self.endLocation = objectToCopy.endLocation
    }

    func accept(visitor: ExprVisitor) {
        visitor.visitIsTypeExpr(expr: self)
    }
    func accept(visitor: ExprThrowVisitor) throws {
        try visitor.visitIsTypeExpr(expr: self)
    }
    func accept(visitor: ExprQsTypeThrowVisitor) throws -> QsType {
        try visitor.visitIsTypeExprQsType(expr: self)
    }
    func accept(visitor: ExprExprThrowVisitor) throws -> Expr {
        try visitor.visitIsTypeExprExpr(expr: self)
    }
    func accept(visitor: ExprStringVisitor) -> String {
        visitor.visitIsTypeExprString(expr: self)
    }
}

class ImplicitCastExpr: Expr {
    var expression: Expr
    var type: QsType?
    var startLocation: InterpreterLocation
    var endLocation: InterpreterLocation
    
    init(expression: Expr, type: QsType?, startLocation: InterpreterLocation, endLocation: InterpreterLocation) {
        self.expression = expression
        self.type = type
        self.startLocation = startLocation
        self.endLocation = endLocation
    }
    init(_ objectToCopy: ImplicitCastExpr) {
        self.expression = objectToCopy.expression
        self.type = objectToCopy.type
        self.startLocation = objectToCopy.startLocation
        self.endLocation = objectToCopy.endLocation
    }

    func accept(visitor: ExprVisitor) {
        visitor.visitImplicitCastExpr(expr: self)
    }
    func accept(visitor: ExprThrowVisitor) throws {
        try visitor.visitImplicitCastExpr(expr: self)
    }
    func accept(visitor: ExprQsTypeThrowVisitor) throws -> QsType {
        try visitor.visitImplicitCastExprQsType(expr: self)
    }
    func accept(visitor: ExprExprThrowVisitor) throws -> Expr {
        try visitor.visitImplicitCastExprExpr(expr: self)
    }
    func accept(visitor: ExprStringVisitor) -> String {
        visitor.visitImplicitCastExprString(expr: self)
    }
}

