struct FunctionParam {
    var name: Token
    var astType: AstType?
    var initializer: Expr?
    var type: QsType?
    var symbolTableIndex: Int?
}
