protocol Expr {
    func accept(visitor: ExprVisitor)
    var type: QsType? { get set }
}

protocol ExprVisitor {
    func visitLiteralExpr(expr: Literal)
    func visitThisExpr(expr: This)
    func visitSuperExpr(expr: Super)
    func visitVariableExpr(expr: Variable)
    func visitSubscriptExpr(expr: Subscript)
    func visitCallExpr(expr: Call)
    func visitGetExpr(expr: Get)
    func visitUnaryExpr(expr: Unary)
    func visitCastExpr(expr: Cast)
    func visitArrayAllocationExpr(expr: ArrayAllocation)
    func visitClassAllocationExpr(expr: ClassAllocation)
    func visitBinaryExpr(expr: Binary)
    func visitSetExpr(expr: Set)
}

class Literal: Expr {
    var value: Any
    var type: QsType?
    
    init(value: Any, type: QsType?) {
        self.value = value
        self.type = type
    }

    func accept(visitor: ExprVisitor) {
        visitor.visitLiteralExpr(expr: self)
    }
}

class This: Expr {
    var keyword: Token
    var type: QsType?
    
    init(keyword: Token, type: QsType?) {
        self.keyword = keyword
        self.type = type
    }

    func accept(visitor: ExprVisitor) {
        visitor.visitThisExpr(expr: self)
    }
}

class Super: Expr {
    var keyword: Token
    var method: Token
    var type: QsType?
    
    init(keyword: Token, method: Token, type: QsType?) {
        self.keyword = keyword
        self.method = method
        self.type = type
    }

    func accept(visitor: ExprVisitor) {
        visitor.visitSuperExpr(expr: self)
    }
}

class Variable: Expr {
    var name: Token
    var type: QsType?
    
    init(name: Token, type: QsType?) {
        self.name = name
        self.type = type
    }

    func accept(visitor: ExprVisitor) {
        visitor.visitVariableExpr(expr: self)
    }
}

class Subscript: Expr {
    var expression: Expr
    var index: Expr
    var type: QsType?
    
    init(expression: Expr, index: Expr, type: QsType?) {
        self.expression = expression
        self.index = index
        self.type = type
    }

    func accept(visitor: ExprVisitor) {
        visitor.visitSubscriptExpr(expr: self)
    }
}

class Call: Expr {
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

    func accept(visitor: ExprVisitor) {
        visitor.visitCallExpr(expr: self)
    }
}

class Get: Expr {
    var object: Expr
    var name: Token
    var type: QsType?
    
    init(object: Expr, name: Token, type: QsType?) {
        self.object = object
        self.name = name
        self.type = type
    }

    func accept(visitor: ExprVisitor) {
        visitor.visitGetExpr(expr: self)
    }
}

class Unary: Expr {
    var opr: Token
    var right: Expr
    var type: QsType?
    
    init(opr: Token, right: Expr, type: QsType?) {
        self.opr = opr
        self.right = right
        self.type = type
    }

    func accept(visitor: ExprVisitor) {
        visitor.visitUnaryExpr(expr: self)
    }
}

class Cast: Expr {
    var toType: QsType
    var value: Expr
    var type: QsType?
    
    init(toType: QsType, value: Expr, type: QsType?) {
        self.toType = toType
        self.value = value
        self.type = type
    }

    func accept(visitor: ExprVisitor) {
        visitor.visitCastExpr(expr: self)
    }
}

class ArrayAllocation: Expr {
    var contains: QsType
    var capacity: Expr
    var type: QsType?
    
    init(contains: QsType, capacity: Expr, type: QsType?) {
        self.contains = contains
        self.capacity = capacity
        self.type = type
    }

    func accept(visitor: ExprVisitor) {
        visitor.visitArrayAllocationExpr(expr: self)
    }
}

class ClassAllocation: Expr {
    var classType: QsClass
    var type: QsType?
    
    init(classType: QsClass, type: QsType?) {
        self.classType = classType
        self.type = type
    }

    func accept(visitor: ExprVisitor) {
        visitor.visitClassAllocationExpr(expr: self)
    }
}

class Binary: Expr {
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

    func accept(visitor: ExprVisitor) {
        visitor.visitBinaryExpr(expr: self)
    }
}

class Set: Expr {
    var to: Expr
    var toType: QsType?
    var value: Expr
    var type: QsType?
    
    init(to: Expr, toType: QsType?, value: Expr, type: QsType?) {
        self.to = to
        self.toType = toType
        self.value = value
        self.type = type
    }

    func accept(visitor: ExprVisitor) {
        visitor.visitSetExpr(expr: self)
    }
}

