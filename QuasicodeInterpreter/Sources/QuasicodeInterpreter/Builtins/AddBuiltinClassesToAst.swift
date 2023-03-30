// swiftlint:disable function_body_length

// TODO: Probably put all of these into external files with Quasicode-native (or implement them in Swift) implementations

extension Builtins {
    public static func addBuiltinClassesToAst(_ ast: [Stmt]) -> [Stmt] {
        // swiftlint:enable function_body_length
        struct MethodDescription {
            struct FunctionParam {
                var name: String
                var type: AstType
            }
            var isStatic: Bool
            var visibilityModifier: VisibilityModifier
            var name: String
            var params: [FunctionParam]
            var annotation: AstType?
        }
        
        func createClass(name: String, templates: [String]?, methods: [MethodDescription]) -> ClassStmt {
            var methodStmts: [MethodStmt] = []
            for method in methods {
                var params: [AstFunctionParam] = []
                for param in method.params {
                    params.append(
                        .init(
                            name: .dummyToken(tokenType: .IDENTIFIER, lexeme: param.name),
                            astType: param.type,
                            initializer: nil,
                            symbolTableIndex: nil
                        )
                    )
                }
                
                let correspondingFunctionStmt: FunctionStmt = .init(
                    keyword: .dummyToken(tokenType: .IDENTIFIER, lexeme: "function"),
                    name: .dummyToken(tokenType: .IDENTIFIER, lexeme: method.name),
                    symbolTableIndex: nil,
                    nameSymbolTableIndex: nil,
                    scopeIndex: nil,
                    params: params,
                    annotation: method.annotation,
                    body: [],
                    endOfFunction: .dummyToken(tokenType: .FUNCTION, lexeme: "function"),
                    startLocation: .dub(),
                    endLocation: .dub()
                )
                
                methodStmts.append(
                    .init(
                        isStatic: method.isStatic,
                        staticKeyword: method.isStatic ? .dummyToken(tokenType: .STATIC, lexeme: "static") : nil,
                        visibilityModifier: method.visibilityModifier,
                        function: correspondingFunctionStmt,
                        startLocation: .dub(),
                        endLocation: .dub()
                    )
                )
            }
            
            return .init(
                keyword: .dummyToken(tokenType: .CLASS, lexeme: "class"),
                name: .dummyToken(tokenType: .IDENTIFIER, lexeme: name),
                builtin: true,
                symbolTableIndex: nil,
                instanceThisSymbolTableIndex: nil,
                staticThisSymbolTableIndex: nil,
                scopeIndex: nil,
                templateParameters: templates == nil ? nil : templates!.map({ str in
                    return Token.dummyToken(tokenType: .IDENTIFIER, lexeme: str)
                }),
                expandedTemplateParameters: nil,
                superclass: nil,
                methods: methodStmts,
                fields: [],
                startLocation: .dub(),
                endLocation: .dub()
            )
        }
        
        let collectionClassAstTemplateTypeT = AstTemplateTypeName(
            belongingClass: "Collection",
            name: .dummyToken(tokenType: .IDENTIFIER, lexeme: "T"),
            startLocation: .dub(),
            endLocation: .dub()
        )
        
        let collectionClass = createClass(
            name: "Collection",
            templates: ["T"],
            methods: [
                .init(
                    isStatic: false,
                    visibilityModifier: .PUBLIC,
                    name: "getNext",
                    params: [],
                    annotation: collectionClassAstTemplateTypeT
                ),
                .init(
                    isStatic: false,
                    visibilityModifier: .PUBLIC,
                    name: "resetNext",
                    params: [],
                    annotation: nil
                ),
                .init(
                    isStatic: false,
                    visibilityModifier: .PUBLIC,
                    name: "addItem",
                    params: [.init(name: "item", type: collectionClassAstTemplateTypeT)],
                    annotation: nil
                ),
                .init(
                    isStatic: false,
                    visibilityModifier: .PUBLIC,
                    name: "isEmpty",
                    params: [],
                    annotation: AstBooleanType(startLocation: .dub(), endLocation: .dub())
                ),
                .init(
                    isStatic: false,
                    visibilityModifier: .PUBLIC,
                    name: "hasNext",
                    params: [],
                    annotation: AstBooleanType(startLocation: .dub(), endLocation: .dub())
                )
            ]
        )
        
        let stackClassAstTemplateTypeT = AstTemplateTypeName(
            belongingClass: "Stack",
            name: .dummyToken(tokenType: .IDENTIFIER, lexeme: "T"),
            startLocation: .dub(),
            endLocation: .dub()
        )
        
        let stackClass = createClass(
            name: "Stack",
            templates: ["T"],
            methods: [
                .init(
                    isStatic: false,
                    visibilityModifier: .PUBLIC,
                    name: "push",
                    params: [.init(name: "val", type: stackClassAstTemplateTypeT)],
                    annotation: nil
                ),
                .init(
                    isStatic: false,
                    visibilityModifier: .PUBLIC,
                    name: "pop",
                    params: [],
                    annotation: stackClassAstTemplateTypeT
                ),
                .init(
                    isStatic: false,
                    visibilityModifier: .PUBLIC,
                    name: "isEmpty",
                    params: [],
                    annotation: AstBooleanType(startLocation: .dub(), endLocation: .dub())
                ),
                .init(
                    isStatic: false,
                    visibilityModifier: .PUBLIC,
                    name: "top",
                    params: [],
                    annotation: stackClassAstTemplateTypeT
                )
            ]
        )
        
        let queueClassAstTemplateTypeT = AstTemplateTypeName(
            belongingClass: "Queue",
            name: .dummyToken(tokenType: .IDENTIFIER, lexeme: "T"),
            startLocation: .dub(),
            endLocation: .dub()
        )
        
        let queueClass = createClass(
            name: "Queue",
            templates: ["T"],
            methods: [
                .init(
                    isStatic: false,
                    visibilityModifier: .PUBLIC,
                    name: "enqueue",
                    params: [.init(name: "val", type: queueClassAstTemplateTypeT)],
                    annotation: nil
                ),
                .init(
                    isStatic: false,
                    visibilityModifier: .PUBLIC,
                    name: "dequeue",
                    params: [],
                    annotation: queueClassAstTemplateTypeT
                ),
                .init(
                    isStatic: false,
                    visibilityModifier: .PUBLIC,
                    name: "isEmpty",
                    params: [],
                    annotation: AstBooleanType(startLocation: .dub(), endLocation: .dub())
                ),
                .init(
                    isStatic: false,
                    visibilityModifier: .PUBLIC,
                    name: "front",
                    params: [],
                    annotation: queueClassAstTemplateTypeT
                )
            ]
        )
        
        var newAst = ast
        newAst.insert(contentsOf: [collectionClass, stackClass, queueClass], at: 0)
        return newAst
    }
}
