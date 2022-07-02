struct FunctionParam {
    var name: Token
    var astType: AstType?
    var initializer: Expr?
    var symbolTableIndex: Int?
    func getType(symbolTable: SymbolTables) -> QsType? {
        if symbolTableIndex == nil {
            return QsErrorType()
        }
        let symbol = symbolTable.getSymbol(id: symbolTableIndex!) as! VariableExpr
        return symbol.type
    }
}
