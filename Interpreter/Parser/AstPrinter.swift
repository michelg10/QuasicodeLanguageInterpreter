class AstPrinter: ExprStringVisitor, StmtStringVisitor, AstTypeStringVisitor {
    internal func visitAstTemplateTypeNameString(asttype: AstTemplateTypeName) -> String {
        return "<TemplateType \(asttype.belongingClass).\(asttype.name.lexeme)>"
    }
    
    private func parenthesize(name: String, exprs: [Expr]) -> String {
        var result = "("+name
        for expr in exprs {
            result += " "
            result += expr.accept(visitor: self)
        }
        result = result + ")"
        return result
    }
    
    private func parenthesize(name: String, exprs: Expr...) -> String {
        return parenthesize(name: name, exprs: exprs)
    }
    
    private func indentBlockStmts(blockStmts: [Stmt]) -> String {
        var result = ""
        for blockStmt in blockStmts {
            let newRow = blockStmt.accept(visitor: self)
            let newRowLines = newRow.split(separator: "\n")
            for newRowLine in newRowLines {
                result+="    "+newRowLine+"\n"
            }
            result+="\n"
        }
        return result
    }
    
    private func encapsulateBlock(blockStmts: [Stmt]) -> String {
        var result=""
        result += "{\n\(indentBlockStmts(blockStmts: blockStmts))"
        
        result+="}"
        
        return result
    }
    
    private func parenthesizeBlock(name: String, exprs: [Expr], blockStmts: [Stmt]) -> String {
        var result = "("+name
        
        for expr in exprs {
            result += " "
            result += expr.accept(visitor: self)
        }
        result += " "+encapsulateBlock(blockStmts: blockStmts)
        result+=")"
        
        return result
    }
    
    internal func visitAstArrayTypeString(asttype: AstArrayType) -> String {
        return "<Array\(asttype.contains.accept(visitor: self))>"
    }
    
    internal func visitAstClassTypeString(asttype: AstClassType) -> String {
        var templateArgumentsString = ""
        if asttype.templateArguments != nil {
            for templateArguments in asttype.templateArguments! {
                if templateArgumentsString != "" {
                    templateArgumentsString += ", "
                }
                templateArgumentsString+=templateArguments.accept(visitor: self)
            }
        }
        return "<Class \(asttype.name.lexeme)\(asttype.templateArguments == nil ? "" : "<\(templateArgumentsString)>")>"
    }
    
    internal func visitAstIntTypeString(asttype: AstIntType) -> String {
        return "<Int>"
    }
    
    internal func visitAstDoubleTypeString(asttype: AstDoubleType) -> String {
        return "<Double>"
    }
    
    internal func visitAstBooleanTypeString(asttype: AstBooleanType) -> String {
        return "<Boolean>"
    }
    
    internal func visitAstAnyTypeString(asttype: AstAnyType) -> String {
        return "<Any>"
    }
    
    internal func visitGroupingExprString(expr: GroupingExpr) -> String {
        return parenthesize(name: "group", exprs: expr.expression)
    }
    
    internal func visitLiteralExprString(expr: LiteralExpr) -> String {
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
    
    internal func visitThisExprString(expr: ThisExpr) -> String {
        return parenthesize(name: "this")
    }
    
    internal func visitArrayLiteralExprString(expr: ArrayLiteralExpr) -> String {
        return parenthesize(name: "ArrayLiteral", exprs: expr.values)
    }
    
    internal func visitSuperExprString(expr: SuperExpr) -> String {
        return parenthesize(name: "super.\(expr.keyword.lexeme)")
    }
    
    internal func visitVariableExprString(expr: VariableExpr) -> String {
        return parenthesize(name: expr.name.lexeme)
    }
    
    internal func visitSubscriptExprString(expr: SubscriptExpr) -> String {
        return parenthesize(name: "subscript", exprs: expr.expression, expr.index)
    }
    
    internal func visitCallExprString(expr: CallExpr) -> String {
        var exprs = [expr.callee]
        exprs.append(contentsOf: expr.arguments)
        return parenthesize(name: "call", exprs: exprs)
    }
    
    internal func visitGetExprString(expr: GetExpr) -> String {
        return parenthesize(name: "get \(expr.name.lexeme)", exprs: expr.object)
    }
    
    internal func visitUnaryExprString(expr: UnaryExpr) -> String {
        return parenthesize(name: expr.opr.lexeme, exprs: expr.right)
    }
    
    internal func visitCastExprString(expr: CastExpr) -> String {
        return parenthesize(name: "cast{to: \(expr.toType.accept(visitor: self))}", exprs: expr.value)
    }
    
    internal func visitArrayAllocationExprString(expr: ArrayAllocationExpr) -> String {
        return parenthesize(name: "allocate{ofType: \(expr.contains.accept(visitor: self))}", exprs: expr.capacity)
    }
    
    internal func visitClassAllocationExprString(expr: ClassAllocationExpr) -> String {
        return parenthesize(name: "allocate{ofType: \(expr.classType.accept(visitor: self))}")
    }
    
    internal func visitBinaryExprString(expr: BinaryExpr) -> String {
        return parenthesize(name: expr.opr.lexeme, exprs: expr.left, expr.right)
    }
    
    internal func visitLogicalExprString(expr: LogicalExpr) -> String {
        return parenthesize(name: expr.opr.lexeme, exprs: expr.left, expr.right)
    }
    
    internal func visitSetExprString(expr: SetExpr) -> String {
        return parenthesize(name: "Set{\(astTypeToString(astType: expr.annotation))}", exprs: expr.to, expr.value)
    }
    
    private func classField(field: ClassField) -> String {
        return "(Field \(field.isStatic ? "static" : "nostatic") \(field.name.lexeme){\(astTypeToString(astType: field.astType))} = \(field.initializer == nil ? "NoInit" : field.initializer!.accept(visitor: self))"
    }
    
    internal func visitClassStmtString(stmt: ClassStmt) -> String {
        let templateParametersDescription = stmt.templateParameters == nil ? "none" : stmt.templateParameters!.reduce("", { partialResult, next in
            if partialResult == "" {
                return next.lexeme
            }
            return partialResult+", "+next.lexeme
        })
        let classDesc = "{name: \(stmt.name.lexeme), superclass: \(stmt.superclass == nil ? "none" : stmt.superclass!.name.lexeme), templateParameters: \(templateParametersDescription)}"
        var result = "(Class\(classDesc) {\n"
        result += indentBlockStmts(blockStmts: stmt.staticMethods)
        result += indentBlockStmts(blockStmts: stmt.methods)
        for field in stmt.staticFields {
            result += "    "+classField(field: field)+"\n"
        }
        for field in stmt.fields {
            result += "    "+classField(field: field)+"\n"
        }
        result += "}"
        return result
    }
    
    internal func visitMethodStmtString(stmt: MethodStmt) -> String {
        return "(Method \(stmt.isStatic ? "static" : "nostatic") \(stmt.visibilityModifier == .PUBLIC ? "public" : "private") \(stmt.function.accept(visitor: self)))"
    }
    
    private func astTypeToString(astType: AstType?) -> String {
        return (astType == nil ? "NoMandatedType" : astType!.accept(visitor: self))
    }
    
    private func parenthesizeFunctionParam(functionParam: FunctionParam) -> String {
        let initializer = functionParam.initializer == nil ? "" : " = \(functionParam.initializer!.accept(visitor: self))"
        return "(\(functionParam.name.lexeme){\(astTypeToString(astType: functionParam.astType))}\(initializer)"
    }
    
    private func parenthesizeFunctionParams(functionParams: [FunctionParam]) -> String {
        var result = ""
        for functionParam in functionParams {
            result+=" "+parenthesizeFunctionParam(functionParam: functionParam)
        }
        return result
    }
    
    internal func visitFunctionStmtString(stmt: FunctionStmt) -> String {
        return "(Function{\(astTypeToString(astType: stmt.annotation))}{\(stmt.name.lexeme)}\(parenthesizeFunctionParams(functionParams: stmt.params)) \(encapsulateBlock(blockStmts: stmt.body)))"
    }
    
    internal func visitExpressionStmtString(stmt: ExpressionStmt) -> String {
        return parenthesize(name: "Expression", exprs: stmt.expression)
    }
    
    private func ifStmt(stmt: IfStmt, isElseIf: Bool) -> String {
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
    
    internal func visitIfStmtString(stmt: IfStmt) -> String {
        return "(\(ifStmt(stmt: stmt, isElseIf: false)))"
    }
    
    internal func visitOutputStmtString(stmt: OutputStmt) -> String {
        return parenthesize(name: "Output", exprs: stmt.expressions)
    }
    
    internal func visitInputStmtString(stmt: InputStmt) -> String {
        return parenthesize(name: "Input", exprs: stmt.expressions)
    }
    
    internal func visitReturnStmtString(stmt: ReturnStmt) -> String {
        if stmt.value == nil {
            return parenthesize(name: "Return")
        }
        return parenthesize(name: "Return", exprs: stmt.value!)
    }
    
    internal func visitLoopFromStmtString(stmt: LoopFromStmt) -> String {
        return parenthesizeBlock(name: "LoopFrom", exprs: [stmt.variable, stmt.lRange, stmt.rRange], blockStmts: stmt.statements)
    }
    
    internal func visitWhileStmtString(stmt: WhileStmt) -> String {
        return parenthesizeBlock(name: "While", exprs: [stmt.expression], blockStmts: stmt.statements)
    }
    
    internal func visitBreakStmtString(stmt: BreakStmt) -> String {
        return parenthesize(name: "Break")
    }
    
    internal func visitContinueStmtString(stmt: ContinueStmt) -> String {
        return parenthesize(name: "Continue")
    }
    
    func printAst(_ astType: AstType) -> String {
        astType.accept(visitor: self)
    }
    
    func printAst(_ expr: Expr) -> String {
        expr.accept(visitor: self)
    }
    
    func printAst(_ stmt: Stmt) -> String {
        stmt.accept(visitor: self)
    }
    
    func printAst(_ stmts: [Stmt]) -> String {
        var result = ""
        for stmt in stmts {
            if result != "" {
                result+="\n"
            }
            result+=printAst(stmt)
        }
        return result
    }
}
