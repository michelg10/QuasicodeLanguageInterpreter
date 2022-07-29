class Compiler: ExprVisitor, StmtVisitor {
    var compilingChunk: UnsafeMutablePointer<Chunk>!
    var symbolTable: SymbolTables = .init()
    var stringClass: QsType = QsVoidType()
    
    internal func currentChunk() -> UnsafeMutablePointer<Chunk>! {
        return compilingChunk
    }
    
    internal func visitGroupingExpr(expr: GroupingExpr) {
        compile(expr.expression)
    }
    
    private func writeInstructionToChunk(op: OpCode, expr: Expr) {
        Interpreter.writeInstructionToChunk(chunk: currentChunk(), op: op, line: expr.startLocation.line)
    }
    
    private func writeLongToChunk(data: UInt64, expr: Expr) {
        Interpreter.writeLongToChunk(chunk: currentChunk(), data: data, line: expr.startLocation.line)
    }
    
    internal func visitLiteralExpr(expr: LiteralExpr) {
        // TODO: Strings
        switch expr.type! {
        case is QsInt:
            writeInstructionToChunk(op: .OP_loadEmbeddedLongConstant, expr: expr)
            writeLongToChunk(data: UInt64(expr.value as! Int), expr: expr)
        case is QsDouble:
            writeInstructionToChunk(op: .OP_loadEmbeddedLongConstant, expr: expr)
            writeLongToChunk(data: (expr.value as! Double).bitPattern, expr: expr)
        case is QsBoolean:
            let value = expr.value as! Bool
            if value {
                writeInstructionToChunk(op: .OP_true, expr: expr)
            } else {
                writeInstructionToChunk(op: .OP_false, expr: expr)
            }
        case is QsClass:
            print("ohnoe")
        default:
            assertionFailure("Unexpected literal type \(printType(expr.type))")
        }
    }
    
    internal func visitArrayLiteralExpr(expr: ArrayLiteralExpr) {
        
    }
    
    internal func visitStaticClassExpr(expr: StaticClassExpr) {
        
    }
    
    internal func visitThisExpr(expr: ThisExpr) {
        
    }
    
    internal func visitSuperExpr(expr: SuperExpr) {
        
    }
    
    internal func visitVariableExpr(expr: VariableExpr) {
        
    }
    
    internal func visitSubscriptExpr(expr: SubscriptExpr) {
        
    }
    
    internal func visitCallExpr(expr: CallExpr) {
        
    }
    
    internal func visitGetExpr(expr: GetExpr) {
        
    }
    
    internal func visitUnaryExpr(expr: UnaryExpr) {
        compile(expr.right)
        switch expr.opr.tokenType {
        case .NOT:
            writeInstructionToChunk(op: .OP_notBool, expr: expr)
        case .MINUS:
            if expr.type is QsInt {
                writeInstructionToChunk(op: .OP_negateInt, expr: expr)
            } else if expr.type is QsDouble {
                writeInstructionToChunk(op: .OP_negateDouble, expr: expr)
            } else {
                assertionFailure("Unexpected unary operand type \(printType(expr.type))")
            }
        default:
            assertionFailure("Unexpected unary operator \(expr.opr.tokenType)")
        }
    }
    
    internal func visitCastExpr(expr: CastExpr) {
        
    }
    
    internal func visitArrayAllocationExpr(expr: ArrayAllocationExpr) {
        
    }
    
    internal func visitClassAllocationExpr(expr: ClassAllocationExpr) {
        
    }
    
    internal func visitBinaryExpr(expr: BinaryExpr) {
        compile(expr.left)
        compile(expr.right)
        let leftType = expr.left.type!
        
        // convenience function
        func writeInstruction(_ intInstruction: OpCode, _ doubleInstruction: OpCode, stringInstruction: OpCode? = nil, boolInstruction: OpCode? = nil) {
            // TODO: Strings
            if leftType is QsInt {
                writeInstructionToChunk(op: intInstruction, expr: expr)
            } else if leftType is QsDouble {
                writeInstructionToChunk(op: doubleInstruction, expr: expr)
            } else if leftType is QsBoolean && boolInstruction != nil {
                writeInstructionToChunk(op: boolInstruction!, expr: expr)
            } else if typesIsEqual(leftType, stringClass) {
                writeInstructionToChunk(op: stringInstruction!, expr: expr)
            } else {
                assertionFailure("Unexpected binary operand type \(printType(leftType))")
            }
        }
        switch expr.opr.tokenType {
        case .GREATER:
            writeInstruction(.OP_greaterInt, .OP_greaterDouble, stringInstruction: .OP_greaterString)
        case .GREATER_EQUAL:
            writeInstruction(.OP_greaterOrEqualInt, .OP_greaterOrEqualDouble, stringInstruction: .OP_greaterOrEqualString)
        case .LESS:
            writeInstruction(.OP_lessInt, .OP_lessDouble, stringInstruction: .OP_lessString)
        case .LESS_EQUAL:
            writeInstruction(.OP_lessOrEqualInt, .OP_lessOrEqualDouble, stringInstruction: .OP_lessOrEqualString)
        case .EQUAL_EQUAL:
            writeInstruction(.OP_equalEqualInt, .OP_equalEqualDouble, stringInstruction: .OP_equalEqualString, boolInstruction: .OP_equalEqualBool)
        case .BANG_EQUAL:
            writeInstruction(.OP_notEqualInt, .OP_notEqualDouble, stringInstruction: .OP_notEqualString, boolInstruction: .OP_notEqualBool)
        case .MINUS:
            writeInstruction(.OP_minusInt, .OP_minusDouble)
        case .SLASH:
            writeInstruction(.OP_divideInt, .OP_divideDouble)
        case .STAR:
            writeInstruction(.OP_multiplyInt, .OP_multiplyDouble)
        case .DIV:
            writeInstruction(.OP_intDivideInt, .OP_intDivideDouble)
        case .MOD:
            writeInstructionToChunk(op: .OP_modInt, expr: expr)
        case .PLUS:
            writeInstruction(.OP_addInt, .OP_addDouble, stringInstruction: .OP_addString)
        default:
            assertionFailure("Unexpected binary operator \(expr.opr.tokenType)")
        }
    }
    
    internal func visitLogicalExpr(expr: LogicalExpr) {
        compile(expr.left)
        compile(expr.right)
        switch expr.opr.tokenType {
        case .OR:
            writeInstructionToChunk(op: .OP_orBool, expr: expr)
        case .AND:
            writeInstructionToChunk(op: .OP_andBool, expr: expr)
        default:
            assertionFailure("Unexpected logical operator \(expr.opr.tokenType)")
        }
    }
    
    internal func visitSetExpr(expr: SetExpr) {
        
    }
    
    internal func visitAssignExpr(expr: AssignExpr) {
        
    }
    
    internal func visitIsTypeExpr(expr: IsTypeExpr) {
        
    }
    
    internal func visitImplicitCastExpr(expr: ImplicitCastExpr) {
        
    }
    
    internal func visitClassStmt(stmt: ClassStmt) {
        
    }
    
    internal func visitMethodStmt(stmt: MethodStmt) {
        
    }
    
    internal func visitFunctionStmt(stmt: FunctionStmt) {
        
    }
    
    internal func visitExpressionStmt(stmt: ExpressionStmt) {
        compile(stmt.expression)
        writeInstructionToChunk(op: .OP_pop, expr: stmt.expression)
    }
    
    internal func visitIfStmt(stmt: IfStmt) {
        
    }
    
    internal func visitOutputStmt(stmt: OutputStmt) {
        for expr in stmt.expressions {
            compile(expr)
            let type = expr.type!
            switch type {
            case is QsInt:
                writeInstructionToChunk(op: .OP_outputInt, expr: expr)
            case is QsDouble:
                writeInstructionToChunk(op: .OP_outputDouble, expr: expr)
            case is QsBoolean:
                writeInstructionToChunk(op: .OP_outputBoolean, expr: expr)
            case is QsClass:
                // TODO: String
                writeInstructionToChunk(op: .OP_outputClass, expr: expr)
            case is QsArray:
                writeInstructionToChunk(op: .OP_outputArray, expr: expr)
            case is QsAnyType:
                writeInstructionToChunk(op: .OP_outputAny, expr: expr)
            case is QsVoidType:
                writeInstructionToChunk(op: .OP_outputVoid, expr: expr)
            default:
                assertionFailure("Unexpected output type \(printType(type))")
            }
        }
    }
    
    internal func visitInputStmt(stmt: InputStmt) {
        
    }
    
    internal func visitReturnStmt(stmt: ReturnStmt) {
        
    }
    
    internal func visitLoopFromStmt(stmt: LoopFromStmt) {
        
    }
    
    internal func visitWhileStmt(stmt: WhileStmt) {
        
    }
    
    internal func visitBreakStmt(stmt: BreakStmt) {
        
    }
    
    internal func visitContinueStmt(stmt: ContinueStmt) {
        
    }
    
    internal func visitBlockStmt(stmt: BlockStmt) {
        
    }
    
    internal func visitExitStmt(stmt: ExitStmt) {
        
    }
    
    
    private func endCompiler() {
        Interpreter.writeInstructionToChunk(chunk: currentChunk(), op: .OP_return, line: 0)
    }
    
    private func compile(_ stmt: Stmt) {
        stmt.accept(visitor: self)
    }
    
    private func compile(_ expr: Expr) {
        expr.accept(visitor: self)
    }
    
    public func compileAst(stmts: [Stmt], symbolTable: SymbolTables) -> UnsafeMutablePointer<Chunk>! {
        compilingChunk = initChunk()
        if let stringSymbol = symbolTable.queryAtGlobalOnly("String<>") {
            stringClass = QsClass(name: "String", id: (stringSymbol as! ClassSymbol).id)
        }
        self.symbolTable = symbolTable
        
        for stmt in stmts {
            compile(stmt)
        }
        
        // end it off
        endCompiler()
        
        return compilingChunk
    }
}
