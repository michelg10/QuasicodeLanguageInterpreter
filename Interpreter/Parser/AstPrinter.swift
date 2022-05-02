class AstPrinter: ExprStringVisitor, StmtStringVisitor, AstTypeStringVisitor {
    func parenthesize(name: String, exprs: [Expr]) -> String {
        var result = "("+name
        for expr in exprs {
            result += " "
            result += expr.accept(visitor: self)
        }
        result = result + ")"
        return result
    }
    
    func parenthesize(name: String, exprs: Expr...) -> String {
        return parenthesize(name: name, exprs: exprs)
    }
    
    func encapsulateBlock(blockStmts: [Stmt]) -> String {
        var result=""
        result += "{\n"
        
        for blockStmt in blockStmts {
            let newRow = blockStmt.accept(visitor: self)
            let newRowLines = newRow.split(separator: "\n")
            for newRowLine in newRowLines {
                result+="    "+newRowLine+"\n"
            }
            result+="\n"
        }
        result+="}"
        
        return result
    }
    
    func parenthesizeBlock(name: String, exprs: [Expr], blockStmts: [Stmt]) -> String {
        var result = "("+name
        
        for expr in exprs {
            result += " "
            result += expr.accept(visitor: self)
        }
        result += encapsulateBlock(blockStmts: blockStmts)
        result+=")"
        
        return result
    }
    
    func visitAstArrayTypeString(asttype: AstArrayType) -> String {
        return "<Array\(asttype.contains.accept(visitor: self))>"
    }
    
    func visitAstClassTypeString(asttype: AstClassType) -> String {
        return "<Class\(asttype.name.lexeme)\(asttype.templateType == nil ? "" : "<\(asttype.templateType!.accept(visitor: self))>")>"
    }
    
    func visitAstIntTypeString(asttype: AstIntType) -> String {
        return "<Int>"
    }
    
    func visitAstDoubleTypeString(asttype: AstDoubleType) -> String {
        return "<Double>"
    }
    
    func visitAstBooleanTypeString(asttype: AstBooleanType) -> String {
        return "<Boolean>"
    }
    
    func visitAstAnyTypeString(asttype: AstAnyType) -> String {
        return "<Any>"
    }
    
    func visitGroupingExprString(expr: GroupingExpr) -> String {
        return parenthesize(name: "group", exprs: expr.expression)
    }
    
    func visitLiteralExprString(expr: LiteralExpr) -> String {
        if expr.value == nil {
            return "nil"
        }
        if expr.type is QsInt {
            return String(expr.value as! Int)
        }
        if expr.type is QsDouble {
            return String(expr.value as! Double)
        }
        if expr.type is QsBoolean {
            return (expr.value as! Bool) ? "true" : "false"
        }
        if expr.type is QsClass {
            return "[Class \((expr.type as! QsClass).name)]"
        }
        return "[Literal of unknown type]"
    }
    
    func visitThisExprString(expr: ThisExpr) -> String {
        return parenthesize(name: "this")
    }
    
    func visitArrayLiteralExprString(expr: ArrayLiteralExpr) -> String {
        return parenthesize(name: "ArrayLiteral", exprs: expr.values)
    }
    
    func visitSuperExprString(expr: SuperExpr) -> String {
        return parenthesize(name: "super.\(expr.keyword.lexeme)")
    }
    
    func visitVariableExprString(expr: VariableExpr) -> String {
        return parenthesize(name: expr.name.lexeme)
    }
    
    func visitSubscriptExprString(expr: SubscriptExpr) -> String {
        return parenthesize(name: "subscript", exprs: expr.expression, expr.index)
    }
    
    func visitCallExprString(expr: CallExpr) -> String {
        var exprs = [expr.callee]
        exprs.append(contentsOf: expr.arguments)
        return parenthesize(name: "call", exprs: exprs)
    }
    
    func visitGetExprString(expr: GetExpr) -> String {
        return parenthesize(name: "get \(expr.name.lexeme)", exprs: expr.object)
    }
    
    func visitUnaryExprString(expr: UnaryExpr) -> String {
        return parenthesize(name: expr.opr.lexeme, exprs: expr.right)
    }
    
    func visitCastExprString(expr: CastExpr) -> String {
        return parenthesize(name: "cast{to: \(expr.toType.accept(visitor: self))}", exprs: expr.value)
    }
    
    func visitArrayAllocationExprString(expr: ArrayAllocationExpr) -> String {
        return parenthesize(name: "allocate{ofType: \(expr.contains.accept(visitor: self))}", exprs: expr.capacity)
    }
    
    func visitClassAllocationExprString(expr: ClassAllocationExpr) -> String {
        return parenthesize(name: "allocate{ofType: \(expr.classType.accept(visitor: self))}")
    }
    
    func visitBinaryExprString(expr: BinaryExpr) -> String {
        return parenthesize(name: expr.opr.lexeme, exprs: expr.left, expr.right)
    }
    
    func visitLogicalExprString(expr: LogicalExpr) -> String {
        return parenthesize(name: expr.opr.lexeme, exprs: expr.left, expr.right)
    }
    
    func visitSetExprString(expr: SetExpr) -> String {
        return parenthesize(name: "Set{\(expr.annotation == nil ? "NoMandatedType" : expr.annotation!.accept(visitor: self))}", exprs: expr.to, expr.value)
    }
    
    func visitClassStmtString(stmt: ClassStmt) -> String {
        // TODO: this
        return parenthesize(name: "Class{name: \(stmt.name.lexeme), superclass: \(stmt.superclass == nil ? "none" : stmt.superclass!.name.lexeme)}")
    }
    
    func visitMethodStmtString(stmt: MethodStmt) -> String {
        
        // TODO: this
        return ""
    }
    
    func visitFunctionStmtString(stmt: FunctionStmt) -> String {
        
        // TODO: this
        return ""
    }
    
    func visitExpressionStmtString(stmt: ExpressionStmt) -> String {
        return parenthesize(name: "Expression", exprs: stmt.expression)
    }
    
    func ifStmt(stmt: IfStmt, isElseIf: Bool) -> String {
        var result = ""
        if isElseIf {
            result = "Else If "
        } else {
            result = "If "
        }
        
        result += stmt.condition.accept(visitor: self)
        
        result += " \(encapsulateBlock(blockStmts: stmt.thenBranch))"
        
        for elseIfBranch in stmt.elseIfBranches {
            result += " "+ifStmt(stmt: elseIfBranch, isElseIf: true)
        }
        
        if stmt.elseBranch != nil {
            result += " Else \(encapsulateBlock(blockStmts: stmt.elseBranch!))"
        }
        
        return result
    }
    
    func visitIfStmtString(stmt: IfStmt) -> String {
        return "(\(ifStmt(stmt: stmt, isElseIf: false)))"
    }
    
    func visitOutputStmtString(stmt: OutputStmt) -> String {
        return parenthesize(name: "Output", exprs: stmt.expressions)
    }
    
    func visitInputStmtString(stmt: InputStmt) -> String {
        return parenthesize(name: "Input", exprs: stmt.expressions)
    }
    
    func visitReturnStmtString(stmt: ReturnStmt) -> String {
        return parenthesize(name: "Return", exprs: stmt.value)
    }
    
    func visitLoopFromStmtString(stmt: LoopFromStmt) -> String {
        return parenthesizeBlock(name: "LoopFrom", exprs: [stmt.variable, stmt.lRange, stmt.rRange], blockStmts: stmt.statements)
    }
    
    func visitWhileStmtString(stmt: WhileStmt) -> String {
        return parenthesizeBlock(name: "While", exprs: [stmt.expression], blockStmts: stmt.statements)
    }
    
    func visitBreakStmtString(stmt: BreakStmt) -> String {
        return parenthesize(name: "Break")
    }
    
    func visitContinueStmtString(stmt: ContinueStmt) -> String {
        return parenthesize(name: "Continue")
    }
    
    func printAst(expr: Expr) -> String {
        expr.accept(visitor: self)
    }
    
    func printAst(stmt: Stmt) -> String {
        stmt.accept(visitor: self)
    }
}
