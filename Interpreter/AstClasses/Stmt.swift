protocol Stmt {
    func accept(visitor: StmtVisitor)
    func accept(visitor: StmtStmtVisitor) -> Stmt
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
    func visitBlockStmt(stmt: BlockStmt) 
}

protocol StmtStmtVisitor {
    func visitClassStmtStmt(stmt: ClassStmt) -> Stmt
    func visitMethodStmtStmt(stmt: MethodStmt) -> Stmt
    func visitFunctionStmtStmt(stmt: FunctionStmt) -> Stmt
    func visitExpressionStmtStmt(stmt: ExpressionStmt) -> Stmt
    func visitIfStmtStmt(stmt: IfStmt) -> Stmt
    func visitOutputStmtStmt(stmt: OutputStmt) -> Stmt
    func visitInputStmtStmt(stmt: InputStmt) -> Stmt
    func visitReturnStmtStmt(stmt: ReturnStmt) -> Stmt
    func visitLoopFromStmtStmt(stmt: LoopFromStmt) -> Stmt
    func visitWhileStmtStmt(stmt: WhileStmt) -> Stmt
    func visitBreakStmtStmt(stmt: BreakStmt) -> Stmt
    func visitContinueStmtStmt(stmt: ContinueStmt) -> Stmt
    func visitBlockStmtStmt(stmt: BlockStmt) -> Stmt
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
    func visitBlockStmtString(stmt: BlockStmt) -> String
}

class ClassStmt: Stmt {
    var keyword: Token
    var name: Token
    var symbolTableIndex: Int?
    var instanceThisSymbolTableIndex: Int?
    var staticThisSymbolTableIndex: Int?
    var scopeIndex: Int?
    var templateParameters: [Token]?
    var expandedTemplateParameters: [AstType]?
    var superclass: AstClassType?
    var methods: [MethodStmt]
    var staticMethods: [MethodStmt]
    var fields: [ClassField]
    var staticFields: [ClassField]
    
    init(keyword: Token, name: Token, symbolTableIndex: Int?, instanceThisSymbolTableIndex: Int?, staticThisSymbolTableIndex: Int?, scopeIndex: Int?, templateParameters: [Token]?, expandedTemplateParameters: [AstType]?, superclass: AstClassType?, methods: [MethodStmt], staticMethods: [MethodStmt], fields: [ClassField], staticFields: [ClassField]) {
        self.keyword = keyword
        self.name = name
        self.symbolTableIndex = symbolTableIndex
        self.instanceThisSymbolTableIndex = instanceThisSymbolTableIndex
        self.staticThisSymbolTableIndex = staticThisSymbolTableIndex
        self.scopeIndex = scopeIndex
        self.templateParameters = templateParameters
        self.expandedTemplateParameters = expandedTemplateParameters
        self.superclass = superclass
        self.methods = methods
        self.staticMethods = staticMethods
        self.fields = fields
        self.staticFields = staticFields
    }
    init(_ objectToCopy: ClassStmt) {
        self.keyword = objectToCopy.keyword
        self.name = objectToCopy.name
        self.symbolTableIndex = objectToCopy.symbolTableIndex
        self.instanceThisSymbolTableIndex = objectToCopy.instanceThisSymbolTableIndex
        self.staticThisSymbolTableIndex = objectToCopy.staticThisSymbolTableIndex
        self.scopeIndex = objectToCopy.scopeIndex
        self.templateParameters = objectToCopy.templateParameters
        self.expandedTemplateParameters = objectToCopy.expandedTemplateParameters
        self.superclass = objectToCopy.superclass
        self.methods = objectToCopy.methods
        self.staticMethods = objectToCopy.staticMethods
        self.fields = objectToCopy.fields
        self.staticFields = objectToCopy.staticFields
    }

    func accept(visitor: StmtVisitor) {
        visitor.visitClassStmt(stmt: self)
    }
    func accept(visitor: StmtStmtVisitor) -> Stmt {
        visitor.visitClassStmtStmt(stmt: self)
    }
    func accept(visitor: StmtStringVisitor) -> String {
        visitor.visitClassStmtString(stmt: self)
    }
}

class MethodStmt: Stmt {
    var isStatic: Bool
    var staticKeyword: Token?
    var visibilityModifier: VisibilityModifier
    var function: FunctionStmt
    
    init(isStatic: Bool, staticKeyword: Token?, visibilityModifier: VisibilityModifier, function: FunctionStmt) {
        self.isStatic = isStatic
        self.staticKeyword = staticKeyword
        self.visibilityModifier = visibilityModifier
        self.function = function
    }
    init(_ objectToCopy: MethodStmt) {
        self.isStatic = objectToCopy.isStatic
        self.staticKeyword = objectToCopy.staticKeyword
        self.visibilityModifier = objectToCopy.visibilityModifier
        self.function = objectToCopy.function
    }

    func accept(visitor: StmtVisitor) {
        visitor.visitMethodStmt(stmt: self)
    }
    func accept(visitor: StmtStmtVisitor) -> Stmt {
        visitor.visitMethodStmtStmt(stmt: self)
    }
    func accept(visitor: StmtStringVisitor) -> String {
        visitor.visitMethodStmtString(stmt: self)
    }
}

class FunctionStmt: Stmt {
    var keyword: Token
    var name: Token
    var symbolTableIndex: Int?
    var nameSymbolTableIndex: Int?
    var scopeIndex: Int?
    var params: [FunctionParam]
    var annotation: AstType?
    var body: [Stmt]
    
    init(keyword: Token, name: Token, symbolTableIndex: Int?, nameSymbolTableIndex: Int?, scopeIndex: Int?, params: [FunctionParam], annotation: AstType?, body: [Stmt]) {
        self.keyword = keyword
        self.name = name
        self.symbolTableIndex = symbolTableIndex
        self.nameSymbolTableIndex = nameSymbolTableIndex
        self.scopeIndex = scopeIndex
        self.params = params
        self.annotation = annotation
        self.body = body
    }
    init(_ objectToCopy: FunctionStmt) {
        self.keyword = objectToCopy.keyword
        self.name = objectToCopy.name
        self.symbolTableIndex = objectToCopy.symbolTableIndex
        self.nameSymbolTableIndex = objectToCopy.nameSymbolTableIndex
        self.scopeIndex = objectToCopy.scopeIndex
        self.params = objectToCopy.params
        self.annotation = objectToCopy.annotation
        self.body = objectToCopy.body
    }

    func accept(visitor: StmtVisitor) {
        visitor.visitFunctionStmt(stmt: self)
    }
    func accept(visitor: StmtStmtVisitor) -> Stmt {
        visitor.visitFunctionStmtStmt(stmt: self)
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
    init(_ objectToCopy: ExpressionStmt) {
        self.expression = objectToCopy.expression
    }

    func accept(visitor: StmtVisitor) {
        visitor.visitExpressionStmt(stmt: self)
    }
    func accept(visitor: StmtStmtVisitor) -> Stmt {
        visitor.visitExpressionStmtStmt(stmt: self)
    }
    func accept(visitor: StmtStringVisitor) -> String {
        visitor.visitExpressionStmtString(stmt: self)
    }
}

class IfStmt: Stmt {
    var condition: Expr
    var thenBranch: BlockStmt
    var elseIfBranches: [IfStmt]
    var elseBranch: BlockStmt?
    
    init(condition: Expr, thenBranch: BlockStmt, elseIfBranches: [IfStmt], elseBranch: BlockStmt?) {
        self.condition = condition
        self.thenBranch = thenBranch
        self.elseIfBranches = elseIfBranches
        self.elseBranch = elseBranch
    }
    init(_ objectToCopy: IfStmt) {
        self.condition = objectToCopy.condition
        self.thenBranch = objectToCopy.thenBranch
        self.elseIfBranches = objectToCopy.elseIfBranches
        self.elseBranch = objectToCopy.elseBranch
    }

    func accept(visitor: StmtVisitor) {
        visitor.visitIfStmt(stmt: self)
    }
    func accept(visitor: StmtStmtVisitor) -> Stmt {
        visitor.visitIfStmtStmt(stmt: self)
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
    init(_ objectToCopy: OutputStmt) {
        self.expressions = objectToCopy.expressions
    }

    func accept(visitor: StmtVisitor) {
        visitor.visitOutputStmt(stmt: self)
    }
    func accept(visitor: StmtStmtVisitor) -> Stmt {
        visitor.visitOutputStmtStmt(stmt: self)
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
    init(_ objectToCopy: InputStmt) {
        self.expressions = objectToCopy.expressions
    }

    func accept(visitor: StmtVisitor) {
        visitor.visitInputStmt(stmt: self)
    }
    func accept(visitor: StmtStmtVisitor) -> Stmt {
        visitor.visitInputStmtStmt(stmt: self)
    }
    func accept(visitor: StmtStringVisitor) -> String {
        visitor.visitInputStmtString(stmt: self)
    }
}

class ReturnStmt: Stmt {
    var keyword: Token
    var value: Expr?
    var isTerminator: Bool
    
    init(keyword: Token, value: Expr?, isTerminator: Bool) {
        self.keyword = keyword
        self.value = value
        self.isTerminator = isTerminator
    }
    init(_ objectToCopy: ReturnStmt) {
        self.keyword = objectToCopy.keyword
        self.value = objectToCopy.value
        self.isTerminator = objectToCopy.isTerminator
    }

    func accept(visitor: StmtVisitor) {
        visitor.visitReturnStmt(stmt: self)
    }
    func accept(visitor: StmtStmtVisitor) -> Stmt {
        visitor.visitReturnStmtStmt(stmt: self)
    }
    func accept(visitor: StmtStringVisitor) -> String {
        visitor.visitReturnStmtString(stmt: self)
    }
}

class LoopFromStmt: Stmt {
    var variable: VariableExpr
    var lRange: Expr
    var rRange: Expr
    var body: BlockStmt
    
    init(variable: VariableExpr, lRange: Expr, rRange: Expr, body: BlockStmt) {
        self.variable = variable
        self.lRange = lRange
        self.rRange = rRange
        self.body = body
    }
    init(_ objectToCopy: LoopFromStmt) {
        self.variable = objectToCopy.variable
        self.lRange = objectToCopy.lRange
        self.rRange = objectToCopy.rRange
        self.body = objectToCopy.body
    }

    func accept(visitor: StmtVisitor) {
        visitor.visitLoopFromStmt(stmt: self)
    }
    func accept(visitor: StmtStmtVisitor) -> Stmt {
        visitor.visitLoopFromStmtStmt(stmt: self)
    }
    func accept(visitor: StmtStringVisitor) -> String {
        visitor.visitLoopFromStmtString(stmt: self)
    }
}

class WhileStmt: Stmt {
    var expression: Expr
    var body: BlockStmt
    
    init(expression: Expr, body: BlockStmt) {
        self.expression = expression
        self.body = body
    }
    init(_ objectToCopy: WhileStmt) {
        self.expression = objectToCopy.expression
        self.body = objectToCopy.body
    }

    func accept(visitor: StmtVisitor) {
        visitor.visitWhileStmt(stmt: self)
    }
    func accept(visitor: StmtStmtVisitor) -> Stmt {
        visitor.visitWhileStmtStmt(stmt: self)
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
    init(_ objectToCopy: BreakStmt) {
        self.keyword = objectToCopy.keyword
    }

    func accept(visitor: StmtVisitor) {
        visitor.visitBreakStmt(stmt: self)
    }
    func accept(visitor: StmtStmtVisitor) -> Stmt {
        visitor.visitBreakStmtStmt(stmt: self)
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
    init(_ objectToCopy: ContinueStmt) {
        self.keyword = objectToCopy.keyword
    }

    func accept(visitor: StmtVisitor) {
        visitor.visitContinueStmt(stmt: self)
    }
    func accept(visitor: StmtStmtVisitor) -> Stmt {
        visitor.visitContinueStmtStmt(stmt: self)
    }
    func accept(visitor: StmtStringVisitor) -> String {
        visitor.visitContinueStmtString(stmt: self)
    }
}

class BlockStmt: Stmt {
    var statements: [Stmt]
    var scopeIndex: Int?
    
    init(statements: [Stmt], scopeIndex: Int?) {
        self.statements = statements
        self.scopeIndex = scopeIndex
    }
    init(_ objectToCopy: BlockStmt) {
        self.statements = objectToCopy.statements
        self.scopeIndex = objectToCopy.scopeIndex
    }

    func accept(visitor: StmtVisitor) {
        visitor.visitBlockStmt(stmt: self)
    }
    func accept(visitor: StmtStmtVisitor) -> Stmt {
        visitor.visitBlockStmtStmt(stmt: self)
    }
    func accept(visitor: StmtStringVisitor) -> String {
        visitor.visitBlockStmtString(stmt: self)
    }
}

