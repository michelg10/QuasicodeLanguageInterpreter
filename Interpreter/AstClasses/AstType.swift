// swiftlint:disable all
protocol AstType {
    func accept(visitor: AstTypeVisitor)
    func accept(visitor: AstTypeStringVisitor) -> String
    func accept(visitor: AstTypeAstTypeThrowVisitor) throws -> AstType
    func accept(visitor: AstTypeQsTypeVisitor) -> QsType
    var startLocation: InterpreterLocation { get set }
    var endLocation: InterpreterLocation { get set }
}

protocol AstTypeVisitor {
    func visitAstArrayType(asttype: AstArrayType) 
    func visitAstClassType(asttype: AstClassType) 
    func visitAstTemplateTypeName(asttype: AstTemplateTypeName) 
    func visitAstIntType(asttype: AstIntType) 
    func visitAstDoubleType(asttype: AstDoubleType) 
    func visitAstBooleanType(asttype: AstBooleanType) 
    func visitAstAnyType(asttype: AstAnyType) 
}

protocol AstTypeStringVisitor {
    func visitAstArrayTypeString(asttype: AstArrayType) -> String
    func visitAstClassTypeString(asttype: AstClassType) -> String
    func visitAstTemplateTypeNameString(asttype: AstTemplateTypeName) -> String
    func visitAstIntTypeString(asttype: AstIntType) -> String
    func visitAstDoubleTypeString(asttype: AstDoubleType) -> String
    func visitAstBooleanTypeString(asttype: AstBooleanType) -> String
    func visitAstAnyTypeString(asttype: AstAnyType) -> String
}

protocol AstTypeAstTypeThrowVisitor {
    func visitAstArrayTypeAstType(asttype: AstArrayType) throws -> AstType
    func visitAstClassTypeAstType(asttype: AstClassType) throws -> AstType
    func visitAstTemplateTypeNameAstType(asttype: AstTemplateTypeName) throws -> AstType
    func visitAstIntTypeAstType(asttype: AstIntType) throws -> AstType
    func visitAstDoubleTypeAstType(asttype: AstDoubleType) throws -> AstType
    func visitAstBooleanTypeAstType(asttype: AstBooleanType) throws -> AstType
    func visitAstAnyTypeAstType(asttype: AstAnyType) throws -> AstType
}

protocol AstTypeQsTypeVisitor {
    func visitAstArrayTypeQsType(asttype: AstArrayType) -> QsType
    func visitAstClassTypeQsType(asttype: AstClassType) -> QsType
    func visitAstTemplateTypeNameQsType(asttype: AstTemplateTypeName) -> QsType
    func visitAstIntTypeQsType(asttype: AstIntType) -> QsType
    func visitAstDoubleTypeQsType(asttype: AstDoubleType) -> QsType
    func visitAstBooleanTypeQsType(asttype: AstBooleanType) -> QsType
    func visitAstAnyTypeQsType(asttype: AstAnyType) -> QsType
}

class AstArrayType: AstType {
    var contains: AstType
    var startLocation: InterpreterLocation
    var endLocation: InterpreterLocation
    
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

    func accept(visitor: AstTypeVisitor) {
        visitor.visitAstArrayType(asttype: self)
    }
    func accept(visitor: AstTypeStringVisitor) -> String {
        visitor.visitAstArrayTypeString(asttype: self)
    }
    func accept(visitor: AstTypeAstTypeThrowVisitor) throws -> AstType {
        try visitor.visitAstArrayTypeAstType(asttype: self)
    }
    func accept(visitor: AstTypeQsTypeVisitor) -> QsType {
        visitor.visitAstArrayTypeQsType(asttype: self)
    }
}

class AstClassType: AstType {
    var name: Token
    var templateArguments: [AstType]?
    var startLocation: InterpreterLocation
    var endLocation: InterpreterLocation
    
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

    func accept(visitor: AstTypeVisitor) {
        visitor.visitAstClassType(asttype: self)
    }
    func accept(visitor: AstTypeStringVisitor) -> String {
        visitor.visitAstClassTypeString(asttype: self)
    }
    func accept(visitor: AstTypeAstTypeThrowVisitor) throws -> AstType {
        try visitor.visitAstClassTypeAstType(asttype: self)
    }
    func accept(visitor: AstTypeQsTypeVisitor) -> QsType {
        visitor.visitAstClassTypeQsType(asttype: self)
    }
}

class AstTemplateTypeName: AstType {
    var belongingClass: String
    var name: Token
    var startLocation: InterpreterLocation
    var endLocation: InterpreterLocation
    
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

    func accept(visitor: AstTypeVisitor) {
        visitor.visitAstTemplateTypeName(asttype: self)
    }
    func accept(visitor: AstTypeStringVisitor) -> String {
        visitor.visitAstTemplateTypeNameString(asttype: self)
    }
    func accept(visitor: AstTypeAstTypeThrowVisitor) throws -> AstType {
        try visitor.visitAstTemplateTypeNameAstType(asttype: self)
    }
    func accept(visitor: AstTypeQsTypeVisitor) -> QsType {
        visitor.visitAstTemplateTypeNameQsType(asttype: self)
    }
}

class AstIntType: AstType {
    var startLocation: InterpreterLocation
    var endLocation: InterpreterLocation
    
    init(startLocation: InterpreterLocation, endLocation: InterpreterLocation) {
        self.startLocation = startLocation
        self.endLocation = endLocation
    }
    init(_ objectToCopy: AstIntType) {
        self.startLocation = objectToCopy.startLocation
        self.endLocation = objectToCopy.endLocation
    }

    func accept(visitor: AstTypeVisitor) {
        visitor.visitAstIntType(asttype: self)
    }
    func accept(visitor: AstTypeStringVisitor) -> String {
        visitor.visitAstIntTypeString(asttype: self)
    }
    func accept(visitor: AstTypeAstTypeThrowVisitor) throws -> AstType {
        try visitor.visitAstIntTypeAstType(asttype: self)
    }
    func accept(visitor: AstTypeQsTypeVisitor) -> QsType {
        visitor.visitAstIntTypeQsType(asttype: self)
    }
}

class AstDoubleType: AstType {
    var startLocation: InterpreterLocation
    var endLocation: InterpreterLocation
    
    init(startLocation: InterpreterLocation, endLocation: InterpreterLocation) {
        self.startLocation = startLocation
        self.endLocation = endLocation
    }
    init(_ objectToCopy: AstDoubleType) {
        self.startLocation = objectToCopy.startLocation
        self.endLocation = objectToCopy.endLocation
    }

    func accept(visitor: AstTypeVisitor) {
        visitor.visitAstDoubleType(asttype: self)
    }
    func accept(visitor: AstTypeStringVisitor) -> String {
        visitor.visitAstDoubleTypeString(asttype: self)
    }
    func accept(visitor: AstTypeAstTypeThrowVisitor) throws -> AstType {
        try visitor.visitAstDoubleTypeAstType(asttype: self)
    }
    func accept(visitor: AstTypeQsTypeVisitor) -> QsType {
        visitor.visitAstDoubleTypeQsType(asttype: self)
    }
}

class AstBooleanType: AstType {
    var startLocation: InterpreterLocation
    var endLocation: InterpreterLocation
    
    init(startLocation: InterpreterLocation, endLocation: InterpreterLocation) {
        self.startLocation = startLocation
        self.endLocation = endLocation
    }
    init(_ objectToCopy: AstBooleanType) {
        self.startLocation = objectToCopy.startLocation
        self.endLocation = objectToCopy.endLocation
    }

    func accept(visitor: AstTypeVisitor) {
        visitor.visitAstBooleanType(asttype: self)
    }
    func accept(visitor: AstTypeStringVisitor) -> String {
        visitor.visitAstBooleanTypeString(asttype: self)
    }
    func accept(visitor: AstTypeAstTypeThrowVisitor) throws -> AstType {
        try visitor.visitAstBooleanTypeAstType(asttype: self)
    }
    func accept(visitor: AstTypeQsTypeVisitor) -> QsType {
        visitor.visitAstBooleanTypeQsType(asttype: self)
    }
}

class AstAnyType: AstType {
    var startLocation: InterpreterLocation
    var endLocation: InterpreterLocation
    
    init(startLocation: InterpreterLocation, endLocation: InterpreterLocation) {
        self.startLocation = startLocation
        self.endLocation = endLocation
    }
    init(_ objectToCopy: AstAnyType) {
        self.startLocation = objectToCopy.startLocation
        self.endLocation = objectToCopy.endLocation
    }

    func accept(visitor: AstTypeVisitor) {
        visitor.visitAstAnyType(asttype: self)
    }
    func accept(visitor: AstTypeStringVisitor) -> String {
        visitor.visitAstAnyTypeString(asttype: self)
    }
    func accept(visitor: AstTypeAstTypeThrowVisitor) throws -> AstType {
        try visitor.visitAstAnyTypeAstType(asttype: self)
    }
    func accept(visitor: AstTypeQsTypeVisitor) -> QsType {
        visitor.visitAstAnyTypeQsType(asttype: self)
    }
}

