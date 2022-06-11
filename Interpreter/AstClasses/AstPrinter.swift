class AstPrinter: ExprStringVisitor, StmtStringVisitor {
    private func parenthesize(name: String, exprs: [Expr]) -> String {
        var result = "("+name
        for expr in exprs {
            result += " "
            result += printAst(expr)
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
            let newRow = printAst(blockStmt)
            let newRowLines = newRow.split(separator: "\n")
            for newRowLine in newRowLines {
                result+="    "+newRowLine+"\n"
            }
            result+="\n"
        }
        return result
    }
    
    private func encapsulateBlock(stmts: [Stmt], scopeIndex: Int?) -> String {
        var result=""
        result += "{ (scopeIndex: \(stringifyOptionalInt(scopeIndex)))\n\(indentBlockStmts(blockStmts: stmts))"
        
        result+="}"
        
        return result
    }
    
    private func encapsulateBlock(blockStmt: BlockStmt) -> String {
        return encapsulateBlock(stmts: blockStmt.statements, scopeIndex: blockStmt.scopeIndex)
    }
    
    private func parenthesizeBlock(name: String, exprs: [Expr], blockStmt: BlockStmt) -> String {
        var result = "("+name
        
        for expr in exprs {
            result += " "
            result += printAst(expr)
        }
        result += " "+encapsulateBlock(stmts: blockStmt.statements, scopeIndex: blockStmt.scopeIndex)
        result+=")"
        
        return result
    }
    
    private func stringifyBoolean(_ val: Bool) -> String {
        return (val ? "yes" : "no")
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
    
    internal func visitStaticClassExprString(expr: StaticClassExpr) -> String {
        return parenthesize(name: "StaticClass{\(printAst(expr.classType)) \(expr.property.lexeme)}")
    }
    
    internal func visitSuperExprString(expr: SuperExpr) -> String {
        return parenthesize(name: "super.\(expr.property.lexeme)")
    }
    
    internal func visitVariableExprString(expr: VariableExpr) -> String {
        return parenthesize(name: expr.name.lexeme+"{index: \(stringifyOptionalInt(expr.symbolTableIndex))}")
    }
    
    internal func visitSubscriptExprString(expr: SubscriptExpr) -> String {
        return parenthesize(name: "subscript", exprs: expr.expression, expr.index)
    }
    
    internal func visitCallExprString(expr: CallExpr) -> String {
        var callsFunction = "none"
        if expr.uniqueFunctionCall != nil {
            callsFunction = "Unique<\(expr.uniqueFunctionCall!)>"
        }
        if expr.polymorphicCallClassIdToIdDict != nil {
            callsFunction = "Polymorph<\(expr.polymorphicCallClassIdToIdDict!.description)>"
        }
        var exprs = [expr.callee]
        exprs.append(contentsOf: expr.arguments)
        return parenthesize(name: "call{callsFunction: \(callsFunction)}", exprs: exprs)
    }
    
    internal func visitGetExprString(expr: GetExpr) -> String {
        return parenthesize(name: "get \(expr.name.lexeme)", exprs: expr.object)
    }
    
    internal func visitUnaryExprString(expr: UnaryExpr) -> String {
        return parenthesize(name: expr.opr.lexeme, exprs: expr.right)
    }
    
    internal func visitCastExprString(expr: CastExpr) -> String {
        return parenthesize(name: "cast{to: \(printAst(expr.toType))}", exprs: expr.value)
    }
    
    internal func visitArrayAllocationExprString(expr: ArrayAllocationExpr) -> String {
        return parenthesize(name: "allocate{ofType: \(printAst(expr.contains))}", exprs: expr.capacity)
    }
    
    internal func visitClassAllocationExprString(expr: ClassAllocationExpr) -> String {
        return parenthesize(name: "allocate{ofType: \(printAst(expr.classType))}")
    }
    
    internal func visitBinaryExprString(expr: BinaryExpr) -> String {
        return parenthesize(name: expr.opr.lexeme, exprs: expr.left, expr.right)
    }
    
    internal func visitLogicalExprString(expr: LogicalExpr) -> String {
        return parenthesize(name: expr.opr.lexeme, exprs: expr.left, expr.right)
    }
    
    internal func visitSetExprString(expr: SetExpr) -> String {
        return parenthesize(name: "Set", exprs: expr.to, expr.value)
    }
    
    func visitAssignExprString(expr: AssignExpr) -> String {
        return parenthesize(name: "Assign{type: \(astTypeToString(astType: expr.annotation)), isFirstAssignment: \(expr.isFirstAssignment == nil ? "nil" : stringifyBoolean(expr.isFirstAssignment!))}", exprs: expr.to, expr.value)
    }
    
    func visitIsTypeExprString(expr: IsTypeExpr) -> String {
        return parenthesize(name: "IsType{type: \(printAst(expr.right))", exprs: expr.left)
    }
    
    func visitImplicitCastExprString(expr: ImplicitCastExpr) -> String {
        return parenthesize(name: "ImplicitCast{to: \(printType(expr.type))}", exprs: expr.expression)
    }
    
    private func classField(field: ClassField) -> String {
        return "(Field \(field.isStatic ? "static" : "nostatic") \(field.name.lexeme){\(astTypeToString(astType: field.astType))} = \(field.initializer == nil ? "NoInit" : printAst(field.initializer!))"
    }
    
    internal func visitClassStmtString(stmt: ClassStmt) -> String {
        let templateParametersDescription = stmt.templateParameters == nil ? "none" : stmt.templateParameters!.reduce("", { partialResult, next in
            if partialResult == "" {
                return next.lexeme
            }
            return partialResult+", "+next.lexeme
        })
        let expandedTemplateParametersDescription = stmt.expandedTemplateParameters == nil ? "none" : stmt.expandedTemplateParameters!.reduce("", { partialResult, next in
            let nextDesc = printAst(next)
            if partialResult == "" {
                return nextDesc
            }
            return partialResult+", "+nextDesc
        })
        let classDesc = "{name: \(stmt.name.lexeme), id: \(stringifyOptionalInt(stmt.symbolTableIndex)), thisId: \(stringifyOptionalInt(stmt.thisSymbolTableIndex)), superclass: \(stmt.superclass == nil ? "none" : stmt.superclass!.name.lexeme), templateParameters: \(templateParametersDescription), expandedTemplateParameers: \(expandedTemplateParametersDescription)}"
        var result = "(Class\(classDesc) { (scopeIndex: \(stringifyOptionalInt(stmt.scopeIndex)))\n"
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
        return "(Method \(stmt.isStatic ? "static" : "nostatic") \(stmt.visibilityModifier == .PUBLIC ? "public" : "private") \(printAst(stmt.function)))"
    }
    
    private func astTypeToString(astType: AstType?) -> String {
        return (astType == nil ? "NoMandatedType" : printAst(astType!))
    }
    
    private func parenthesizeFunctionParam(functionParam: FunctionParam) -> String {
        let initializer = functionParam.initializer == nil ? "" : " = \(printAst(functionParam.initializer!))"
        return "(\(functionParam.name.lexeme){index: \(stringifyOptionalInt(functionParam.symbolTableIndex)), type: \(astTypeToString(astType: functionParam.astType))}\(initializer)"
    }
    
    private func parenthesizeFunctionParams(functionParams: [FunctionParam]) -> String {
        var result = ""
        for functionParam in functionParams {
            result+=" "+parenthesizeFunctionParam(functionParam: functionParam)
        }
        return result
    }
    
    internal func visitFunctionStmtString(stmt: FunctionStmt) -> String {
        return "(Function{\(astTypeToString(astType: stmt.annotation))}{name: \(stmt.name.lexeme), nameIndex: \(stringifyOptionalInt(stmt.nameSymbolTableIndex)), index: \(stringifyOptionalInt(stmt.symbolTableIndex))}\(parenthesizeFunctionParams(functionParams: stmt.params)) \(encapsulateBlock(stmts: stmt.body, scopeIndex: stmt.scopeIndex))"
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
        
        result += printAst(stmt.condition)
        
        result += " \(encapsulateBlock(blockStmt: stmt.thenBranch))"
        
        for elseIfBranch in stmt.elseIfBranches {
            result += " "+ifStmt(stmt: elseIfBranch, isElseIf: true)
        }
        
        if stmt.elseBranch != nil {
            result += " Else \(encapsulateBlock(blockStmt: stmt.elseBranch!))"
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
        return parenthesize(name: "Return{isTerminator: \(stringifyBoolean(stmt.isTerminator))}", exprs: stmt.value!)
    }
    
    internal func visitLoopFromStmtString(stmt: LoopFromStmt) -> String {
        return parenthesizeBlock(name: "LoopFrom", exprs: [stmt.variable, stmt.lRange, stmt.rRange], blockStmt: stmt.body)
    }
    
    internal func visitWhileStmtString(stmt: WhileStmt) -> String {
        return parenthesizeBlock(name: "While", exprs: [stmt.expression], blockStmt: stmt.body)
    }
    
    internal func visitBreakStmtString(stmt: BreakStmt) -> String {
        return parenthesize(name: "Break")
    }
    
    internal func visitContinueStmtString(stmt: ContinueStmt) -> String {
        return parenthesize(name: "Continue")
    }
    
    func visitBlockStmtString(stmt: BlockStmt) -> String {
        return encapsulateBlock(stmts: stmt.statements, scopeIndex: stmt.scopeIndex)
    }
    
    func printAst(_ astType: AstType) -> String {
        astTypeToStringSingleton.stringify(astType)
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
