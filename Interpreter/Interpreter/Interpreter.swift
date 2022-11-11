// a very slow, but (hopefully) guaranteed correct tree-walk interpreter for debugging purposes
class Interpreter: ExprOptionalAnyThrowVisitor {
    let verifyTypeCheck = true // this switch configures whether or not the interpreter will verify the type checker
    
    private enum InterpreterRuntimeError: Error {
        case error(String, InterpreterLocation, InterpreterLocation)
    }
    
    enum TypeVerificationResult {
        case verificationWithQsErrorType
        case pass
        case fail
    }
    
    private func verifyIsType(_ value: Any?, type: QsType) -> TypeVerificationResult {
        return .pass
    }
    
    internal func visitGroupingExprOptionalAny(expr: GroupingExpr) throws -> Any? {
        return try interpret(expr.expression)
    }
    
    internal func visitLiteralExprOptionalAny(expr: LiteralExpr) -> Any? {
        return expr.value
    }
    
    internal func visitArrayLiteralExprOptionalAny(expr: ArrayLiteralExpr) throws -> Any? {
        var result: [Any?] = [];
        for value in expr.values {
            result.append(try interpret(value))
        }
        
        return result
    }
    
    internal func visitStaticClassExprOptionalAny(expr: StaticClassExpr) -> Any? {
        // TODO
        return nil
    }
    
    internal func visitThisExprOptionalAny(expr: ThisExpr) -> Any? {
        // TODO
        return nil
    }
    
    internal func visitSuperExprOptionalAny(expr: SuperExpr) -> Any? {
        // TODO
        return nil
    }
    
    internal func visitVariableExprOptionalAny(expr: VariableExpr) -> Any? {
        // TODO
        return nil
    }
    
    internal func visitSubscriptExprOptionalAny(expr: SubscriptExpr) throws -> Any? {
        let indexedArray = try interpret(expr.expression) as! [Any?]
        let index = try interpret(expr.index) as! Int;
        
        if index < 0 || index >= indexedArray.count {
            throw InterpreterRuntimeError.error("Array access index out of range", expr.index.startLocation, expr.index.endLocation)
        }
        
        return indexedArray[index]
    }
    
    internal func visitCallExprOptionalAny(expr: CallExpr) -> Any? {
        // TODO
        return nil
    }
    
    internal func visitGetExprOptionalAny(expr: GetExpr) -> Any? {
        // TODO
        return nil
    }
    
    internal func visitUnaryExprOptionalAny(expr: UnaryExpr) throws -> Any? {
        let right = try interpret(expr.right)
        switch expr.opr.tokenType {
        case .MINUS:
            if right is Double {
                return -(right as! Double)
            } else if right is Int {
                return -(right as! Int)
            } else {
                preconditionFailure("Expected operand of type 'Double' or 'Int' with '-' unary operator")
            }
        case .NOT:
            if right is Bool {
                return !(right as! Bool)
            } else {
                preconditionFailure("Expected operand of type 'Bool' with 'NOT' unary operator")
            }
            
        default:
            preconditionFailure("Unrecognized unary operator \(expr.opr.tokenType)")
        }
    }
    
    internal func visitCastExprOptionalAny(expr: CastExpr) -> Any? {
        // TODO
        return nil
    }
    
    internal func visitArrayAllocationExprOptionalAny(expr: ArrayAllocationExpr) -> Any? {
        // TODO
        return nil
    }
    
    internal func visitClassAllocationExprOptionalAny(expr: ClassAllocationExpr) -> Any? {
        // TODO
        return nil
    }
    
    internal func visitBinaryExprOptionalAny(expr: BinaryExpr) -> Any? {
        switch expr.opr.tokenType {
        case .EQUAL_EQUAL, .BANG_EQUAL:
            // string equality, array equality, object alias equality, numbers equality, boolean equality
            print()
        case .GREATER, .GREATER_EQUAL, .LESS, .LESS_EQUAL, .MINUS, .SLASH, .STAR, .DIV:
            print()
            // IMPORTANT: Integer division by zero
        case .MOD:
            print()
        case .PLUS:
            print()
        default:
            preconditionFailure("Unrecognized binary operator \(expr.opr.tokenType)")
        }
        
        return nil
    }
    
    internal func visitLogicalExprOptionalAny(expr: LogicalExpr) -> Any? {
        // TODO
        return nil
    }
    
    internal func visitSetExprOptionalAny(expr: SetExpr) -> Any? {
        // TODO
        return nil
    }
    
    internal func visitAssignExprOptionalAny(expr: AssignExpr) -> Any? {
        // TODO
        return nil
    }
    
    internal func visitIsTypeExprOptionalAny(expr: IsTypeExpr) -> Any? {
        // TODO
        return nil
    }
    
    internal func visitImplicitCastExprOptionalAny(expr: ImplicitCastExpr) -> Any? {
        // TODO
        return nil
    }
    
    func interpret(_ expr: Expr) throws -> Any? {
        let result = try expr.accept(visitor: self)
        if verifyTypeCheck {
            let verificationResult = verifyIsType(result, type: expr.type!)
            if verificationResult != .pass {
                print("Type verification failure!")
                preconditionFailure()
            }
        }
        return result
    }
}
