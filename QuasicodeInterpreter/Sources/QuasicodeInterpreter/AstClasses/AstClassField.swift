// swiftlint:disable all

public class AstClassField {
    init(isStatic: Bool, visibilityModifier: VisibilityModifier, name: Token, astType: AstType, initializer: Expr? = nil, symbolTableIndex: Int? = nil, startLocation: InterpreterLocation, endLocation: InterpreterLocation) {
        self.isStatic = isStatic
        self.visibilityModifier = visibilityModifier
        self.name = name
        self.astType = astType
        self.initializer = initializer
        self.symbolTableIndex = symbolTableIndex
        self.startLocation = startLocation
        self.endLocation = endLocation
    }
    
    public var isStatic: Bool
    public var visibilityModifier: VisibilityModifier
    public var name: Token
    public var astType: AstType
    public var initializer: Expr?
    public var symbolTableIndex: Int?
    public var startLocation: InterpreterLocation
    public var endLocation: InterpreterLocation
}
