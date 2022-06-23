class ClassField {
    init(isStatic: Bool, visibilityModifier: VisibilityModifier, name: Token, astType: AstType? = nil, initializer: Expr? = nil, type: QsType? = nil, symbolTableIndex: Int? = nil) {
        self.isStatic = isStatic
        self.visibilityModifier = visibilityModifier
        self.name = name
        self.astType = astType
        self.initializer = initializer
        self.type = type
        self.symbolTableIndex = symbolTableIndex
    }
    
    var isStatic: Bool
    var visibilityModifier: VisibilityModifier
    var name: Token
    var astType: AstType?
    var initializer: Expr?
    var type: QsType?
    var symbolTableIndex: Int?
}
