// swiftlint:disable type_body_length
/// A slow tree-walk interpreter for debugging purposes
public class Interpreter: ExprOptionalAnyThrowVisitor, StmtThrowVisitor {
// swiftlint:enable type_body_length
    public init() {}
    
    let verifyTypeCheck = true // this switch configures whether or not the interpreter will verify the type checker
    var doDebugPrint = false
    private var environment = Environment()
    
    private var stringClassId = -1
    
    private func getStringType() -> QsType {
        return QsClass(name: "String", id: stringClassId)
    }
    
    private func printToStdout(_ str: String) {
        print(str, terminator: "")
    }
    
    private func getStdin() -> String {
        print("Expect input: ", terminator: "")
        return readLine(strippingNewline: true) ?? ""
    }
    
    private enum InterpreterRuntimeError: Error {
        case error(String, InterpreterLocation, InterpreterLocation)
    }
    
    private enum InterpreterExitSignal: Error {
        case signal
    }
    
    private enum InterpreterInterruptSignal: Error {
        case breakLoop
        case continueLoop
    }
    
    enum TypeVerificationResult {
        case verificationWithQsErrorType
        case pass
        case fail
    }
    
    // Arrays are value types in Swift but are reference types in Quasicode, so they need to be boxed
    class QsArrayReference: Collection {
        init(data: [Any?]) {
            self.data = data
        }
        
        private var data: [Any?]
        
        var startIndex: Int = 0
        var endIndex: Int {
            data.count
        }
        func index(after i: Int) -> Int {
            i + 1
        }
        
        subscript(index: Int) -> Any? {
            get {
                // returns a data type or, in the case of a multi-dimensional array, another QsArrayReference
                return data[index]
            }
            set {
                data[index] = newValue
            }
        }
        
        var count: Int {
            data.count
        }
        
        var isEmpty: Bool {
            // swiftlint:disable:next empty_count
            count == 0
        }
    }
    
    private func verifyIsType(_ value: Any?, type: QsType) -> TypeVerificationResult {
        defer {
            debugPrint(purpose: "Type checker verification", "Verifying \(String(describing: value)) as \(printType(type))")
        }
        
        if type is QsErrorType {
            return .verificationWithQsErrorType
        }
        if type is QsAnyType {
            return .pass
        }
        if value is Double {
            return (type is QsDouble ? .pass : .fail)
        }
        if value is Int {
            return (type is QsInt ? .pass : .fail)
        }
        if value is Bool {
            return (type is QsBoolean ? .pass : .fail)
        }
        if value is String {
            guard let type = type as? QsClass else {
                return .fail
            }
            
            return (type.name == "String" ? .pass : .fail)
        }
        if let value = value as? QsArrayReference {
            guard let type = type as? QsArray else {
                return .fail
            }
            if value.isEmpty {
                return .pass
            }
            return verifyIsType(value[0], type: type.contains)
        }
        if value == nil {
            if type is QsVoidType {
                return .pass
            } else {
                return .fail
            }
        }
        // TODO: verify classes
        preconditionFailure("Unrecognized type \(Swift.type(of: value))")
    }
    
    public func visitGroupingExprOptionalAny(expr: GroupingExpr) throws -> Any? {
        return try interpret(expr.expression)
    }
    
    public func visitLiteralExprOptionalAny(expr: LiteralExpr) -> Any? {
        return expr.value
    }
    
    public func visitArrayLiteralExprOptionalAny(expr: ArrayLiteralExpr) throws -> Any? {
        var result: [Any?] = []
        for value in expr.values {
            result.append(try interpret(value))
        }
        
        return QsArrayReference(data: result)
    }
    
    public func visitStaticClassExprOptionalAny(expr: StaticClassExpr) -> Any? {
        // TODO
        return nil
    }
    
    public func visitThisExprOptionalAny(expr: ThisExpr) -> Any? {
        // TODO
        return nil
    }
    
    public func visitSuperExprOptionalAny(expr: SuperExpr) -> Any? {
        // TODO
        return nil
    }
    
    public func visitVariableExprOptionalAny(expr: VariableExpr) throws -> Any? {
        let fetch = environment.fetch(symbolTableId: expr.symbolTableIndex!)
        
        guard let fetch = fetch else {
            throw InterpreterRuntimeError.error("Use of variable '\(expr.name.lexeme)' before initialization", expr.startLocation, expr.endLocation)
        }
        
        return fetch.value
    }
    
    public func visitSubscriptExprOptionalAny(expr: SubscriptExpr) throws -> Any? {
        let indexedArray = try interpret(expr.expression) as! QsArrayReference
        let index = try interpret(expr.index) as! Int
        
        if index < 0 || index >= indexedArray.count {
            throw InterpreterRuntimeError.error("Array access index out of range", expr.index.startLocation, expr.index.endLocation)
        }
        
        return indexedArray[index]
    }
    
    public func visitCallExprOptionalAny(expr: CallExpr) -> Any? {
        // TODO
        return nil
    }
    
    public func visitGetExprOptionalAny(expr: GetExpr) throws -> Any? {
        // TODO: this, static class, or an object
        let value = try interpret(expr.object)
        if let value = value as? QsArrayReference {
            return value.count
        } else {
            preconditionFailure("Operation not implemented")
        }
    }
    
    public func visitUnaryExprOptionalAny(expr: UnaryExpr) throws -> Any? {
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
    
    public func visitCastExprOptionalAny(expr: CastExpr) -> Any? {
        // TODO
        return nil
    }
    
    /// Gets the default value of a requested type for array initialization.
    /// Halts execution with a preconditionFailure when the requested type is invalid.
    /// - Parameter type: The requested type. This function does not support array types.
    /// - Returns: The default value for the requested type
    private func getDefaultValue(ofType type: QsType) -> Any? {
        if let type = type as? QsArray {
            preconditionFailure("getDefaultValue called with QsArray type!")
        }
        if type is QsBoolean {
            return false
        }
        if type is QsInt {
            return 0
        }
        if type is QsDouble {
            return 0.0
        }
        if type is QsAnyType {
            return nil
        }
        // TODO: QsClassTypes
        preconditionFailure("Unrecognized type for default value fetching")
    }
    
    private func allocateArray(ofType type: QsType, ofLengths lengths: [Int], lengthsOffset: Int = 0) -> Any? {
        if let type = type as? QsArray {
            return QsArrayReference(
                data: .init(
                    repeating: allocateArray(ofType: type.contains, ofLengths: lengths, lengthsOffset: lengthsOffset + 1),
                    count: lengths[lengthsOffset]
                )
            )
        }
        return getDefaultValue(ofType: type)
    }
    
    public func visitArrayAllocationExprOptionalAny(expr: ArrayAllocationExpr) throws -> Any? {
        var lengths: [Int] = []
        for lengthExpr in expr.capacity {
            let length = try interpret(lengthExpr) as! Int
            lengths.append(length)
        }
        return allocateArray(ofType: expr.type!, ofLengths: lengths)
    }
    
    public func visitClassAllocationExprOptionalAny(expr: ClassAllocationExpr) -> Any? {
        // TODO
        return nil
    }
    
    enum ComparisonResult {
        case less
        case equal
        case greater
    }
    
    private func compareNumbers(_ lhs: Any?, _ rhs: Any?) -> ComparisonResult {
        if lhs is Int {
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
        
        // the type checker should use implicit cast expressions to promote the value to a double if necessary, so checking for combinations is unnecessary. it must be a double.
        let lhs = lhs as! Double
        let rhs = rhs as! Double
        
        if lhs == rhs {
            return .equal
        } else if lhs > rhs {
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
        if lhs is QsArrayReference {
            let lhs = lhs as! QsArrayReference
            let rhs = rhs as! QsArrayReference
            if lhs === rhs {
                // one small optimization: if they refer to the same object in memory (i.e. lhs and rhs are aliases of one another, then they must be equal)
                return true
            }
            if lhs.count != rhs.count {
                return false
            }
            
            if lhs.elementsEqual(rhs, by: { element1, element2 in
                areEqual(element1, element2)
            }) {
                return true
            } else {
                return false
            }
        }
        
        // booleans
        if let lhs = lhs as? Bool {
            let rhs = rhs as! Bool
            return lhs == rhs
        }
        
        // TODO: objects
        
        preconditionFailure("Unrecognized type for equality comparison \(type(of: lhs)) and \(type(of: rhs))")
    }
    
    public func visitBinaryExprOptionalAny(expr: BinaryExpr) throws -> Any? {
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
            if left is Int {
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
            if left is Double {
                // the type checker should've already promoted an operand to double if the other is double
                var lhs = left as! Double
                var rhs = right as! Double
                
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
    
    public func visitLogicalExprOptionalAny(expr: LogicalExpr) throws -> Any? {
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
    
    public func visitIsTypeExprOptionalAny(expr: IsTypeExpr) -> Any? {
        // TODO: since type information is erased in the compiler / VM, "is type" expressions need to be computed at compile-time for every type *except* for anys and potentially polymorphic classes
        return nil
    }
    
    public func visitImplicitCastExprOptionalAny(expr: ImplicitCastExpr) throws -> Any? {
        // Supported casts
        // int -> double
        // some type -> any
        // TODO: subclass -> superclass
        var value = try interpret(expr.expression)
        if typesEqual(expr.type!, QsDouble(), anyEqAny: true) {
            if value is Int {
                value = Double(value as! Int)
                return value
            }
        } else if typesEqual(expr.type!, QsAnyType(), anyEqAny: true) {
            // do nothing
            return value
        }
        preconditionFailure("Unsupported implicit type cast \(printType(expr.expression.type)) -> \(printType(expr.type))")
        return value
    }
    
    public func visitVariableToSetExprOptionalAny(expr: VariableToSetExpr) throws -> Any? {
        preconditionFailure("VariableToSetExpr should be interpreted in the SetExpr")
        return nil
    }
    
    public func visitClassStmt(stmt: ClassStmt) throws {
        // TODO
    }
    
    public func visitMethodStmt(stmt: MethodStmt) throws {
        // TODO
    }
    
    public func visitFunctionStmt(stmt: FunctionStmt) throws {
        // TODO
    }
    
    public func visitExpressionStmt(stmt: ExpressionStmt) throws {
        try interpret(stmt.expression)
    }
    
    public func visitIfStmt(stmt: IfStmt) throws {
        let condition = try interpret(stmt.condition) as! Bool
        if condition {
            try interpret(stmt.thenBranch)
        } else {
            for branch in stmt.elseIfBranches {
                let condition = try interpret(branch.condition) as! Bool
                if condition {
                    try interpret(branch.thenBranch)
                    return
                }
            }
            if stmt.elseBranch != nil {
                try interpret(stmt.elseBranch!)
            }
        }
    }
    
    private func stringify(_ val: Any?) -> String {
        if val == nil {
            return "nil"
        }
        
        if let val = val as? Int {
            return val.description
        }
        
        if let val = val as? Double {
            return val.description
        }
        
        if let val = val as? Bool {
            if val {
                return "true"
            } else {
                return "false"
            }
        }
        
        if let val = val as? QsArrayReference {
            var res = "{"
            for i in 0..<val.count {
                res += stringify(val[i])
                if i != val.count - 1 {
                    res += ", "
                }
            }
            res += "}"
            return res
        }
        
        if let val = val as? String {
            return val
        }
        
        preconditionFailure("Unrecognized type for stringify \(type(of: val))")
    }
    
    public func visitOutputStmt(stmt: OutputStmt) throws {
        for i in 0..<stmt.expressions.count {
            let result = try interpret(stmt.expressions[i])
            printToStdout(stringify(result))
            
            if i != stmt.expressions.count - 1 {
                printToStdout(" ")
            }
        }
        printToStdout("\n")
    }
    
    public func visitInputStmt(stmt: InputStmt) throws {
        for expression in stmt.expressions {
            let input = getStdin()
            if typesEqual(expression.type!, QsInt(), anyEqAny: true) {
                var value: Int
                if let input = Int(input) {
                    value = input
                } else if let input = Double(input) {
                    value = Int(input)
                } else {
                    throw InterpreterRuntimeError.error("Cannot cast input to type \(printType(expression.type!))", expression.startLocation, expression.endLocation)
                }
                try assignTo(lhs: expression, rhs: value)
            } else if typesEqual(expression.type!, QsDouble(), anyEqAny: true) {
                if let input = Double(input) {
                    try assignTo(lhs: expression, rhs: input)
                } else {
                    throw InterpreterRuntimeError.error("Cannot cast input to type \(printType(expression.type!))", expression.startLocation, expression.endLocation)
                }
            } else if typesEqual(expression.type!, getStringType(), anyEqAny: true) {
                try assignTo(lhs: expression, rhs: input)
            } else if typesEqual(expression.type!, QsAnyType(), anyEqAny: true) {
                if let input = Int(input) {
                    try assignTo(lhs: expression, rhs: input)
                } else if let input = Double(input) {
                    try assignTo(lhs: expression, rhs: input)
                } else {
                    try assignTo(lhs: expression, rhs: input)
                }
            } else {
                preconditionFailure("Expected input expression to be of type Int, Double, or String")
            }
        }
    }
    
    public func visitReturnStmt(stmt: ReturnStmt) throws {
        // TODO
    }
    
    public func visitLoopFromStmt(stmt: LoopFromStmt) throws {
        let lrange = try interpret(stmt.lRange) as! Int
        let rrange = try interpret(stmt.rRange) as! Int
        
        for i in lrange...rrange {
            environment.add(symbolTableId: stmt.variable.symbolTableIndex!, name: stmt.variable.name.lexeme, value: i)
            
            do {
                try interpret(stmt.body)
            } catch InterpreterInterruptSignal.continueLoop {
                continue
            } catch InterpreterInterruptSignal.breakLoop {
                break
            }
        }
    }
    
    public func visitWhileStmt(stmt: WhileStmt) throws {
        while true {
            let condition = try interpret(stmt.expression)
            if (condition as! Bool) == false {
                break
            }
            do {
                try interpret(stmt.body)
            } catch InterpreterInterruptSignal.continueLoop {
                continue
            } catch InterpreterInterruptSignal.breakLoop {
                break
            } catch {
                throw error
            }
        }
    }
    
    public func visitBreakStmt(stmt: BreakStmt) throws {
        throw InterpreterInterruptSignal.breakLoop
    }
    
    public func visitContinueStmt(stmt: ContinueStmt) throws {
        throw InterpreterInterruptSignal.continueLoop
    }
    
    public func visitBlockStmt(stmt: BlockStmt) throws {
        try interpret(stmt.statements)
    }
    
    public func visitExitStmt(stmt: ExitStmt) throws {
        throw InterpreterExitSignal.signal
    }
    
    public func visitMultiSetStmt(stmt: MultiSetStmt) throws {
        for setStmt in stmt.setStmts {
            try interpret(setStmt)
        }
    }
    
    private func assignTo(lhs: Expr, rhs: Any?) throws {
        if lhs is GetExpr {
            // TODO
        } else if lhs is SubscriptExpr {
            let lhs = lhs as! SubscriptExpr
            let lhsObject = try interpret(lhs.expression) as! QsArrayReference
            let lhsIndex = try interpret(lhs.index) as! Int
            lhsObject[lhsIndex] = rhs
        } else if lhs is VariableToSetExpr {
            let lhs = lhs as! VariableToSetExpr
            environment.add(symbolTableId: lhs.to.symbolTableIndex!, name: lhs.to.name.lexeme, value: rhs)
        } else if lhs is VariableExpr {
            let lhs = lhs as! VariableExpr
            environment.add(symbolTableId: lhs.symbolTableIndex!, name: lhs.name.lexeme, value: rhs)
        } else {
            preconditionFailure("Unrecognized assignable expression \(type(of: lhs))")
        }
    }
    
    public func visitSetStmt(stmt: SetStmt) throws {
        let rhs = try interpret(stmt.value)
        for i in stmt.chained.indices.reversed() {
            try assignTo(lhs: stmt.chained[i], rhs: rhs)
        }
        try assignTo(lhs: stmt.left, rhs: rhs)
    }
    
    private func interpret(_ expr: Expr) throws -> Any? {
        let result = try expr.accept(visitor: self)
        if verifyTypeCheck {
            let verificationResult = verifyIsType(result, type: expr.type!)
            if verificationResult != .pass && doDebugPrint {
                debugPrint(purpose: "Type checker verification", "Type verification failure")
                preconditionFailure()
            }
        }
        return result
    }
    
    private func interpret(_ stmt: Stmt) throws {
        try stmt.accept(visitor: self)
    }
    
    private func interpret(_ stmts: [Stmt]) throws {
        for stmt in stmts {
            try interpret(stmt)
        }
    }
    
    public func execute(_ stmts: [Stmt], symbolTable: SymbolTables, debugPrint: Bool = false) {
        if debugPrint {
            print("----- Interpreter -----")
        }
        doDebugPrint = debugPrint
        
        stringClassId = symbolTable.queryAtGlobalOnly("String<>")?.id ?? -1
        self.environment = Environment()
        for stmt in stmts {
            do {
                try interpret(stmt)
            } catch let error {
                print(error)
            }
        }
    }
}