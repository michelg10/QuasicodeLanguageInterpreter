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
    
    enum ComparisonResult {
        case less
        case equal
        case greater
    }
    
    private func compareNumbers(_ lhs: Any?, _ rhs: Any?) -> ComparisonResult {
        if lhs is Int && rhs is Int {
            let lhs = lhs as! Int
            let rhs = rhs as! Int
            if lhs == rhs {
                return .equal
            } else if lhs > rhs {
                return .greater
            } else {
                return .less
            }
        }
        var comparisonLeft: Double
        var comparisonRight: Double
        if lhs is Int && rhs is Double {
            comparisonLeft = Double(lhs as! Int)
            comparisonRight = rhs as! Double
        } else if lhs is Double && rhs is Int {
            comparisonLeft = lhs as! Double
            comparisonRight = Double(rhs as! Int)
        } else {
            comparisonLeft = lhs as! Double
            comparisonRight = rhs as! Double
        }
        
        if comparisonLeft == comparisonRight {
            return .equal
        } else if comparisonLeft > comparisonRight {
            return .greater
        } else {
            return .less
        }
    }
    
    private func areEqual(_ lhs: Any?, _ rhs: Any?) -> Bool {
        // this assumes that the type checker has done its job
        
        // strings
        if let lhs = lhs as? String {
            let rhs = rhs as! String
            return lhs == rhs
        }
        
        // ints and doubles
        if lhs is Int || lhs is Double {
            return compareNumbers(lhs, rhs) == .equal
        }
        
        // arrays
        if lhs is [Any?] {
            let lhs = lhs as! [Any?]
            let rhs = rhs as! [Any?]
            if lhs.count != rhs.count {
                return false
            }
            for i in 0..<lhs.count {
                if !areEqual(lhs[i], rhs[i]) {
                    return false
                }
            }
            return true
        }
        
        // booleans
        if let lhs = lhs as? Bool {
            let rhs = rhs as! Bool
            return lhs == rhs
        }
        
        // TODO: objects
        
        preconditionFailure("Unrecognized type for equality comparison \(type(of: lhs)) and \(type(of: rhs))")
    }
    
    internal func visitBinaryExprOptionalAny(expr: BinaryExpr) throws -> Any? {
        let left = try interpret(expr.left)
        let right = try interpret(expr.right)
        switch expr.opr.tokenType {
        case .EQUAL_EQUAL:
            return areEqual(left, right)
        case .BANG_EQUAL:
            return !areEqual(left, right)
        case .GREATER, .GREATER_EQUAL, .LESS, .LESS_EQUAL:
            if left is Int || left is Double {
                let comparisonResult = compareNumbers(left, right)
                switch expr.opr.tokenType {
                case .GREATER:
                    return comparisonResult == .greater
                case .GREATER_EQUAL:
                    return comparisonResult == .greater || comparisonResult == .equal
                case .LESS:
                    return comparisonResult == .less
                case .LESS_EQUAL:
                    return comparisonResult == .less || comparisonResult == .equal
                default:
                    preconditionFailure("Switch should be exhaustive")
                }
            }
            if left is String {
                let left = left as! String
                let right = right as! String
                switch expr.opr.tokenType {
                case .GREATER:
                    return left > right
                case .GREATER_EQUAL:
                    return left >= right
                case .LESS:
                    return left < right
                case .LESS_EQUAL:
                    return left <= right
                default:
                    preconditionFailure("Switch should be exhaustive")
                }
            }
            preconditionFailure("Unrecognized type for comparison")
        case .MINUS, .SLASH, .STAR, .DIV, .MOD, .PLUS:
            // IMPORTANT: Integer division by zero
            if left is Int && right is Int {
                let left = left as! Int
                let right = right as! Int
                switch expr.opr.tokenType {
                case .MINUS:
                    return left - right
                case .SLASH, .DIV, .MOD:
                    if right == 0 {
                        throw InterpreterRuntimeError.error("Division by zero", expr.startLocation, expr.endLocation)
                    }
                    switch expr.opr.tokenType {
                    case .SLASH, .DIV:
                        return left / right
                    case .MOD:
                        return left % right
                    default:
                        preconditionFailure("Switch should be exhaustive")
                    }
                case .STAR:
                    return left * right
                case .PLUS:
                    return left + right
                default:
                    preconditionFailure("Switch should be exhaustive")
                }
            }
            if left is Double || right is Double {
                // promote both operands to double
                var lhs: Double
                var rhs: Double
                if left is Int {
                    lhs = Double(left as! Int)
                } else {
                    lhs = left as! Double
                }
                if right is Int {
                    rhs = Double(right as! Int)
                } else {
                    rhs = right as! Double
                }
                
                // perform the operation
                switch expr.opr.tokenType {
                case .MINUS:
                    return lhs - rhs
                case .SLASH:
                    return lhs / rhs
                case .STAR:
                    return lhs * rhs
                case .DIV:
                    return Int(lhs / rhs)
                case .PLUS:
                    return lhs + rhs
                default:
                    preconditionFailure("Switch should be exhaustive")
                }
            }
            if left is String && expr.opr.tokenType == .PLUS {
                let left = left as! String
                let right = right as! String
                return left + right
            }
        default:
            preconditionFailure("Unrecognized binary operator \(expr.opr.tokenType)")
        }
        
        preconditionFailure("This line should not be executed")
    }
    
    internal func visitLogicalExprOptionalAny(expr: LogicalExpr) throws -> Any? {
        let left = try interpret(expr.left) as! Bool
        
        // short-circuiting operators
        if expr.opr.tokenType == .OR && left == true {
            return true
        }
        if expr.opr.tokenType == .AND && left == false {
            return false
        }
        
        let right = try interpret(expr.right) as! Bool
        
        if expr.opr.tokenType == .OR {
            return left || right
        } else if expr.opr.tokenType == .AND {
            return left && right
        }
        
        preconditionFailure()
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
