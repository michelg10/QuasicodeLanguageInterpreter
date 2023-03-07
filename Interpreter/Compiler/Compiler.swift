public class Compiler: ExprVisitor, StmtVisitor {
    var compilingChunk: UnsafeMutablePointer<Chunk>!
    var symbolTable: SymbolTables = .init()
    var stringClass: QsType = QsVoidType()
    let useEmbeddedConstants = true // don't know why not, but just feels like that there's a reason that Java and Lox used a constants table.
    var classSymbolTableIndexToClassRuntimeIdMap: [Int : Int] = [:]
    
    func currentChunk() -> UnsafeMutablePointer<Chunk>! {
        return compilingChunk
    }
    
    public func visitGroupingExpr(expr: GroupingExpr) {
        compile(expr.expression)
    }
    
    private func writeInstructionToChunk(op: OpCode, expr: Expr) {
        ChunkInterface.writeInstructionToChunk(chunk: currentChunk(), op: op, index: expr.startLocation.index)
    }
    
    private func writeLongToChunk(data: UInt64, expr: Expr) {
        ChunkInterface.writeLongToChunk(chunk: currentChunk(), data: data, index: expr.startLocation.index)
    }
    
    private func writeByteToChunk(data: UInt8, expr: Expr) {
        ChunkInterface.writeByteToChunk(chunk: currentChunk(), data: data, index: expr.startLocation.index)
    }
    
    private func addConstantToChunk(data: UInt64) -> Int {
        return ChunkInterface.addConstantToChunk(chunk: currentChunk(), data: data)
    }
    
    private func writeLoadConstantFromTableInstruction(constantIndex: Int, expr: Expr) {
        let alwaysUseLongOperations = false // debug option
        if !alwaysUseLongOperations && constantIndex <= UInt8.max {
            ChunkInterface.writeInstructionToChunk(chunk: currentChunk(), op: .OP_loadConstantFromTable, index: expr.startLocation.index)
            ChunkInterface.writeByteToChunk(chunk: currentChunk(), data: UInt8(constantIndex), index: expr.startLocation.index)
        } else if constantIndex <= ((1 << 32) - 1) {
            ChunkInterface.writeInstructionToChunk(chunk: currentChunk(), op: .OP_LONG_loadConstantFromTable, index: expr.startLocation.index)
            ChunkInterface.writeUIntToChunk(chunk: currentChunk(), data: UInt32(constantIndex), index: expr.startLocation.index)
        } else {
            // TODO: Error handling
            assertionFailure("Compiler internal failure (too many constants)")
        }
    }
    
    private func writeExplicitlyTypedValueObjectToChunk(object: UnsafeMutableRawPointer, type: QsClass, expr: Expr) {
        ChunkInterface.writeExplicitlyTypedValueObjectToChunk(
            chunk: currentChunk(),
            object: object,
            classId: symbolTable.getClassRuntimeId(symbolTableIndex: type.id),
            index: expr.startLocation.index
        )
    }
    
    private func writeStringToChunk(_ string: String, expr: Expr) {
        let objString = string.utf8CString.withUnsafeBufferPointer { pointer in
            compilerCopyString(pointer.baseAddress!, pointer.count)
        }
        writeExplicitlyTypedValueObjectToChunk(object: objString!, type: stringClass as! QsClass, expr: expr)
    }
    
    public func visitLiteralExpr(expr: LiteralExpr) {
        // TODO: Strings
        switch expr.type! {
        case is QsInt:
            let value = expr.value as! Int
            if value >= Int8.min && value <= Int8.max {
                writeInstructionToChunk(op: .OP_loadEmbeddedByteConstant, expr: expr)
                writeByteToChunk(data: UInt8(bitPattern: Int8(value)), expr: expr)
            } else {
                if useEmbeddedConstants {
                    writeInstructionToChunk(op: .OP_loadEmbeddedLongConstant, expr: expr)
                    writeLongToChunk(data: UInt64(bitPattern: Int64(expr.value as! Int)), expr: expr)
                } else {
                    let constantIndex = addConstantToChunk(data: .init(bitPattern: Int64(value)))
                    writeLoadConstantFromTableInstruction(constantIndex: constantIndex, expr: expr)
                }
            }
        case is QsDouble:
            if useEmbeddedConstants {
                writeInstructionToChunk(op: .OP_loadEmbeddedLongConstant, expr: expr)
                writeLongToChunk(data: (expr.value as! Double).bitPattern, expr: expr)
            } else {
                let constantIndex = addConstantToChunk(data: (expr.value as! Double).bitPattern)
                writeLoadConstantFromTableInstruction(constantIndex: constantIndex, expr: expr)
            }
        case is QsBoolean:
            let value = expr.value as! Bool
            if value {
                writeInstructionToChunk(op: .OP_true, expr: expr)
            } else {
                writeInstructionToChunk(op: .OP_false, expr: expr)
            }
        case is QsClass:
            if typesEqual(expr.type!, stringClass, anyEqAny: true) {
                let value = expr.value as! String
                if useEmbeddedConstants {
                    writeInstructionToChunk(op: .OP_loadEmbeddedExplicitlyTypedConstant, expr: expr)
                    writeStringToChunk(value, expr: expr)
                } else {
                    // no implementation yet
                }
            } else {
                assertionFailure("Classes as literals should only be strings!")
            }
        default:
            assertionFailure("Unexpected literal type \(printType(expr.type))")
        }
    }
    
    public func visitArrayLiteralExpr(expr: ArrayLiteralExpr) {
        
    }
    
    public func visitStaticClassExpr(expr: StaticClassExpr) {
        
    }
    
    public func visitThisExpr(expr: ThisExpr) {
        
    }
    
    public func visitSuperExpr(expr: SuperExpr) {
        
    }
    
    public func visitVariableExpr(expr: VariableExpr) {
        
    }
    
    public func visitSubscriptExpr(expr: SubscriptExpr) {
        
    }
    
    public func visitCallExpr(expr: CallExpr) {
        
    }
    
    public func visitGetExpr(expr: GetExpr) {
        
    }
    
    public func visitUnaryExpr(expr: UnaryExpr) {
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
    
    public func visitCastExpr(expr: CastExpr) {
        
    }
    
    public func visitArrayAllocationExpr(expr: ArrayAllocationExpr) {
        
    }
    
    public func visitClassAllocationExpr(expr: ClassAllocationExpr) {
        
    }
    
    public func visitBinaryExpr(expr: BinaryExpr) {
        compile(expr.left)
        compile(expr.right)
        let leftType = expr.left.type!
        
        // convenience function
        func writeInstruction(
            _ intInstruction: OpCode,
            _ doubleInstruction: OpCode,
            stringInstruction: OpCode? = nil,
            boolInstruction: OpCode? = nil
        ) {
            if leftType is QsInt {
                writeInstructionToChunk(op: intInstruction, expr: expr)
            } else if leftType is QsDouble {
                writeInstructionToChunk(op: doubleInstruction, expr: expr)
            } else if leftType is QsBoolean && boolInstruction != nil {
                writeInstructionToChunk(op: boolInstruction!, expr: expr)
            } else if typesEqual(leftType, stringClass, anyEqAny: true) {
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
    
    public func visitLogicalExpr(expr: LogicalExpr) {
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
    
    public func visitVariableToSetExpr(expr: VariableToSetExpr) {
        
    }
    
    public func visitIsTypeExpr(expr: IsTypeExpr) {
        
    }
    
    public func visitImplicitCastExpr(expr: ImplicitCastExpr) {
        
    }
    
    public func visitClassStmt(stmt: ClassStmt) {
        
    }
    
    public func visitMethodStmt(stmt: MethodStmt) {
        
    }
    
    public func visitFunctionStmt(stmt: FunctionStmt) {
        
    }
    
    public func visitExpressionStmt(stmt: ExpressionStmt) {
        compile(stmt.expression)
        writeInstructionToChunk(op: .OP_pop, expr: stmt.expression)
    }
    
    public func visitMultiSetStmt(stmt: MultiSetStmt) {
        
    }
    
    public func visitSetStmt(stmt: SetStmt) {
        
    }
    
    public func visitIfStmt(stmt: IfStmt) {
        
    }
    
    public func visitOutputStmt(stmt: OutputStmt) {
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
                if typesEqual(type, stringClass, anyEqAny: true) {
                    writeInstructionToChunk(op: .OP_outputString, expr: expr)
                } else {
                    writeInstructionToChunk(op: .OP_outputClass, expr: expr)
                }
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
    
    public func visitInputStmt(stmt: InputStmt) {
        
    }
    
    public func visitReturnStmt(stmt: ReturnStmt) {
        
    }
    
    public func visitLoopFromStmt(stmt: LoopFromStmt) {
        
    }
    
    public func visitWhileStmt(stmt: WhileStmt) {
        
    }
    
    public func visitBreakStmt(stmt: BreakStmt) {
        
    }
    
    public func visitContinueStmt(stmt: ContinueStmt) {
        
    }
    
    public func visitBlockStmt(stmt: BlockStmt) {
        
    }
    
    public func visitExitStmt(stmt: ExitStmt) {
        
    }
    
    private func endCompiler() {
        ChunkInterface.writeInstructionToChunk(chunk: currentChunk(), op: .OP_return, index: 0)
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
