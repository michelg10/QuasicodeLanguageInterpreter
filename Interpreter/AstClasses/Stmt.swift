// swiftlint:disable all
public protocol Stmt {
    func accept(visitor: StmtVisitor)
    func accept(visitor: StmtThrowVisitor) throws
    func accept(visitor: StmtStmtVisitor) -> Stmt
    func accept(visitor: StmtStringVisitor) -> String
}

public protocol StmtVisitor {
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
    func visitExitStmt(stmt: ExitStmt) 
    func visitMultiSetStmt(stmt: MultiSetStmt) 
    func visitSetStmt(stmt: SetStmt) 
}

public protocol StmtThrowVisitor {
    func visitClassStmt(stmt: ClassStmt) throws 
    func visitMethodStmt(stmt: MethodStmt) throws 
    func visitFunctionStmt(stmt: FunctionStmt) throws 
    func visitExpressionStmt(stmt: ExpressionStmt) throws 
    func visitIfStmt(stmt: IfStmt) throws 
    func visitOutputStmt(stmt: OutputStmt) throws 
    func visitInputStmt(stmt: InputStmt) throws 
    func visitReturnStmt(stmt: ReturnStmt) throws 
    func visitLoopFromStmt(stmt: LoopFromStmt) throws 
    func visitWhileStmt(stmt: WhileStmt) throws 
    func visitBreakStmt(stmt: BreakStmt) throws 
    func visitContinueStmt(stmt: ContinueStmt) throws 
    func visitBlockStmt(stmt: BlockStmt) throws 
    func visitExitStmt(stmt: ExitStmt) throws 
    func visitMultiSetStmt(stmt: MultiSetStmt) throws 
    func visitSetStmt(stmt: SetStmt) throws 
}

public protocol StmtStmtVisitor {
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
    func visitExitStmtStmt(stmt: ExitStmt) -> Stmt
    func visitMultiSetStmtStmt(stmt: MultiSetStmt) -> Stmt
    func visitSetStmtStmt(stmt: SetStmt) -> Stmt
}

public protocol StmtStringVisitor {
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
    func visitExitStmtString(stmt: ExitStmt) -> String
    func visitMultiSetStmtString(stmt: MultiSetStmt) -> String
    func visitSetStmtString(stmt: SetStmt) -> String
}

public class ClassStmt: Stmt {
    public var keyword: Token
    public var name: Token
    public var symbolTableIndex: Int?
    public var instanceThisSymbolTableIndex: Int?
    public var staticThisSymbolTableIndex: Int?
    public var scopeIndex: Int?
    public var templateParameters: [Token]?
    public var expandedTemplateParameters: [AstType]?
    public var superclass: AstClassType?
    public var methods: [MethodStmt]
    public var fields: [AstClassField]
    
    init(keyword: Token, name: Token, symbolTableIndex: Int?, instanceThisSymbolTableIndex: Int?, staticThisSymbolTableIndex: Int?, scopeIndex: Int?, templateParameters: [Token]?, expandedTemplateParameters: [AstType]?, superclass: AstClassType?, methods: [MethodStmt], fields: [AstClassField]) {
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
        self.fields = fields
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
        self.fields = objectToCopy.fields
    }

    public func accept(visitor: StmtVisitor) {
        visitor.visitClassStmt(stmt: self)
    }
    public func accept(visitor: StmtThrowVisitor) throws {
        try visitor.visitClassStmt(stmt: self)
    }
    public func accept(visitor: StmtStmtVisitor) -> Stmt {
        visitor.visitClassStmtStmt(stmt: self)
    }
    public func accept(visitor: StmtStringVisitor) -> String {
        visitor.visitClassStmtString(stmt: self)
    }
}

public class MethodStmt: Stmt {
    public var isStatic: Bool
    public var staticKeyword: Token?
    public var visibilityModifier: VisibilityModifier
    public var function: FunctionStmt
    
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

    public func accept(visitor: StmtVisitor) {
        visitor.visitMethodStmt(stmt: self)
    }
    public func accept(visitor: StmtThrowVisitor) throws {
        try visitor.visitMethodStmt(stmt: self)
    }
    public func accept(visitor: StmtStmtVisitor) -> Stmt {
        visitor.visitMethodStmtStmt(stmt: self)
    }
    public func accept(visitor: StmtStringVisitor) -> String {
        visitor.visitMethodStmtString(stmt: self)
    }
}

public class FunctionStmt: Stmt {
    public var keyword: Token
    public var name: Token
    public var symbolTableIndex: Int?
    public var nameSymbolTableIndex: Int?
    public var scopeIndex: Int?
    public var params: [AstFunctionParam]
    public var annotation: AstType?
    public var body: [Stmt]
    public var endOfFunction: Token
    
    init(keyword: Token, name: Token, symbolTableIndex: Int?, nameSymbolTableIndex: Int?, scopeIndex: Int?, params: [AstFunctionParam], annotation: AstType?, body: [Stmt], endOfFunction: Token) {
        self.keyword = keyword
        self.name = name
        self.symbolTableIndex = symbolTableIndex
        self.nameSymbolTableIndex = nameSymbolTableIndex
        self.scopeIndex = scopeIndex
        self.params = params
        self.annotation = annotation
        self.body = body
        self.endOfFunction = endOfFunction
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
        self.endOfFunction = objectToCopy.endOfFunction
    }

    public func accept(visitor: StmtVisitor) {
        visitor.visitFunctionStmt(stmt: self)
    }
    public func accept(visitor: StmtThrowVisitor) throws {
        try visitor.visitFunctionStmt(stmt: self)
    }
    public func accept(visitor: StmtStmtVisitor) -> Stmt {
        visitor.visitFunctionStmtStmt(stmt: self)
    }
    public func accept(visitor: StmtStringVisitor) -> String {
        visitor.visitFunctionStmtString(stmt: self)
    }
}

public class ExpressionStmt: Stmt {
    public var expression: Expr
    
    init(expression: Expr) {
        self.expression = expression
    }
    init(_ objectToCopy: ExpressionStmt) {
        self.expression = objectToCopy.expression
    }

    public func accept(visitor: StmtVisitor) {
        visitor.visitExpressionStmt(stmt: self)
    }
    public func accept(visitor: StmtThrowVisitor) throws {
        try visitor.visitExpressionStmt(stmt: self)
    }
    public func accept(visitor: StmtStmtVisitor) -> Stmt {
        visitor.visitExpressionStmtStmt(stmt: self)
    }
    public func accept(visitor: StmtStringVisitor) -> String {
        visitor.visitExpressionStmtString(stmt: self)
    }
}

public class IfStmt: Stmt {
    public var condition: Expr
    public var thenBranch: BlockStmt
    public var elseIfBranches: [IfStmt]
    public var elseBranch: BlockStmt?
    
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

    public func accept(visitor: StmtVisitor) {
        visitor.visitIfStmt(stmt: self)
    }
    public func accept(visitor: StmtThrowVisitor) throws {
        try visitor.visitIfStmt(stmt: self)
    }
    public func accept(visitor: StmtStmtVisitor) -> Stmt {
        visitor.visitIfStmtStmt(stmt: self)
    }
    public func accept(visitor: StmtStringVisitor) -> String {
        visitor.visitIfStmtString(stmt: self)
    }
}

public class OutputStmt: Stmt {
    public var expressions: [Expr]
    
    init(expressions: [Expr]) {
        self.expressions = expressions
    }
    init(_ objectToCopy: OutputStmt) {
        self.expressions = objectToCopy.expressions
    }

    public func accept(visitor: StmtVisitor) {
        visitor.visitOutputStmt(stmt: self)
    }
    public func accept(visitor: StmtThrowVisitor) throws {
        try visitor.visitOutputStmt(stmt: self)
    }
    public func accept(visitor: StmtStmtVisitor) -> Stmt {
        visitor.visitOutputStmtStmt(stmt: self)
    }
    public func accept(visitor: StmtStringVisitor) -> String {
        visitor.visitOutputStmtString(stmt: self)
    }
}

public class InputStmt: Stmt {
    public var expressions: [Expr]
    
    init(expressions: [Expr]) {
        self.expressions = expressions
    }
    init(_ objectToCopy: InputStmt) {
        self.expressions = objectToCopy.expressions
    }

    public func accept(visitor: StmtVisitor) {
        visitor.visitInputStmt(stmt: self)
    }
    public func accept(visitor: StmtThrowVisitor) throws {
        try visitor.visitInputStmt(stmt: self)
    }
    public func accept(visitor: StmtStmtVisitor) -> Stmt {
        visitor.visitInputStmtStmt(stmt: self)
    }
    public func accept(visitor: StmtStringVisitor) -> String {
        visitor.visitInputStmtString(stmt: self)
    }
}

public class ReturnStmt: Stmt {
    public var keyword: Token
    public var value: Expr?
    public var isTerminator: Bool
    
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

    public func accept(visitor: StmtVisitor) {
        visitor.visitReturnStmt(stmt: self)
    }
    public func accept(visitor: StmtThrowVisitor) throws {
        try visitor.visitReturnStmt(stmt: self)
    }
    public func accept(visitor: StmtStmtVisitor) -> Stmt {
        visitor.visitReturnStmtStmt(stmt: self)
    }
    public func accept(visitor: StmtStringVisitor) -> String {
        visitor.visitReturnStmtString(stmt: self)
    }
}

public class LoopFromStmt: Stmt {
    public var variable: VariableExpr
    public var lRange: Expr
    public var rRange: Expr
    public var body: BlockStmt
    
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

    public func accept(visitor: StmtVisitor) {
        visitor.visitLoopFromStmt(stmt: self)
    }
    public func accept(visitor: StmtThrowVisitor) throws {
        try visitor.visitLoopFromStmt(stmt: self)
    }
    public func accept(visitor: StmtStmtVisitor) -> Stmt {
        visitor.visitLoopFromStmtStmt(stmt: self)
    }
    public func accept(visitor: StmtStringVisitor) -> String {
        visitor.visitLoopFromStmtString(stmt: self)
    }
}

public class WhileStmt: Stmt {
    public var expression: Expr
    public var body: BlockStmt
    
    init(expression: Expr, body: BlockStmt) {
        self.expression = expression
        self.body = body
    }
    init(_ objectToCopy: WhileStmt) {
        self.expression = objectToCopy.expression
        self.body = objectToCopy.body
    }

    public func accept(visitor: StmtVisitor) {
        visitor.visitWhileStmt(stmt: self)
    }
    public func accept(visitor: StmtThrowVisitor) throws {
        try visitor.visitWhileStmt(stmt: self)
    }
    public func accept(visitor: StmtStmtVisitor) -> Stmt {
        visitor.visitWhileStmtStmt(stmt: self)
    }
    public func accept(visitor: StmtStringVisitor) -> String {
        visitor.visitWhileStmtString(stmt: self)
    }
}

public class BreakStmt: Stmt {
    public var keyword: Token
    
    init(keyword: Token) {
        self.keyword = keyword
    }
    init(_ objectToCopy: BreakStmt) {
        self.keyword = objectToCopy.keyword
    }

    public func accept(visitor: StmtVisitor) {
        visitor.visitBreakStmt(stmt: self)
    }
    public func accept(visitor: StmtThrowVisitor) throws {
        try visitor.visitBreakStmt(stmt: self)
    }
    public func accept(visitor: StmtStmtVisitor) -> Stmt {
        visitor.visitBreakStmtStmt(stmt: self)
    }
    public func accept(visitor: StmtStringVisitor) -> String {
        visitor.visitBreakStmtString(stmt: self)
    }
}

public class ContinueStmt: Stmt {
    public var keyword: Token
    
    init(keyword: Token) {
        self.keyword = keyword
    }
    init(_ objectToCopy: ContinueStmt) {
        self.keyword = objectToCopy.keyword
    }

    public func accept(visitor: StmtVisitor) {
        visitor.visitContinueStmt(stmt: self)
    }
    public func accept(visitor: StmtThrowVisitor) throws {
        try visitor.visitContinueStmt(stmt: self)
    }
    public func accept(visitor: StmtStmtVisitor) -> Stmt {
        visitor.visitContinueStmtStmt(stmt: self)
    }
    public func accept(visitor: StmtStringVisitor) -> String {
        visitor.visitContinueStmtString(stmt: self)
    }
}

public class BlockStmt: Stmt {
    public var statements: [Stmt]
    public var scopeIndex: Int?
    
    init(statements: [Stmt], scopeIndex: Int?) {
        self.statements = statements
        self.scopeIndex = scopeIndex
    }
    init(_ objectToCopy: BlockStmt) {
        self.statements = objectToCopy.statements
        self.scopeIndex = objectToCopy.scopeIndex
    }

    public func accept(visitor: StmtVisitor) {
        visitor.visitBlockStmt(stmt: self)
    }
    public func accept(visitor: StmtThrowVisitor) throws {
        try visitor.visitBlockStmt(stmt: self)
    }
    public func accept(visitor: StmtStmtVisitor) -> Stmt {
        visitor.visitBlockStmtStmt(stmt: self)
    }
    public func accept(visitor: StmtStringVisitor) -> String {
        visitor.visitBlockStmtString(stmt: self)
    }
}

public class ExitStmt: Stmt {
    public var keyword: Token
    
    init(keyword: Token) {
        self.keyword = keyword
    }
    init(_ objectToCopy: ExitStmt) {
        self.keyword = objectToCopy.keyword
    }

    public func accept(visitor: StmtVisitor) {
        visitor.visitExitStmt(stmt: self)
    }
    public func accept(visitor: StmtThrowVisitor) throws {
        try visitor.visitExitStmt(stmt: self)
    }
    public func accept(visitor: StmtStmtVisitor) -> Stmt {
        visitor.visitExitStmtStmt(stmt: self)
    }
    public func accept(visitor: StmtStringVisitor) -> String {
        visitor.visitExitStmtString(stmt: self)
    }
}

public class MultiSetStmt: Stmt {
    public var setStmts: [SetStmt]
    
    init(setStmts: [SetStmt]) {
        self.setStmts = setStmts
    }
    init(_ objectToCopy: MultiSetStmt) {
        self.setStmts = objectToCopy.setStmts
    }

    public func accept(visitor: StmtVisitor) {
        visitor.visitMultiSetStmt(stmt: self)
    }
    public func accept(visitor: StmtThrowVisitor) throws {
        try visitor.visitMultiSetStmt(stmt: self)
    }
    public func accept(visitor: StmtStmtVisitor) -> Stmt {
        visitor.visitMultiSetStmtStmt(stmt: self)
    }
    public func accept(visitor: StmtStringVisitor) -> String {
        visitor.visitMultiSetStmtString(stmt: self)
    }
}

public class SetStmt: Stmt {
    public var left: Expr
    public var chained: [Expr]
    public var value: Expr
    
    init(left: Expr, chained: [Expr], value: Expr) {
        self.left = left
        self.chained = chained
        self.value = value
    }
    init(_ objectToCopy: SetStmt) {
        self.left = objectToCopy.left
        self.chained = objectToCopy.chained
        self.value = objectToCopy.value
    }

    public func accept(visitor: StmtVisitor) {
        visitor.visitSetStmt(stmt: self)
    }
    public func accept(visitor: StmtThrowVisitor) throws {
        try visitor.visitSetStmt(stmt: self)
    }
    public func accept(visitor: StmtStmtVisitor) -> Stmt {
        visitor.visitSetStmtStmt(stmt: self)
    }
    public func accept(visitor: StmtStringVisitor) -> String {
        visitor.visitSetStmtString(stmt: self)
    }
}

