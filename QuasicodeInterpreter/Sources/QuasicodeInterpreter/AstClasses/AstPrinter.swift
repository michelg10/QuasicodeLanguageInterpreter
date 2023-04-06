internal let astPrinterSingleton = AstPrinter()

// swiftlint:disable type_body_length
public class AstPrinter: ExprStringVisitor, StmtStringVisitor {
// swiftlint:enable type_body_length
    public init() {}
    
    var printWithTypes = false
    
    private func parenthesize(name: String, additionalProperties: [(String, String)] = [], exprs: [Expr]) -> String {
        var result = "(" + name
        if !additionalProperties.isEmpty {
            var additionalPropertyString = ""
            for additionalProperty in additionalProperties {
                if !additionalPropertyString.isEmpty {
                    additionalPropertyString += ", "
                }
                additionalPropertyString += "\(additionalProperty.0): \(additionalProperty.1)"
            }
            result += "{\(additionalPropertyString)}"
        }
        for expr in exprs {
            result += " "
            result += printAst(expr)
        }
        result += ")"
        return result
    }
    
    private func parenthesize(name: String, additionalProperties: [(String, String)] = [], exprs: Expr...) -> String {
        parenthesize(name: name, additionalProperties: additionalProperties, exprs: exprs)
    }
    
    private func indentBlockStmts(blockStmts: [Stmt]) -> String {
        var result = ""
        for blockStmt in blockStmts {
            let newRow = printAst(blockStmt)
            let newRowLines = newRow.split(separator: "\n", omittingEmptySubsequences: false)
            for newRowLine in newRowLines {
                result += "    " + newRowLine + "\n"
            }
        }
        return result
    }
    
    private func encapsulateBlock(stmts: [Stmt], scopeIndex: Int?) -> String {
        var result = ""
        result += "{ (scopeIndex: \(stringifyOptionalInt(scopeIndex)))\n"
        
        result += (stmts.isEmpty ? "\n" : indentBlockStmts(blockStmts: stmts))
        
        result += "}"
        
        return result
    }
    
    private func encapsulateBlock(blockStmt: BlockStmt) -> String {
        encapsulateBlock(stmts: blockStmt.statements, scopeIndex: blockStmt.scopeIndex)
    }
    
    private func parenthesizeBlock(name: String, exprs: [Expr], blockStmt: BlockStmt) -> String {
        var result = "(" + name
        
        for expr in exprs {
            result += " "
            result += printAst(expr)
        }
        result += " " + encapsulateBlock(stmts: blockStmt.statements, scopeIndex: blockStmt.scopeIndex)
        result += ")"
        
        return result
    }
    
    private func stringifyBoolean(_ val: Bool) -> String {
        val ? "yes" : "no"
    }
    
    private func generateTypePropertyForExpr(_ expr: Expr) -> (String, String) {
        ("QsType", printType(expr.type))
    }
    
    private func generateAdditionalTypePropertyArray(_ expr: Expr) -> [(String, String)] {
        if printWithTypes {
            return [generateTypePropertyForExpr(expr)]
        }
        return []
    }
    
    public func visitGroupingExprString(expr: GroupingExpr) -> String {
        parenthesize(name: "Group", additionalProperties: generateAdditionalTypePropertyArray(expr), exprs: expr.expression)
    }
    
    public func visitLiteralExprString(expr: LiteralExpr) -> String {
        if expr.value == nil {
            return "nil"
        }
        if expr.type is QsInt {
            return String(expr.value as! Int) + (printWithTypes ? "{QsType: int}" : "")
        }
        if expr.type is QsDouble {
            return String(expr.value as! Double) + (printWithTypes ? "{QsType: double}" : "")
        }
        if expr.type is QsBoolean {
            return ((expr.value as! Bool) ? "true" : "false") + (printWithTypes ? "{QsType: boolean}" : "")
        }
        if expr.type is QsClass {
            return "[Class \((expr.type as! QsClass).name)]"
        }
        return "[Literal of unknown type]"
    }
    
    public func visitThisExprString(expr: ThisExpr) -> String {
        parenthesize(name: "ThisExpr", additionalProperties: generateAdditionalTypePropertyArray(expr))
    }
    
    public func visitArrayLiteralExprString(expr: ArrayLiteralExpr) -> String {
        parenthesize(name: "ArrayLiteral", additionalProperties: generateAdditionalTypePropertyArray(expr), exprs: expr.values)
    }
    
    public func visitStaticClassExprString(expr: StaticClassExpr) -> String {
        parenthesize(name: "StaticClass", additionalProperties: [
            ("class", printAst(expr.classType)),
            ("classId", stringifyOptionalInt(expr.classId))
        ] + generateAdditionalTypePropertyArray(expr))
    }
    
    public func visitSuperExprString(expr: SuperExpr) -> String {
        parenthesize(name: "super", additionalProperties: [
            ("property", expr.property.lexeme),
            ("superClassId", stringifyOptionalInt(expr.superClassId)),
            ("propertyId", stringifyOptionalInt(expr.propertyId))
        ] + generateAdditionalTypePropertyArray(expr))
    }
    
    public func visitVariableExprString(expr: VariableExpr) -> String {
        parenthesize(name: expr.name.lexeme, additionalProperties: [
            ("index", stringifyOptionalInt(expr.symbolTableIndex))
        ] + generateAdditionalTypePropertyArray(expr))
    }
    
    public func visitSubscriptExprString(expr: SubscriptExpr) -> String {
        parenthesize(
            name: "Subscript",
            additionalProperties: [] + generateAdditionalTypePropertyArray(expr),
            exprs: expr.expression,
            expr.index
        )
    }
    
    public func visitCallExprString(expr: CallExpr) -> String {
        var callsFunction = "none"
        if expr.uniqueFunctionCall != nil {
            callsFunction = "Unique<\(expr.uniqueFunctionCall!)>"
        }
        if expr.polymorphicCallClassIdToIdDict != nil {
            callsFunction = "Polymorph<\(expr.polymorphicCallClassIdToIdDict!.description)>"
        }
        var exprs: [Expr] = []
        if expr.object != nil {
            exprs.append(expr.object!)
        }
        exprs.append(contentsOf: expr.arguments)
        return parenthesize(
            name: "Call",
            additionalProperties: [
                ("property", expr.property.lexeme),
                ("callsFunction", callsFunction)
            ] + generateAdditionalTypePropertyArray(expr),
            exprs: exprs
        )
    }
    
    public func visitGetExprString(expr: GetExpr) -> String {
        parenthesize(
            name: "Get",
            additionalProperties: [
                ("property", expr.property.lexeme),
                ("propertyId", stringifyOptionalInt(expr.propertyId))
            ] + generateAdditionalTypePropertyArray(expr),
            exprs: expr.object
        )
    }
    
    public func visitUnaryExprString(expr: UnaryExpr) -> String {
        parenthesize(name: expr.opr.lexeme, additionalProperties: generateAdditionalTypePropertyArray(expr), exprs: expr.right)
    }
    
    public func visitCastExprString(expr: CastExpr) -> String {
        parenthesize(
            name: "cast",
            additionalProperties: [
                ("to", printAst(expr.toType))
            ] + generateAdditionalTypePropertyArray(expr),
            exprs: expr.value
        )
    }
    
    public func visitArrayAllocationExprString(expr: ArrayAllocationExpr) -> String {
        parenthesize(
            name: "ArrayAllocate",
            additionalProperties: [
                ("ofType", printAst(expr.contains))
            ] + generateAdditionalTypePropertyArray(expr),
            exprs: expr.capacity
        )
    }
    
    public func visitClassAllocationExprString(expr: ClassAllocationExpr) -> String {
        parenthesize(
            name: "ClassAllocate",
            additionalProperties: [
                ("ofType", printAst(expr.classType)),
                ("callsFunction", stringifyOptionalInt(expr.callsFunction))
            ] + generateAdditionalTypePropertyArray(expr)
        )
    }
    
    public func visitBinaryExprString(expr: BinaryExpr) -> String {
        parenthesize(
            name:expr.opr.lexeme,
            additionalProperties: generateAdditionalTypePropertyArray(expr),
            exprs: expr.left,
            expr.right
        )
    }
    
    public func visitLogicalExprString(expr: LogicalExpr) -> String {
        parenthesize(
            name: expr.opr.lexeme,
            additionalProperties: generateAdditionalTypePropertyArray(expr),
            exprs: expr.left,
            expr.right
        )
    }
    
    public func visitVariableToSetExprString(expr: VariableToSetExpr) -> String {
        parenthesize(
            name: "VariableToSet",
            additionalProperties: [
                ("type", astTypeToString(astType: expr.annotation)),
                ("isFirstAssignment", expr.isFirstAssignment == nil ? "nil" : stringifyBoolean(expr.isFirstAssignment!))
            ] + generateAdditionalTypePropertyArray(expr),
            exprs: expr.to
        )
    }
    
    public func visitIsTypeExprString(expr: IsTypeExpr) -> String {
        parenthesize(
            name: "IsType",
            additionalProperties: [
                ("type", printAst(expr.right)),
                ("QsType", printType(expr.rightType))
            ] + generateAdditionalTypePropertyArray(expr),
            exprs: expr.left
        )
    }
    
    public func visitImplicitCastExprString(expr: ImplicitCastExpr) -> String {
        parenthesize(
            name: "ImplicitCast",
            additionalProperties: [
                ("to", printType(expr.type))
            ],
            exprs: expr.expression
        )
    }
    
    private func classField(field: AstClassField) -> String {
        "(Field \(field.isStatic ? "static" : "nostatic") \(field.name.lexeme){" +
            "index: \(stringifyOptionalInt(field.symbolTableIndex)), " +
            "type: \(astTypeToString(astType: field.astType))" +
        "}" +
        "= \(field.initializer == nil ? "NoInit" : printAst(field.initializer!))"
    }
    
    public func visitClassStmtString(stmt: ClassStmt) -> String {
        let templateParametersDescription = stmt.templateParameters == nil ? "none" : stmt.templateParameters!.reduce(into: "", { result, token in
            if result.isEmpty {
                result = token.lexeme
            }
            result += ", " + token.lexeme
        })
        
        let expandedTemplateParametersDescription = stmt.expandedTemplateParameters == nil ? "none" : stmt.expandedTemplateParameters!.reduce(
            into: "", { result, astType in
                let descriptionOfType = printAst(astType)
                if result.isEmpty {
                    result = descriptionOfType
                }
                result += ", " + descriptionOfType
            }
        )
        let classDesc = "{name: \(stmt.name.lexeme), " +
                         "id: \(stringifyOptionalInt(stmt.symbolTableIndex)), " +
                         "builtin: \(stmt.builtin), " +
                         "instanceThisId: \(stringifyOptionalInt(stmt.instanceThisSymbolTableIndex)), " +
                         "staticThisId: \(stringifyOptionalInt(stmt.staticThisSymbolTableIndex)), " +
                         "superclass: \(stmt.superclass == nil ? "none" : stmt.superclass!.name.lexeme), " +
                         "templateParameters: \(templateParametersDescription), " +
                         "expandedTemplateParameers: \(expandedTemplateParametersDescription)" +
        "}"
        var result = "(Class\(classDesc) { (scopeIndex: \(stringifyOptionalInt(stmt.scopeIndex)))\n"
        result += indentBlockStmts(blockStmts: stmt.methods)
        if !stmt.fields.isEmpty && !stmt.methods.isEmpty {
            result += "\n"
        }
        for field in stmt.fields {
            result += "    " + classField(field: field) + "\n"
        }
        if stmt.fields.isEmpty && stmt.methods.isEmpty {
            result += "\n"
        }
        result += "})"
        return result
    }
    
    public func visitMethodStmtString(stmt: MethodStmt) -> String {
        "(Method \(stmt.isStatic ? "static" : "nostatic") \(stmt.visibilityModifier == .PUBLIC ? "public" : "private") \(printAst(stmt.function)))"
    }
    
    public func visitMultiSetStmtString(stmt: MultiSetStmt) -> String {
        "(MultiSet {\n" + indentBlockStmts(blockStmts: stmt.setStmts) + "})"
    }
    
    public func visitSetStmtString(stmt: SetStmt) -> String {
        var exprs = stmt.chained
        exprs.insert(stmt.left, at: 0)
        exprs.append(stmt.value)
        return parenthesize(name: "Set", exprs: exprs)
    }
    
    private func astTypeToString(astType: AstType?) -> String {
        (astType == nil ? "NoMandatedType" : printAst(astType!))
    }
    
    private func parenthesizeFunctionParam(functionParam: AstFunctionParam) -> String {
        let initializer = functionParam.initializer == nil ? "" : " = \(printAst(functionParam.initializer!))"
        return "\(functionParam.name.lexeme){" +
                    "index: \(stringifyOptionalInt(functionParam.symbolTableIndex)), " +
                    "type: \(astTypeToString(astType: functionParam.astType))" +
        "}\(initializer)"
    }
    
    private func parenthesizeFunctionParams(functionParams: [AstFunctionParam]) -> String {
        var result = ""
        for functionParam in functionParams {
            if !result.isEmpty {
                result += ", "
            }
            result += parenthesizeFunctionParam(functionParam: functionParam)
        }
        return "(" + result + ")"
    }
    
    public func visitFunctionStmtString(stmt: FunctionStmt) -> String {
        "(Function{" +
            "returns \(stmt.annotation == nil ? "Void" : astTypeToString(astType: stmt.annotation))}" +
            "{" +
                "name: \(stmt.name.lexeme), " +
                "nameIndex: \(stringifyOptionalInt(stmt.nameSymbolTableIndex)), " +
                "index: \(stringifyOptionalInt(stmt.symbolTableIndex))" +
            "}" +
            "\(parenthesizeFunctionParams(functionParams: stmt.params)) " +
            "\(encapsulateBlock(stmts: stmt.body, scopeIndex: stmt.scopeIndex)))"
    }
    
    public func visitExpressionStmtString(stmt: ExpressionStmt) -> String {
        parenthesize(name: "Expression", exprs: stmt.expression)
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
            result += " " + ifStmt(stmt: elseIfBranch, isElseIf: true)
        }
        
        if stmt.elseBranch != nil {
            result += " Else \(encapsulateBlock(blockStmt: stmt.elseBranch!))"
        }
        
        return result
    }
    
    public func visitIfStmtString(stmt: IfStmt) -> String {
        "(\(ifStmt(stmt: stmt, isElseIf: false)))"
    }
    
    public func visitOutputStmtString(stmt: OutputStmt) -> String {
        parenthesize(
            name: "Output",
            exprs: stmt.expressions
        )
    }
    
    public func visitInputStmtString(stmt: InputStmt) -> String {
        parenthesize(
            name: "Input",
            exprs: stmt.expressions
        )
    }
    
    public func visitReturnStmtString(stmt: ReturnStmt) -> String {
        if stmt.value == nil {
            return parenthesize(name: "Return")
        }
        return parenthesize(
            name: "Return",
            exprs: stmt.value!
        )
    }
    
    public func visitLoopFromStmtString(stmt: LoopFromStmt) -> String {
        parenthesizeBlock(
            name: "LoopFrom{loopScopeIndex: \(stringifyOptionalInt(stmt.loopScopeIndex))}",
            exprs: [stmt.variable, stmt.lRange, stmt.rRange],
            blockStmt: stmt.body
        )
    }
    
    public func visitWhileStmtString(stmt: WhileStmt) -> String {
        parenthesizeBlock(
            name: "While{isDesugaredUntil: \(stmt.isDesugaredUntil)}",
            exprs: [stmt.expression],
            blockStmt: stmt.body
        )
    }
    
    public func visitBreakStmtString(stmt: BreakStmt) -> String {
        parenthesize(
            name: "Break"
        )
    }
    
    public func visitContinueStmtString(stmt: ContinueStmt) -> String {
        parenthesize(
            name: "Continue"
        )
    }
    
    public func visitBlockStmtString(stmt: BlockStmt) -> String {
        encapsulateBlock(
            stmts: stmt.statements,
            scopeIndex: stmt.scopeIndex
        )
    }
    
    public func visitExitStmtString(stmt: ExitStmt) -> String {
        parenthesize(
            name: "Exit"
        )
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
    
    public func printAst(_ stmts: [Stmt], printWithTypes: Bool) -> String {
        self.printWithTypes = printWithTypes
        var result = ""
        for stmt in stmts {
            if !result.isEmpty {
                result += "\n"
            }
            result += printAst(stmt)
        }
        return result
    }
}
