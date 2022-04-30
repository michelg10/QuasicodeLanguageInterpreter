protocol Stmt {
    func accept(visitor: StmtVisitor)
}

protocol StmtVisitor {
    func visitClassStmt(stmt: Class)
    func visitMethodStmt(stmt: Method)
    func visitFunctionStmt(stmt: Function)
    func visitExpressionStmt(stmt: Expression)
    func visitIfStmt(stmt: If)
    func visitOutputStmt(stmt: Output)
    func visitInputStmt(stmt: Input)
    func visitReturnStmt(stmt: Return)
    func visitForStmt(stmt: For)
}

class Class: Stmt {
    var name: Token
    var superclass: Variable
    var methods: [Method]
    var staticMethods: [Method]
    
    init(name: Token, superclass: Variable, methods: [Method], staticMethods: [Method]) {
        self.name = name
        self.superclass = superclass
        self.methods = methods
        self.staticMethods = staticMethods
    }

    func accept(visitor: StmtVisitor) {
        visitor.visitClassStmt(stmt: self)
    }
}

class Method: Stmt {
    var isStatic: Bool
    var visibilityModifier: VisibilityModifier
    var function: Function
    
    init(isStatic: Bool, visibilityModifier: VisibilityModifier, function: Function) {
        self.isStatic = isStatic
        self.visibilityModifier = visibilityModifier
        self.function = function
    }

    func accept(visitor: StmtVisitor) {
        visitor.visitMethodStmt(stmt: self)
    }
}

class Function: Stmt {
    var name: Token
    var params: [Expr]
    var body: [Stmt]
    
    init(name: Token, params: [Expr], body: [Stmt]) {
        self.name = name
        self.params = params
        self.body = body
    }

    func accept(visitor: StmtVisitor) {
        visitor.visitFunctionStmt(stmt: self)
    }
}

class Expression: Stmt {
    var expression: Expr
    
    init(expression: Expr) {
        self.expression = expression
    }

    func accept(visitor: StmtVisitor) {
        visitor.visitExpressionStmt(stmt: self)
    }
}

class If: Stmt {
    var condition: Expr
    var thenBranch: [Stmt]
    var elseIfBranches: [If]
    var elseBranch: [Stmt]?
    
    init(condition: Expr, thenBranch: [Stmt], elseIfBranches: [If], elseBranch: [Stmt]?) {
        self.condition = condition
        self.thenBranch = thenBranch
        self.elseIfBranches = elseIfBranches
        self.elseBranch = elseBranch
    }

    func accept(visitor: StmtVisitor) {
        visitor.visitIfStmt(stmt: self)
    }
}

class Output: Stmt {
    var expressions: [Expr]
    
    init(expressions: [Expr]) {
        self.expressions = expressions
    }

    func accept(visitor: StmtVisitor) {
        visitor.visitOutputStmt(stmt: self)
    }
}

class Input: Stmt {
    var expressions: [Expr]
    
    init(expressions: [Expr]) {
        self.expressions = expressions
    }

    func accept(visitor: StmtVisitor) {
        visitor.visitInputStmt(stmt: self)
    }
}

class Return: Stmt {
    var keyword: Token
    var value: Expr
    
    init(keyword: Token, value: Expr) {
        self.keyword = keyword
        self.value = value
    }

    func accept(visitor: StmtVisitor) {
        visitor.visitReturnStmt(stmt: self)
    }
}

class For: Stmt {
    var variable: Expr
    var loopVariable: Expr
    
    init(variable: Expr, loopVariable: Expr) {
        self.variable = variable
        self.loopVariable = loopVariable
    }

    func accept(visitor: StmtVisitor) {
        visitor.visitForStmt(stmt: self)
    }
}

