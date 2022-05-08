protocol Expr {
    func accept(visitor: ExprVisitor)
    func accept(visitor: ExprExprThrowVisitor) throws -> Expr
    func accept(visitor: ExprStringVisitor) -> String
    var type: QsType? { get set }
}

protocol ExprVisitor {
    func visitGroupingExpr(expr: GroupingExpr) 
    func visitLiteralExpr(expr: LiteralExpr) 
    func visitArrayLiteralExpr(expr: ArrayLiteralExpr) 
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
}

protocol ExprExprThrowVisitor {
    func visitGroupingExprExpr(expr: GroupingExpr) throws -> Expr
    func visitLiteralExprExpr(expr: LiteralExpr) throws -> Expr
    func visitArrayLiteralExprExpr(expr: ArrayLiteralExpr) throws -> Expr
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
}

protocol ExprStringVisitor {
    func visitGroupingExprString(expr: GroupingExpr) -> String
    func visitLiteralExprString(expr: LiteralExpr) -> String
    func visitArrayLiteralExprString(expr: ArrayLiteralExpr) -> String
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
}

class GroupingExpr: Expr {
    var expression: Expr
    var type: QsType?
    
    init(expression: Expr, type: QsType?) {
        self.expression = expression
        self.type = type
    }
    init(_ objectToCopy: GroupingExpr) {
        self.expression = objectToCopy.expression
        self.type = objectToCopy.type
    }

    func accept(visitor: ExprVisitor) {
        visitor.visitGroupingExpr(expr: self)
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
    
    init(value: Any?, type: QsType?) {
        self.value = value
        self.type = type
    }
    init(_ objectToCopy: LiteralExpr) {
        self.value = objectToCopy.value
        self.type = objectToCopy.type
    }

    func accept(visitor: ExprVisitor) {
        visitor.visitLiteralExpr(expr: self)
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
    
    init(values: [Expr], type: QsType?) {
        self.values = values
        self.type = type
    }
    init(_ objectToCopy: ArrayLiteralExpr) {
        self.values = objectToCopy.values
        self.type = objectToCopy.type
    }

    func accept(visitor: ExprVisitor) {
        visitor.visitArrayLiteralExpr(expr: self)
    }
    func accept(visitor: ExprExprThrowVisitor) throws -> Expr {
        try visitor.visitArrayLiteralExprExpr(expr: self)
    }
    func accept(visitor: ExprStringVisitor) -> String {
        visitor.visitArrayLiteralExprString(expr: self)
    }
}

class ThisExpr: Expr {
    var keyword: Token
    var type: QsType?
    
    init(keyword: Token, type: QsType?) {
        self.keyword = keyword
        self.type = type
    }
    init(_ objectToCopy: ThisExpr) {
        self.keyword = objectToCopy.keyword
        self.type = objectToCopy.type
    }

    func accept(visitor: ExprVisitor) {
        visitor.visitThisExpr(expr: self)
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
    var type: QsType?
    
    init(keyword: Token, property: Token, type: QsType?) {
        self.keyword = keyword
        self.property = property
        self.type = type
    }
    init(_ objectToCopy: SuperExpr) {
        self.keyword = objectToCopy.keyword
        self.property = objectToCopy.property
        self.type = objectToCopy.type
    }

    func accept(visitor: ExprVisitor) {
        visitor.visitSuperExpr(expr: self)
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
    var runtimeLocation: RuntimeLocation?
    var type: QsType?
    
    init(name: Token, symbolTableIndex: Int?, runtimeLocation: RuntimeLocation?, type: QsType?) {
        self.name = name
        self.symbolTableIndex = symbolTableIndex
        self.runtimeLocation = runtimeLocation
        self.type = type
    }
    init(_ objectToCopy: VariableExpr) {
        self.name = objectToCopy.name
        self.symbolTableIndex = objectToCopy.symbolTableIndex
        self.runtimeLocation = objectToCopy.runtimeLocation
        self.type = objectToCopy.type
    }

    func accept(visitor: ExprVisitor) {
        visitor.visitVariableExpr(expr: self)
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
    
    init(expression: Expr, index: Expr, type: QsType?) {
        self.expression = expression
        self.index = index
        self.type = type
    }
    init(_ objectToCopy: SubscriptExpr) {
        self.expression = objectToCopy.expression
        self.index = objectToCopy.index
        self.type = objectToCopy.type
    }

    func accept(visitor: ExprVisitor) {
        visitor.visitSubscriptExpr(expr: self)
    }
    func accept(visitor: ExprExprThrowVisitor) throws -> Expr {
        try visitor.visitSubscriptExprExpr(expr: self)
    }
    func accept(visitor: ExprStringVisitor) -> String {
        visitor.visitSubscriptExprString(expr: self)
    }
}

class CallExpr: Expr {
    var callee: Expr
    var paren: Token
    var arguments: [Expr]
    var type: QsType?
    
    init(callee: Expr, paren: Token, arguments: [Expr], type: QsType?) {
        self.callee = callee
        self.paren = paren
        self.arguments = arguments
        self.type = type
    }
    init(_ objectToCopy: CallExpr) {
        self.callee = objectToCopy.callee
        self.paren = objectToCopy.paren
        self.arguments = objectToCopy.arguments
        self.type = objectToCopy.type
    }

    func accept(visitor: ExprVisitor) {
        visitor.visitCallExpr(expr: self)
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
    var name: Token
    var type: QsType?
    
    init(object: Expr, name: Token, type: QsType?) {
        self.object = object
        self.name = name
        self.type = type
    }
    init(_ objectToCopy: GetExpr) {
        self.object = objectToCopy.object
        self.name = objectToCopy.name
        self.type = objectToCopy.type
    }

    func accept(visitor: ExprVisitor) {
        visitor.visitGetExpr(expr: self)
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
    
    init(opr: Token, right: Expr, type: QsType?) {
        self.opr = opr
        self.right = right
        self.type = type
    }
    init(_ objectToCopy: UnaryExpr) {
        self.opr = objectToCopy.opr
        self.right = objectToCopy.right
        self.type = objectToCopy.type
    }

    func accept(visitor: ExprVisitor) {
        visitor.visitUnaryExpr(expr: self)
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
    
    init(toType: AstType, value: Expr, type: QsType?) {
        self.toType = toType
        self.value = value
        self.type = type
    }
    init(_ objectToCopy: CastExpr) {
        self.toType = objectToCopy.toType
        self.value = objectToCopy.value
        self.type = objectToCopy.type
    }

    func accept(visitor: ExprVisitor) {
        visitor.visitCastExpr(expr: self)
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
    
    init(contains: AstType, capacity: [Expr], type: QsType?) {
        self.contains = contains
        self.capacity = capacity
        self.type = type
    }
    init(_ objectToCopy: ArrayAllocationExpr) {
        self.contains = objectToCopy.contains
        self.capacity = objectToCopy.capacity
        self.type = objectToCopy.type
    }

    func accept(visitor: ExprVisitor) {
        visitor.visitArrayAllocationExpr(expr: self)
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
    
    init(classType: AstClassType, arguments: [Expr], type: QsType?) {
        self.classType = classType
        self.arguments = arguments
        self.type = type
    }
    init(_ objectToCopy: ClassAllocationExpr) {
        self.classType = objectToCopy.classType
        self.arguments = objectToCopy.arguments
        self.type = objectToCopy.type
    }

    func accept(visitor: ExprVisitor) {
        visitor.visitClassAllocationExpr(expr: self)
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
    
    init(left: Expr, opr: Token, right: Expr, type: QsType?) {
        self.left = left
        self.opr = opr
        self.right = right
        self.type = type
    }
    init(_ objectToCopy: BinaryExpr) {
        self.left = objectToCopy.left
        self.opr = objectToCopy.opr
        self.right = objectToCopy.right
        self.type = objectToCopy.type
    }

    func accept(visitor: ExprVisitor) {
        visitor.visitBinaryExpr(expr: self)
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
    
    init(left: Expr, opr: Token, right: Expr, type: QsType?) {
        self.left = left
        self.opr = opr
        self.right = right
        self.type = type
    }
    init(_ objectToCopy: LogicalExpr) {
        self.left = objectToCopy.left
        self.opr = objectToCopy.opr
        self.right = objectToCopy.right
        self.type = objectToCopy.type
    }

    func accept(visitor: ExprVisitor) {
        visitor.visitLogicalExpr(expr: self)
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
    var annotation: AstType?
    var value: Expr
    var isFirstAssignment: Bool?
    var type: QsType?
    
    init(to: Expr, annotation: AstType?, value: Expr, isFirstAssignment: Bool?, type: QsType?) {
        self.to = to
        self.annotation = annotation
        self.value = value
        self.isFirstAssignment = isFirstAssignment
        self.type = type
    }
    init(_ objectToCopy: SetExpr) {
        self.to = objectToCopy.to
        self.annotation = objectToCopy.annotation
        self.value = objectToCopy.value
        self.isFirstAssignment = objectToCopy.isFirstAssignment
        self.type = objectToCopy.type
    }

    func accept(visitor: ExprVisitor) {
        visitor.visitSetExpr(expr: self)
    }
    func accept(visitor: ExprExprThrowVisitor) throws -> Expr {
        try visitor.visitSetExprExpr(expr: self)
    }
    func accept(visitor: ExprStringVisitor) -> String {
        visitor.visitSetExprString(expr: self)
    }
}

