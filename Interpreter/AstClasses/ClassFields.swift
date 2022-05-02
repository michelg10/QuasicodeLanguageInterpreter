struct ClassFields {
    var visibilityModifier: VisibilityModifier
    var name: Token
    var astType: AstType?
    var initializer: Expr?
    var type: QsType?
}
