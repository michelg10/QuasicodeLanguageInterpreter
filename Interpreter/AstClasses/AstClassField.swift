// swiftlint:disable all

class AstClassField {
    init(isStatic: Bool, visibilityModifier: VisibilityModifier, name: Token, astType: AstType, initializer: Expr? = nil, symbolTableIndex: Int? = nil) {
        self.isStatic = isStatic
        self.visibilityModifier = visibilityModifier
        self.name = name
        self.astType = astType
        self.initializer = initializer
        self.symbolTableIndex = symbolTableIndex
    }
    
    var isStatic: Bool
    var visibilityModifier: VisibilityModifier
    var name: Token
    var astType: AstType
    var initializer: Expr?
    var symbolTableIndex: Int?
}
