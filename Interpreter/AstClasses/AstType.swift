protocol AstType {
    func accept(visitor: AstTypeVisitor)
    func accept(visitor: AstTypeStringVisitor) -> String
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
}

class AstClassType: AstType {
    var name: Token
    var templateTypes: [AstType]?
    
    init(name: Token, templateTypes: [AstType]?) {
        self.name = name
        self.templateTypes = templateTypes
    }

    func accept(visitor: AstTypeVisitor) {
        visitor.visitAstClassType(asttype: self)
    }
    func accept(visitor: AstTypeStringVisitor) -> String {
        visitor.visitAstClassTypeString(asttype: self)
    }
}

class AstTemplateTypeName: AstType {
    var name: Token
    
    init(name: Token) {
        self.name = name
    }

    func accept(visitor: AstTypeVisitor) {
        visitor.visitAstTemplateTypeName(asttype: self)
    }
    func accept(visitor: AstTypeStringVisitor) -> String {
        visitor.visitAstTemplateTypeNameString(asttype: self)
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
}

