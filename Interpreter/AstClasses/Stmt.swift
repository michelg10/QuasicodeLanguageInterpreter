protocol Stmt {
    func accept(visitor: StmtVisitor)
    func accept(visitor: StmtStringVisitor) -> String
}

protocol StmtVisitor {
    func visitClassStmt(stmt: ClassStmt) 
    func visitMethodStmt(stmt: MethodStmt) 
    func visitFunctionStmt(stmt: FunctionStmt) 
    func visitExpressionStmt(stmt: ExpressionStmt) 
    func visitIfStmt(stmt: IfStmt) 
    func visitOutputStmt(stmt: OutputStmt) 
    func visitInputStmt(stmt: InputStmt) 
    func visitReturnStmt(stmt: ReturnStmt) 
    func visitLoopFromStmt(stmt: LoopFromStmt) 
    func visitWhileStmt(stmt: WhileStmt) 
    func visitBreakStmt(stmt: BreakStmt) 
    func visitContinueStmt(stmt: ContinueStmt) 
}

protocol StmtStringVisitor {
    func visitClassStmtString(stmt: ClassStmt) -> String
    func visitMethodStmtString(stmt: MethodStmt) -> String
    func visitFunctionStmtString(stmt: FunctionStmt) -> String
    func visitExpressionStmtString(stmt: ExpressionStmt) -> String
    func visitIfStmtString(stmt: IfStmt) -> String
    func visitOutputStmtString(stmt: OutputStmt) -> String
    func visitInputStmtString(stmt: InputStmt) -> String
    func visitReturnStmtString(stmt: ReturnStmt) -> String
    func visitLoopFromStmtString(stmt: LoopFromStmt) -> String
    func visitWhileStmtString(stmt: WhileStmt) -> String
    func visitBreakStmtString(stmt: BreakStmt) -> String
    func visitContinueStmtString(stmt: ContinueStmt) -> String
}

class ClassStmt: Stmt {
    var keyword: Token
    var name: Token
    var templateParameters: [Token]?
    var superclass: AstClassType?
    var methods: [MethodStmt]
    var staticMethods: [MethodStmt]
    var fields: [ClassField]
    var staticFields: [ClassField]
    
    init(keyword: Token, name: Token, templateParameters: [Token]?, superclass: AstClassType?, methods: [MethodStmt], staticMethods: [MethodStmt], fields: [ClassField], staticFields: [ClassField]) {
        self.keyword = keyword
        self.name = name
        self.templateParameters = templateParameters
        self.superclass = superclass
        self.methods = methods
        self.staticMethods = staticMethods
        self.fields = fields
        self.staticFields = staticFields
    }

    func accept(visitor: StmtVisitor) {
        visitor.visitClassStmt(stmt: self)
    }
    func accept(visitor: StmtStringVisitor) -> String {
        visitor.visitClassStmtString(stmt: self)
    }
}

class MethodStmt: Stmt {
    var isStatic: Bool
    var visibilityModifier: VisibilityModifier
    var function: FunctionStmt
    
    init(isStatic: Bool, visibilityModifier: VisibilityModifier, function: FunctionStmt) {
        self.isStatic = isStatic
        self.visibilityModifier = visibilityModifier
        self.function = function
    }

    func accept(visitor: StmtVisitor) {
        visitor.visitMethodStmt(stmt: self)
    }
    func accept(visitor: StmtStringVisitor) -> String {
        visitor.visitMethodStmtString(stmt: self)
    }
}

class FunctionStmt: Stmt {
    var keyword: Token
    var name: Token
    var params: [FunctionParam]
    var annotation: AstType?
    var body: [Stmt]
    
    init(keyword: Token, name: Token, params: [FunctionParam], annotation: AstType?, body: [Stmt]) {
        self.keyword = keyword
        self.name = name
        self.params = params
        self.annotation = annotation
        self.body = body
    }

    func accept(visitor: StmtVisitor) {
        visitor.visitFunctionStmt(stmt: self)
    }
    func accept(visitor: StmtStringVisitor) -> String {
        visitor.visitFunctionStmtString(stmt: self)
    }
}

class ExpressionStmt: Stmt {
    var expression: Expr
    
    init(expression: Expr) {
        self.expression = expression
    }

    func accept(visitor: StmtVisitor) {
        visitor.visitExpressionStmt(stmt: self)
    }
    func accept(visitor: StmtStringVisitor) -> String {
        visitor.visitExpressionStmtString(stmt: self)
    }
}

class IfStmt: Stmt {
    var condition: Expr
    var thenBranch: [Stmt]
    var elseIfBranches: [IfStmt]
    var elseBranch: [Stmt]?
    
    init(condition: Expr, thenBranch: [Stmt], elseIfBranches: [IfStmt], elseBranch: [Stmt]?) {
        self.condition = condition
        self.thenBranch = thenBranch
        self.elseIfBranches = elseIfBranches
        self.elseBranch = elseBranch
    }

    func accept(visitor: StmtVisitor) {
        visitor.visitIfStmt(stmt: self)
    }
    func accept(visitor: StmtStringVisitor) -> String {
        visitor.visitIfStmtString(stmt: self)
    }
}

class OutputStmt: Stmt {
    var expressions: [Expr]
    
    init(expressions: [Expr]) {
        self.expressions = expressions
    }

    func accept(visitor: StmtVisitor) {
        visitor.visitOutputStmt(stmt: self)
    }
    func accept(visitor: StmtStringVisitor) -> String {
        visitor.visitOutputStmtString(stmt: self)
    }
}

class InputStmt: Stmt {
    var expressions: [Expr]
    
    init(expressions: [Expr]) {
        self.expressions = expressions
    }

    func accept(visitor: StmtVisitor) {
        visitor.visitInputStmt(stmt: self)
    }
    func accept(visitor: StmtStringVisitor) -> String {
        visitor.visitInputStmtString(stmt: self)
    }
}

class ReturnStmt: Stmt {
    var keyword: Token
    var value: Expr?
    
    init(keyword: Token, value: Expr?) {
        self.keyword = keyword
        self.value = value
    }

    func accept(visitor: StmtVisitor) {
        visitor.visitReturnStmt(stmt: self)
    }
    func accept(visitor: StmtStringVisitor) -> String {
        visitor.visitReturnStmtString(stmt: self)
    }
}

class LoopFromStmt: Stmt {
    var variable: Expr
    var lRange: Expr
    var rRange: Expr
    var statements: [Stmt]
    
    init(variable: Expr, lRange: Expr, rRange: Expr, statements: [Stmt]) {
        self.variable = variable
        self.lRange = lRange
        self.rRange = rRange
        self.statements = statements
    }

    func accept(visitor: StmtVisitor) {
        visitor.visitLoopFromStmt(stmt: self)
    }
    func accept(visitor: StmtStringVisitor) -> String {
        visitor.visitLoopFromStmtString(stmt: self)
    }
}

class WhileStmt: Stmt {
    var expression: Expr
    var statements: [Stmt]
    
    init(expression: Expr, statements: [Stmt]) {
        self.expression = expression
        self.statements = statements
    }

    func accept(visitor: StmtVisitor) {
        visitor.visitWhileStmt(stmt: self)
    }
    func accept(visitor: StmtStringVisitor) -> String {
        visitor.visitWhileStmtString(stmt: self)
    }
}

class BreakStmt: Stmt {
    var keyword: Token
    
    init(keyword: Token) {
        self.keyword = keyword
    }

    func accept(visitor: StmtVisitor) {
        visitor.visitBreakStmt(stmt: self)
    }
    func accept(visitor: StmtStringVisitor) -> String {
        visitor.visitBreakStmtString(stmt: self)
    }
}

class ContinueStmt: Stmt {
    var keyword: Token
    
    init(keyword: Token) {
        self.keyword = keyword
    }

    func accept(visitor: StmtVisitor) {
        visitor.visitContinueStmt(stmt: self)
    }
    func accept(visitor: StmtStringVisitor) -> String {
        visitor.visitContinueStmtString(stmt: self)
    }
}

