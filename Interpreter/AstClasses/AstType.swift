protocol AstType {
    func accept(visitor: AstTypeVisitor)
    func accept(visitor: AstTypeStringVisitor) -> String
    func accept(visitor: AstTypeAstTypeThrowVisitor) throws -> AstType
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

class AstArrayType: AstType {
    var contains: AstType
    
    init(contains: AstType) {
        self.contains = contains
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
}

class AstClassType: AstType {
    var name: Token
    var templateArguments: [AstType]?
    
    init(name: Token, templateArguments: [AstType]?) {
        self.name = name
        self.templateArguments = templateArguments
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
}

class AstTemplateTypeName: AstType {
    var belongingClass: String
    var name: Token
    
    init(belongingClass: String, name: Token) {
        self.belongingClass = belongingClass
        self.name = name
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
}

class AstIntType: AstType {
    
    init() {
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
}

class AstDoubleType: AstType {
    
    init() {
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
}

class AstBooleanType: AstType {
    
    init() {
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
}

class AstAnyType: AstType {
    
    init() {
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
}

