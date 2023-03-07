// swiftlint:disable all
public protocol AstType {
    func accept(visitor: AstTypeVisitor)
    func accept(visitor: AstTypeStringVisitor) -> String
    func accept(visitor: AstTypeAstTypeThrowVisitor) throws -> AstType
    func accept(visitor: AstTypeQsTypeVisitor) -> QsType
    var startLocation: InterpreterLocation { get set }
    var endLocation: InterpreterLocation { get set }
}

public protocol AstTypeVisitor {
    func visitAstArrayType(asttype: AstArrayType) 
    func visitAstClassType(asttype: AstClassType) 
    func visitAstTemplateTypeName(asttype: AstTemplateTypeName) 
    func visitAstIntType(asttype: AstIntType) 
    func visitAstDoubleType(asttype: AstDoubleType) 
    func visitAstBooleanType(asttype: AstBooleanType) 
    func visitAstAnyType(asttype: AstAnyType) 
}

public protocol AstTypeStringVisitor {
    func visitAstArrayTypeString(asttype: AstArrayType) -> String
    func visitAstClassTypeString(asttype: AstClassType) -> String
    func visitAstTemplateTypeNameString(asttype: AstTemplateTypeName) -> String
    func visitAstIntTypeString(asttype: AstIntType) -> String
    func visitAstDoubleTypeString(asttype: AstDoubleType) -> String
    func visitAstBooleanTypeString(asttype: AstBooleanType) -> String
    func visitAstAnyTypeString(asttype: AstAnyType) -> String
}

public protocol AstTypeAstTypeThrowVisitor {
    func visitAstArrayTypeAstType(asttype: AstArrayType) throws -> AstType
    func visitAstClassTypeAstType(asttype: AstClassType) throws -> AstType
    func visitAstTemplateTypeNameAstType(asttype: AstTemplateTypeName) throws -> AstType
    func visitAstIntTypeAstType(asttype: AstIntType) throws -> AstType
    func visitAstDoubleTypeAstType(asttype: AstDoubleType) throws -> AstType
    func visitAstBooleanTypeAstType(asttype: AstBooleanType) throws -> AstType
    func visitAstAnyTypeAstType(asttype: AstAnyType) throws -> AstType
}

public protocol AstTypeQsTypeVisitor {
    func visitAstArrayTypeQsType(asttype: AstArrayType) -> QsType
    func visitAstClassTypeQsType(asttype: AstClassType) -> QsType
    func visitAstTemplateTypeNameQsType(asttype: AstTemplateTypeName) -> QsType
    func visitAstIntTypeQsType(asttype: AstIntType) -> QsType
    func visitAstDoubleTypeQsType(asttype: AstDoubleType) -> QsType
    func visitAstBooleanTypeQsType(asttype: AstBooleanType) -> QsType
    func visitAstAnyTypeQsType(asttype: AstAnyType) -> QsType
}

public class AstArrayType: AstType {
    public var contains: AstType
    public var startLocation: InterpreterLocation
    public var endLocation: InterpreterLocation
    
    init(contains: AstType, startLocation: InterpreterLocation, endLocation: InterpreterLocation) {
        self.contains = contains
        self.startLocation = startLocation
        self.endLocation = endLocation
    }
    init(_ objectToCopy: AstArrayType) {
        self.contains = objectToCopy.contains
        self.startLocation = objectToCopy.startLocation
        self.endLocation = objectToCopy.endLocation
    }

    public func accept(visitor: AstTypeVisitor) {
        visitor.visitAstArrayType(asttype: self)
    }
    public func accept(visitor: AstTypeStringVisitor) -> String {
        visitor.visitAstArrayTypeString(asttype: self)
    }
    public func accept(visitor: AstTypeAstTypeThrowVisitor) throws -> AstType {
        try visitor.visitAstArrayTypeAstType(asttype: self)
    }
    public func accept(visitor: AstTypeQsTypeVisitor) -> QsType {
        visitor.visitAstArrayTypeQsType(asttype: self)
    }
}

public class AstClassType: AstType {
    public var name: Token
    public var templateArguments: [AstType]?
    public var startLocation: InterpreterLocation
    public var endLocation: InterpreterLocation
    
    init(name: Token, templateArguments: [AstType]?, startLocation: InterpreterLocation, endLocation: InterpreterLocation) {
        self.name = name
        self.templateArguments = templateArguments
        self.startLocation = startLocation
        self.endLocation = endLocation
    }
    init(_ objectToCopy: AstClassType) {
        self.name = objectToCopy.name
        self.templateArguments = objectToCopy.templateArguments
        self.startLocation = objectToCopy.startLocation
        self.endLocation = objectToCopy.endLocation
    }

    public func accept(visitor: AstTypeVisitor) {
        visitor.visitAstClassType(asttype: self)
    }
    public func accept(visitor: AstTypeStringVisitor) -> String {
        visitor.visitAstClassTypeString(asttype: self)
    }
    public func accept(visitor: AstTypeAstTypeThrowVisitor) throws -> AstType {
        try visitor.visitAstClassTypeAstType(asttype: self)
    }
    public func accept(visitor: AstTypeQsTypeVisitor) -> QsType {
        visitor.visitAstClassTypeQsType(asttype: self)
    }
}

public class AstTemplateTypeName: AstType {
    public var belongingClass: String
    public var name: Token
    public var startLocation: InterpreterLocation
    public var endLocation: InterpreterLocation
    
    init(belongingClass: String, name: Token, startLocation: InterpreterLocation, endLocation: InterpreterLocation) {
        self.belongingClass = belongingClass
        self.name = name
        self.startLocation = startLocation
        self.endLocation = endLocation
    }
    init(_ objectToCopy: AstTemplateTypeName) {
        self.belongingClass = objectToCopy.belongingClass
        self.name = objectToCopy.name
        self.startLocation = objectToCopy.startLocation
        self.endLocation = objectToCopy.endLocation
    }

    public func accept(visitor: AstTypeVisitor) {
        visitor.visitAstTemplateTypeName(asttype: self)
    }
    public func accept(visitor: AstTypeStringVisitor) -> String {
        visitor.visitAstTemplateTypeNameString(asttype: self)
    }
    public func accept(visitor: AstTypeAstTypeThrowVisitor) throws -> AstType {
        try visitor.visitAstTemplateTypeNameAstType(asttype: self)
    }
    public func accept(visitor: AstTypeQsTypeVisitor) -> QsType {
        visitor.visitAstTemplateTypeNameQsType(asttype: self)
    }
}

public class AstIntType: AstType {
    public var startLocation: InterpreterLocation
    public var endLocation: InterpreterLocation
    
    init(startLocation: InterpreterLocation, endLocation: InterpreterLocation) {
        self.startLocation = startLocation
        self.endLocation = endLocation
    }
    init(_ objectToCopy: AstIntType) {
        self.startLocation = objectToCopy.startLocation
        self.endLocation = objectToCopy.endLocation
    }

    public func accept(visitor: AstTypeVisitor) {
        visitor.visitAstIntType(asttype: self)
    }
    public func accept(visitor: AstTypeStringVisitor) -> String {
        visitor.visitAstIntTypeString(asttype: self)
    }
    public func accept(visitor: AstTypeAstTypeThrowVisitor) throws -> AstType {
        try visitor.visitAstIntTypeAstType(asttype: self)
    }
    public func accept(visitor: AstTypeQsTypeVisitor) -> QsType {
        visitor.visitAstIntTypeQsType(asttype: self)
    }
}

public class AstDoubleType: AstType {
    public var startLocation: InterpreterLocation
    public var endLocation: InterpreterLocation
    
    init(startLocation: InterpreterLocation, endLocation: InterpreterLocation) {
        self.startLocation = startLocation
        self.endLocation = endLocation
    }
    init(_ objectToCopy: AstDoubleType) {
        self.startLocation = objectToCopy.startLocation
        self.endLocation = objectToCopy.endLocation
    }

    public func accept(visitor: AstTypeVisitor) {
        visitor.visitAstDoubleType(asttype: self)
    }
    public func accept(visitor: AstTypeStringVisitor) -> String {
        visitor.visitAstDoubleTypeString(asttype: self)
    }
    public func accept(visitor: AstTypeAstTypeThrowVisitor) throws -> AstType {
        try visitor.visitAstDoubleTypeAstType(asttype: self)
    }
    public func accept(visitor: AstTypeQsTypeVisitor) -> QsType {
        visitor.visitAstDoubleTypeQsType(asttype: self)
    }
}

public class AstBooleanType: AstType {
    public var startLocation: InterpreterLocation
    public var endLocation: InterpreterLocation
    
    init(startLocation: InterpreterLocation, endLocation: InterpreterLocation) {
        self.startLocation = startLocation
        self.endLocation = endLocation
    }
    init(_ objectToCopy: AstBooleanType) {
        self.startLocation = objectToCopy.startLocation
        self.endLocation = objectToCopy.endLocation
    }

    public func accept(visitor: AstTypeVisitor) {
        visitor.visitAstBooleanType(asttype: self)
    }
    public func accept(visitor: AstTypeStringVisitor) -> String {
        visitor.visitAstBooleanTypeString(asttype: self)
    }
    public func accept(visitor: AstTypeAstTypeThrowVisitor) throws -> AstType {
        try visitor.visitAstBooleanTypeAstType(asttype: self)
    }
    public func accept(visitor: AstTypeQsTypeVisitor) -> QsType {
        visitor.visitAstBooleanTypeQsType(asttype: self)
    }
}

public class AstAnyType: AstType {
    public var startLocation: InterpreterLocation
    public var endLocation: InterpreterLocation
    
    init(startLocation: InterpreterLocation, endLocation: InterpreterLocation) {
        self.startLocation = startLocation
        self.endLocation = endLocation
    }
    init(_ objectToCopy: AstAnyType) {
        self.startLocation = objectToCopy.startLocation
        self.endLocation = objectToCopy.endLocation
    }

    public func accept(visitor: AstTypeVisitor) {
        visitor.visitAstAnyType(asttype: self)
    }
    public func accept(visitor: AstTypeStringVisitor) -> String {
        visitor.visitAstAnyTypeString(asttype: self)
    }
    public func accept(visitor: AstTypeAstTypeThrowVisitor) throws -> AstType {
        try visitor.visitAstAnyTypeAstType(asttype: self)
    }
    public func accept(visitor: AstTypeQsTypeVisitor) -> QsType {
        visitor.visitAstAnyTypeQsType(asttype: self)
    }
}

