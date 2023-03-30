// swiftlint:disable all
public protocol Expr {
    func accept(visitor: ExprVisitor)
    func accept(visitor: ExprThrowVisitor) throws
    func accept(visitor: ExprQsTypeThrowVisitor) throws -> QsType
    func accept(visitor: ExprExprThrowVisitor) throws -> Expr
    func accept(visitor: ExprStringVisitor) -> String
    func accept(visitor: ExprOptionalAnyThrowVisitor) throws -> Any?
    func fallbackToErrorType(assignable: Bool)
    var type: QsType? { get set }
    var startLocation: InterpreterLocation { get set }
    var endLocation: InterpreterLocation { get set }
}

public protocol ExprVisitor {
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
    func visitVariableToSetExpr(expr: VariableToSetExpr) 
    func visitIsTypeExpr(expr: IsTypeExpr) 
    func visitImplicitCastExpr(expr: ImplicitCastExpr) 
}

public protocol ExprThrowVisitor {
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
    func visitVariableToSetExpr(expr: VariableToSetExpr) throws 
    func visitIsTypeExpr(expr: IsTypeExpr) throws 
    func visitImplicitCastExpr(expr: ImplicitCastExpr) throws 
}

public protocol ExprQsTypeThrowVisitor {
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
    func visitVariableToSetExprQsType(expr: VariableToSetExpr) throws -> QsType
    func visitIsTypeExprQsType(expr: IsTypeExpr) throws -> QsType
    func visitImplicitCastExprQsType(expr: ImplicitCastExpr) throws -> QsType
}

public protocol ExprExprThrowVisitor {
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
    func visitVariableToSetExprExpr(expr: VariableToSetExpr) throws -> Expr
    func visitIsTypeExprExpr(expr: IsTypeExpr) throws -> Expr
    func visitImplicitCastExprExpr(expr: ImplicitCastExpr) throws -> Expr
}

public protocol ExprStringVisitor {
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
    func visitVariableToSetExprString(expr: VariableToSetExpr) -> String
    func visitIsTypeExprString(expr: IsTypeExpr) -> String
    func visitImplicitCastExprString(expr: ImplicitCastExpr) -> String
}

public protocol ExprOptionalAnyThrowVisitor {
    func visitGroupingExprOptionalAny(expr: GroupingExpr) throws -> Any?
    func visitLiteralExprOptionalAny(expr: LiteralExpr) throws -> Any?
    func visitArrayLiteralExprOptionalAny(expr: ArrayLiteralExpr) throws -> Any?
    func visitStaticClassExprOptionalAny(expr: StaticClassExpr) throws -> Any?
    func visitThisExprOptionalAny(expr: ThisExpr) throws -> Any?
    func visitSuperExprOptionalAny(expr: SuperExpr) throws -> Any?
    func visitVariableExprOptionalAny(expr: VariableExpr) throws -> Any?
    func visitSubscriptExprOptionalAny(expr: SubscriptExpr) throws -> Any?
    func visitCallExprOptionalAny(expr: CallExpr) throws -> Any?
    func visitGetExprOptionalAny(expr: GetExpr) throws -> Any?
    func visitUnaryExprOptionalAny(expr: UnaryExpr) throws -> Any?
    func visitCastExprOptionalAny(expr: CastExpr) throws -> Any?
    func visitArrayAllocationExprOptionalAny(expr: ArrayAllocationExpr) throws -> Any?
    func visitClassAllocationExprOptionalAny(expr: ClassAllocationExpr) throws -> Any?
    func visitBinaryExprOptionalAny(expr: BinaryExpr) throws -> Any?
    func visitLogicalExprOptionalAny(expr: LogicalExpr) throws -> Any?
    func visitVariableToSetExprOptionalAny(expr: VariableToSetExpr) throws -> Any?
    func visitIsTypeExprOptionalAny(expr: IsTypeExpr) throws -> Any?
    func visitImplicitCastExprOptionalAny(expr: ImplicitCastExpr) throws -> Any?
}

public class GroupingExpr: Expr {
    public var expression: Expr
    public var type: QsType?
    public var startLocation: InterpreterLocation
    public var endLocation: InterpreterLocation
    
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

    public func fallbackToErrorType(assignable: Bool) {
        if self.type == nil {
            self.type = QsErrorType(assignable: assignable)
        }
    }

    public func accept(visitor: ExprVisitor) {
        visitor.visitGroupingExpr(expr: self)
    }
    public func accept(visitor: ExprThrowVisitor) throws {
        try visitor.visitGroupingExpr(expr: self)
    }
    public func accept(visitor: ExprQsTypeThrowVisitor) throws -> QsType {
        try visitor.visitGroupingExprQsType(expr: self)
    }
    public func accept(visitor: ExprExprThrowVisitor) throws -> Expr {
        try visitor.visitGroupingExprExpr(expr: self)
    }
    public func accept(visitor: ExprStringVisitor) -> String {
        visitor.visitGroupingExprString(expr: self)
    }
    public func accept(visitor: ExprOptionalAnyThrowVisitor) throws -> Any? {
        try visitor.visitGroupingExprOptionalAny(expr: self)
    }
}

public class LiteralExpr: Expr {
    public var value: Any?
    public var type: QsType?
    public var startLocation: InterpreterLocation
    public var endLocation: InterpreterLocation
    
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

    public func fallbackToErrorType(assignable: Bool) {
        if self.type == nil {
            self.type = QsErrorType(assignable: assignable)
        }
    }

    public func accept(visitor: ExprVisitor) {
        visitor.visitLiteralExpr(expr: self)
    }
    public func accept(visitor: ExprThrowVisitor) throws {
        try visitor.visitLiteralExpr(expr: self)
    }
    public func accept(visitor: ExprQsTypeThrowVisitor) throws -> QsType {
        try visitor.visitLiteralExprQsType(expr: self)
    }
    public func accept(visitor: ExprExprThrowVisitor) throws -> Expr {
        try visitor.visitLiteralExprExpr(expr: self)
    }
    public func accept(visitor: ExprStringVisitor) -> String {
        visitor.visitLiteralExprString(expr: self)
    }
    public func accept(visitor: ExprOptionalAnyThrowVisitor) throws -> Any? {
        try visitor.visitLiteralExprOptionalAny(expr: self)
    }
}

public class ArrayLiteralExpr: Expr {
    public var values: [Expr]
    public var type: QsType?
    public var startLocation: InterpreterLocation
    public var endLocation: InterpreterLocation
    
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

    public func fallbackToErrorType(assignable: Bool) {
        if self.type == nil {
            self.type = QsErrorType(assignable: assignable)
        }
    }

    public func accept(visitor: ExprVisitor) {
        visitor.visitArrayLiteralExpr(expr: self)
    }
    public func accept(visitor: ExprThrowVisitor) throws {
        try visitor.visitArrayLiteralExpr(expr: self)
    }
    public func accept(visitor: ExprQsTypeThrowVisitor) throws -> QsType {
        try visitor.visitArrayLiteralExprQsType(expr: self)
    }
    public func accept(visitor: ExprExprThrowVisitor) throws -> Expr {
        try visitor.visitArrayLiteralExprExpr(expr: self)
    }
    public func accept(visitor: ExprStringVisitor) -> String {
        visitor.visitArrayLiteralExprString(expr: self)
    }
    public func accept(visitor: ExprOptionalAnyThrowVisitor) throws -> Any? {
        try visitor.visitArrayLiteralExprOptionalAny(expr: self)
    }
}

public class StaticClassExpr: Expr {
    public var classType: AstClassType
    public var classId: Int?
    public var type: QsType?
    public var startLocation: InterpreterLocation
    public var endLocation: InterpreterLocation
    
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

    public func fallbackToErrorType(assignable: Bool) {
        if self.type == nil {
            self.type = QsErrorType(assignable: assignable)
        }
    }

    public func accept(visitor: ExprVisitor) {
        visitor.visitStaticClassExpr(expr: self)
    }
    public func accept(visitor: ExprThrowVisitor) throws {
        try visitor.visitStaticClassExpr(expr: self)
    }
    public func accept(visitor: ExprQsTypeThrowVisitor) throws -> QsType {
        try visitor.visitStaticClassExprQsType(expr: self)
    }
    public func accept(visitor: ExprExprThrowVisitor) throws -> Expr {
        try visitor.visitStaticClassExprExpr(expr: self)
    }
    public func accept(visitor: ExprStringVisitor) -> String {
        visitor.visitStaticClassExprString(expr: self)
    }
    public func accept(visitor: ExprOptionalAnyThrowVisitor) throws -> Any? {
        try visitor.visitStaticClassExprOptionalAny(expr: self)
    }
}

public class ThisExpr: Expr {
    public var keyword: Token
    public var symbolTableIndex: Int?
    public var type: QsType?
    public var startLocation: InterpreterLocation
    public var endLocation: InterpreterLocation
    
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

    public func fallbackToErrorType(assignable: Bool) {
        if self.type == nil {
            self.type = QsErrorType(assignable: assignable)
        }
    }

    public func accept(visitor: ExprVisitor) {
        visitor.visitThisExpr(expr: self)
    }
    public func accept(visitor: ExprThrowVisitor) throws {
        try visitor.visitThisExpr(expr: self)
    }
    public func accept(visitor: ExprQsTypeThrowVisitor) throws -> QsType {
        try visitor.visitThisExprQsType(expr: self)
    }
    public func accept(visitor: ExprExprThrowVisitor) throws -> Expr {
        try visitor.visitThisExprExpr(expr: self)
    }
    public func accept(visitor: ExprStringVisitor) -> String {
        visitor.visitThisExprString(expr: self)
    }
    public func accept(visitor: ExprOptionalAnyThrowVisitor) throws -> Any? {
        try visitor.visitThisExprOptionalAny(expr: self)
    }
}

public class SuperExpr: Expr {
    public var keyword: Token
    public var property: Token
    public var superClassId: Int?
    public var propertyId: Int?
    public var type: QsType?
    public var startLocation: InterpreterLocation
    public var endLocation: InterpreterLocation
    
    init(keyword: Token, property: Token, superClassId: Int?, propertyId: Int?, type: QsType?, startLocation: InterpreterLocation, endLocation: InterpreterLocation) {
        self.keyword = keyword
        self.property = property
        self.superClassId = superClassId
        self.propertyId = propertyId
        self.type = type
        self.startLocation = startLocation
        self.endLocation = endLocation
    }
    init(_ objectToCopy: SuperExpr) {
        self.keyword = objectToCopy.keyword
        self.property = objectToCopy.property
        self.superClassId = objectToCopy.superClassId
        self.propertyId = objectToCopy.propertyId
        self.type = objectToCopy.type
        self.startLocation = objectToCopy.startLocation
        self.endLocation = objectToCopy.endLocation
    }

    public func fallbackToErrorType(assignable: Bool) {
        if self.type == nil {
            self.type = QsErrorType(assignable: assignable)
        }
    }

    public func accept(visitor: ExprVisitor) {
        visitor.visitSuperExpr(expr: self)
    }
    public func accept(visitor: ExprThrowVisitor) throws {
        try visitor.visitSuperExpr(expr: self)
    }
    public func accept(visitor: ExprQsTypeThrowVisitor) throws -> QsType {
        try visitor.visitSuperExprQsType(expr: self)
    }
    public func accept(visitor: ExprExprThrowVisitor) throws -> Expr {
        try visitor.visitSuperExprExpr(expr: self)
    }
    public func accept(visitor: ExprStringVisitor) -> String {
        visitor.visitSuperExprString(expr: self)
    }
    public func accept(visitor: ExprOptionalAnyThrowVisitor) throws -> Any? {
        try visitor.visitSuperExprOptionalAny(expr: self)
    }
}

public class VariableExpr: Expr {
    public var name: Token
    public var symbolTableIndex: Int?
    public var type: QsType?
    public var startLocation: InterpreterLocation
    public var endLocation: InterpreterLocation
    
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

    public func fallbackToErrorType(assignable: Bool) {
        if self.type == nil {
            self.type = QsErrorType(assignable: assignable)
        }
    }

    public func accept(visitor: ExprVisitor) {
        visitor.visitVariableExpr(expr: self)
    }
    public func accept(visitor: ExprThrowVisitor) throws {
        try visitor.visitVariableExpr(expr: self)
    }
    public func accept(visitor: ExprQsTypeThrowVisitor) throws -> QsType {
        try visitor.visitVariableExprQsType(expr: self)
    }
    public func accept(visitor: ExprExprThrowVisitor) throws -> Expr {
        try visitor.visitVariableExprExpr(expr: self)
    }
    public func accept(visitor: ExprStringVisitor) -> String {
        visitor.visitVariableExprString(expr: self)
    }
    public func accept(visitor: ExprOptionalAnyThrowVisitor) throws -> Any? {
        try visitor.visitVariableExprOptionalAny(expr: self)
    }
}

public class SubscriptExpr: Expr {
    public var expression: Expr
    public var index: Expr
    public var type: QsType?
    public var startLocation: InterpreterLocation
    public var endLocation: InterpreterLocation
    
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

    public func fallbackToErrorType(assignable: Bool) {
        if self.type == nil {
            self.type = QsErrorType(assignable: assignable)
        }
    }

    public func accept(visitor: ExprVisitor) {
        visitor.visitSubscriptExpr(expr: self)
    }
    public func accept(visitor: ExprThrowVisitor) throws {
        try visitor.visitSubscriptExpr(expr: self)
    }
    public func accept(visitor: ExprQsTypeThrowVisitor) throws -> QsType {
        try visitor.visitSubscriptExprQsType(expr: self)
    }
    public func accept(visitor: ExprExprThrowVisitor) throws -> Expr {
        try visitor.visitSubscriptExprExpr(expr: self)
    }
    public func accept(visitor: ExprStringVisitor) -> String {
        visitor.visitSubscriptExprString(expr: self)
    }
    public func accept(visitor: ExprOptionalAnyThrowVisitor) throws -> Any? {
        try visitor.visitSubscriptExprOptionalAny(expr: self)
    }
}

public class CallExpr: Expr {
    public var object: Expr?
    public var property: Token
    public var paren: Token
    public var arguments: [Expr]
    public var uniqueFunctionCall: Int?
    public var polymorphicCallClassIdToIdDict: [Int : Int]?
    public var type: QsType?
    public var startLocation: InterpreterLocation
    public var endLocation: InterpreterLocation
    
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

    public func fallbackToErrorType(assignable: Bool) {
        if self.type == nil {
            self.type = QsErrorType(assignable: assignable)
        }
    }

    public func accept(visitor: ExprVisitor) {
        visitor.visitCallExpr(expr: self)
    }
    public func accept(visitor: ExprThrowVisitor) throws {
        try visitor.visitCallExpr(expr: self)
    }
    public func accept(visitor: ExprQsTypeThrowVisitor) throws -> QsType {
        try visitor.visitCallExprQsType(expr: self)
    }
    public func accept(visitor: ExprExprThrowVisitor) throws -> Expr {
        try visitor.visitCallExprExpr(expr: self)
    }
    public func accept(visitor: ExprStringVisitor) -> String {
        visitor.visitCallExprString(expr: self)
    }
    public func accept(visitor: ExprOptionalAnyThrowVisitor) throws -> Any? {
        try visitor.visitCallExprOptionalAny(expr: self)
    }
}

public class GetExpr: Expr {
    public var object: Expr
    public var property: Token
    public var propertyId: Int?
    public var type: QsType?
    public var startLocation: InterpreterLocation
    public var endLocation: InterpreterLocation
    
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

    public func fallbackToErrorType(assignable: Bool) {
        if self.type == nil {
            self.type = QsErrorType(assignable: assignable)
        }
    }

    public func accept(visitor: ExprVisitor) {
        visitor.visitGetExpr(expr: self)
    }
    public func accept(visitor: ExprThrowVisitor) throws {
        try visitor.visitGetExpr(expr: self)
    }
    public func accept(visitor: ExprQsTypeThrowVisitor) throws -> QsType {
        try visitor.visitGetExprQsType(expr: self)
    }
    public func accept(visitor: ExprExprThrowVisitor) throws -> Expr {
        try visitor.visitGetExprExpr(expr: self)
    }
    public func accept(visitor: ExprStringVisitor) -> String {
        visitor.visitGetExprString(expr: self)
    }
    public func accept(visitor: ExprOptionalAnyThrowVisitor) throws -> Any? {
        try visitor.visitGetExprOptionalAny(expr: self)
    }
}

public class UnaryExpr: Expr {
    public var opr: Token
    public var right: Expr
    public var type: QsType?
    public var startLocation: InterpreterLocation
    public var endLocation: InterpreterLocation
    
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

    public func fallbackToErrorType(assignable: Bool) {
        if self.type == nil {
            self.type = QsErrorType(assignable: assignable)
        }
    }

    public func accept(visitor: ExprVisitor) {
        visitor.visitUnaryExpr(expr: self)
    }
    public func accept(visitor: ExprThrowVisitor) throws {
        try visitor.visitUnaryExpr(expr: self)
    }
    public func accept(visitor: ExprQsTypeThrowVisitor) throws -> QsType {
        try visitor.visitUnaryExprQsType(expr: self)
    }
    public func accept(visitor: ExprExprThrowVisitor) throws -> Expr {
        try visitor.visitUnaryExprExpr(expr: self)
    }
    public func accept(visitor: ExprStringVisitor) -> String {
        visitor.visitUnaryExprString(expr: self)
    }
    public func accept(visitor: ExprOptionalAnyThrowVisitor) throws -> Any? {
        try visitor.visitUnaryExprOptionalAny(expr: self)
    }
}

public class CastExpr: Expr {
    public var toType: AstType
    public var value: Expr
    public var type: QsType?
    public var startLocation: InterpreterLocation
    public var endLocation: InterpreterLocation
    
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

    public func fallbackToErrorType(assignable: Bool) {
        if self.type == nil {
            self.type = QsErrorType(assignable: assignable)
        }
    }

    public func accept(visitor: ExprVisitor) {
        visitor.visitCastExpr(expr: self)
    }
    public func accept(visitor: ExprThrowVisitor) throws {
        try visitor.visitCastExpr(expr: self)
    }
    public func accept(visitor: ExprQsTypeThrowVisitor) throws -> QsType {
        try visitor.visitCastExprQsType(expr: self)
    }
    public func accept(visitor: ExprExprThrowVisitor) throws -> Expr {
        try visitor.visitCastExprExpr(expr: self)
    }
    public func accept(visitor: ExprStringVisitor) -> String {
        visitor.visitCastExprString(expr: self)
    }
    public func accept(visitor: ExprOptionalAnyThrowVisitor) throws -> Any? {
        try visitor.visitCastExprOptionalAny(expr: self)
    }
}

public class ArrayAllocationExpr: Expr {
    public var contains: AstType
    public var capacity: [Expr]
    public var type: QsType?
    public var startLocation: InterpreterLocation
    public var endLocation: InterpreterLocation
    
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

    public func fallbackToErrorType(assignable: Bool) {
        if self.type == nil {
            self.type = QsErrorType(assignable: assignable)
        }
    }

    public func accept(visitor: ExprVisitor) {
        visitor.visitArrayAllocationExpr(expr: self)
    }
    public func accept(visitor: ExprThrowVisitor) throws {
        try visitor.visitArrayAllocationExpr(expr: self)
    }
    public func accept(visitor: ExprQsTypeThrowVisitor) throws -> QsType {
        try visitor.visitArrayAllocationExprQsType(expr: self)
    }
    public func accept(visitor: ExprExprThrowVisitor) throws -> Expr {
        try visitor.visitArrayAllocationExprExpr(expr: self)
    }
    public func accept(visitor: ExprStringVisitor) -> String {
        visitor.visitArrayAllocationExprString(expr: self)
    }
    public func accept(visitor: ExprOptionalAnyThrowVisitor) throws -> Any? {
        try visitor.visitArrayAllocationExprOptionalAny(expr: self)
    }
}

public class ClassAllocationExpr: Expr {
    public var classType: AstClassType
    public var arguments: [Expr]
    public var callsFunction: Int?
    public var type: QsType?
    public var startLocation: InterpreterLocation
    public var endLocation: InterpreterLocation
    
    init(classType: AstClassType, arguments: [Expr], callsFunction: Int?, type: QsType?, startLocation: InterpreterLocation, endLocation: InterpreterLocation) {
        self.classType = classType
        self.arguments = arguments
        self.callsFunction = callsFunction
        self.type = type
        self.startLocation = startLocation
        self.endLocation = endLocation
    }
    init(_ objectToCopy: ClassAllocationExpr) {
        self.classType = objectToCopy.classType
        self.arguments = objectToCopy.arguments
        self.callsFunction = objectToCopy.callsFunction
        self.type = objectToCopy.type
        self.startLocation = objectToCopy.startLocation
        self.endLocation = objectToCopy.endLocation
    }

    public func fallbackToErrorType(assignable: Bool) {
        if self.type == nil {
            self.type = QsErrorType(assignable: assignable)
        }
    }

    public func accept(visitor: ExprVisitor) {
        visitor.visitClassAllocationExpr(expr: self)
    }
    public func accept(visitor: ExprThrowVisitor) throws {
        try visitor.visitClassAllocationExpr(expr: self)
    }
    public func accept(visitor: ExprQsTypeThrowVisitor) throws -> QsType {
        try visitor.visitClassAllocationExprQsType(expr: self)
    }
    public func accept(visitor: ExprExprThrowVisitor) throws -> Expr {
        try visitor.visitClassAllocationExprExpr(expr: self)
    }
    public func accept(visitor: ExprStringVisitor) -> String {
        visitor.visitClassAllocationExprString(expr: self)
    }
    public func accept(visitor: ExprOptionalAnyThrowVisitor) throws -> Any? {
        try visitor.visitClassAllocationExprOptionalAny(expr: self)
    }
}

public class BinaryExpr: Expr {
    public var left: Expr
    public var opr: Token
    public var right: Expr
    public var type: QsType?
    public var startLocation: InterpreterLocation
    public var endLocation: InterpreterLocation
    
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

    public func fallbackToErrorType(assignable: Bool) {
        if self.type == nil {
            self.type = QsErrorType(assignable: assignable)
        }
    }

    public func accept(visitor: ExprVisitor) {
        visitor.visitBinaryExpr(expr: self)
    }
    public func accept(visitor: ExprThrowVisitor) throws {
        try visitor.visitBinaryExpr(expr: self)
    }
    public func accept(visitor: ExprQsTypeThrowVisitor) throws -> QsType {
        try visitor.visitBinaryExprQsType(expr: self)
    }
    public func accept(visitor: ExprExprThrowVisitor) throws -> Expr {
        try visitor.visitBinaryExprExpr(expr: self)
    }
    public func accept(visitor: ExprStringVisitor) -> String {
        visitor.visitBinaryExprString(expr: self)
    }
    public func accept(visitor: ExprOptionalAnyThrowVisitor) throws -> Any? {
        try visitor.visitBinaryExprOptionalAny(expr: self)
    }
}

public class LogicalExpr: Expr {
    public var left: Expr
    public var opr: Token
    public var right: Expr
    public var type: QsType?
    public var startLocation: InterpreterLocation
    public var endLocation: InterpreterLocation
    
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

    public func fallbackToErrorType(assignable: Bool) {
        if self.type == nil {
            self.type = QsErrorType(assignable: assignable)
        }
    }

    public func accept(visitor: ExprVisitor) {
        visitor.visitLogicalExpr(expr: self)
    }
    public func accept(visitor: ExprThrowVisitor) throws {
        try visitor.visitLogicalExpr(expr: self)
    }
    public func accept(visitor: ExprQsTypeThrowVisitor) throws -> QsType {
        try visitor.visitLogicalExprQsType(expr: self)
    }
    public func accept(visitor: ExprExprThrowVisitor) throws -> Expr {
        try visitor.visitLogicalExprExpr(expr: self)
    }
    public func accept(visitor: ExprStringVisitor) -> String {
        visitor.visitLogicalExprString(expr: self)
    }
    public func accept(visitor: ExprOptionalAnyThrowVisitor) throws -> Any? {
        try visitor.visitLogicalExprOptionalAny(expr: self)
    }
}

public class VariableToSetExpr: Expr {
    public var to: VariableExpr
    public var annotationColon: Token?
    public var annotation: AstType?
    public var isFirstAssignment: Bool?
    public var type: QsType?
    public var startLocation: InterpreterLocation
    public var endLocation: InterpreterLocation
    
    init(to: VariableExpr, annotationColon: Token?, annotation: AstType?, isFirstAssignment: Bool?, type: QsType?, startLocation: InterpreterLocation, endLocation: InterpreterLocation) {
        self.to = to
        self.annotationColon = annotationColon
        self.annotation = annotation
        self.isFirstAssignment = isFirstAssignment
        self.type = type
        self.startLocation = startLocation
        self.endLocation = endLocation
    }
    init(_ objectToCopy: VariableToSetExpr) {
        self.to = objectToCopy.to
        self.annotationColon = objectToCopy.annotationColon
        self.annotation = objectToCopy.annotation
        self.isFirstAssignment = objectToCopy.isFirstAssignment
        self.type = objectToCopy.type
        self.startLocation = objectToCopy.startLocation
        self.endLocation = objectToCopy.endLocation
    }

    public func fallbackToErrorType(assignable: Bool) {
        if self.type == nil {
            self.type = QsErrorType(assignable: assignable)
        }
    }

    public func accept(visitor: ExprVisitor) {
        visitor.visitVariableToSetExpr(expr: self)
    }
    public func accept(visitor: ExprThrowVisitor) throws {
        try visitor.visitVariableToSetExpr(expr: self)
    }
    public func accept(visitor: ExprQsTypeThrowVisitor) throws -> QsType {
        try visitor.visitVariableToSetExprQsType(expr: self)
    }
    public func accept(visitor: ExprExprThrowVisitor) throws -> Expr {
        try visitor.visitVariableToSetExprExpr(expr: self)
    }
    public func accept(visitor: ExprStringVisitor) -> String {
        visitor.visitVariableToSetExprString(expr: self)
    }
    public func accept(visitor: ExprOptionalAnyThrowVisitor) throws -> Any? {
        try visitor.visitVariableToSetExprOptionalAny(expr: self)
    }
}

public class IsTypeExpr: Expr {
    public var left: Expr
    public var keyword: Token
    public var right: AstType
    public var rightType: QsType?
    public var type: QsType?
    public var startLocation: InterpreterLocation
    public var endLocation: InterpreterLocation
    
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

    public func fallbackToErrorType(assignable: Bool) {
        if self.type == nil {
            self.type = QsErrorType(assignable: assignable)
        }
    }

    public func accept(visitor: ExprVisitor) {
        visitor.visitIsTypeExpr(expr: self)
    }
    public func accept(visitor: ExprThrowVisitor) throws {
        try visitor.visitIsTypeExpr(expr: self)
    }
    public func accept(visitor: ExprQsTypeThrowVisitor) throws -> QsType {
        try visitor.visitIsTypeExprQsType(expr: self)
    }
    public func accept(visitor: ExprExprThrowVisitor) throws -> Expr {
        try visitor.visitIsTypeExprExpr(expr: self)
    }
    public func accept(visitor: ExprStringVisitor) -> String {
        visitor.visitIsTypeExprString(expr: self)
    }
    public func accept(visitor: ExprOptionalAnyThrowVisitor) throws -> Any? {
        try visitor.visitIsTypeExprOptionalAny(expr: self)
    }
}

public class ImplicitCastExpr: Expr {
    public var expression: Expr
    public var type: QsType?
    public var startLocation: InterpreterLocation
    public var endLocation: InterpreterLocation
    
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

    public func fallbackToErrorType(assignable: Bool) {
        if self.type == nil {
            self.type = QsErrorType(assignable: assignable)
        }
    }

    public func accept(visitor: ExprVisitor) {
        visitor.visitImplicitCastExpr(expr: self)
    }
    public func accept(visitor: ExprThrowVisitor) throws {
        try visitor.visitImplicitCastExpr(expr: self)
    }
    public func accept(visitor: ExprQsTypeThrowVisitor) throws -> QsType {
        try visitor.visitImplicitCastExprQsType(expr: self)
    }
    public func accept(visitor: ExprExprThrowVisitor) throws -> Expr {
        try visitor.visitImplicitCastExprExpr(expr: self)
    }
    public func accept(visitor: ExprStringVisitor) -> String {
        visitor.visitImplicitCastExprString(expr: self)
    }
    public func accept(visitor: ExprOptionalAnyThrowVisitor) throws -> Any? {
        try visitor.visitImplicitCastExprOptionalAny(expr: self)
    }
}

