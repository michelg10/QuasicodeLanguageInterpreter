public struct AstFunctionParam {
    public var name: Token
    public var astType: AstType?
    public var initializer: Expr?
    public var symbolTableIndex: Int?
    func getType(symbolTable: SymbolTable) -> QsType? {
        if symbolTableIndex == nil {
            return QsErrorType()
        }
        let symbol = symbolTable.getSymbol(id: symbolTableIndex!) as! VariableExpr
        return symbol.type
    }
}
