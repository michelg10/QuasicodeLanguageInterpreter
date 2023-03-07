extension Builtins {
    // swiftlint:disable:next function_body_length
    static func addStringClassToSymbolTable(_ symbolTable: SymbolTables) {
        let stringClassScopeSymbol = symbolTable.createTableAtScope()
        let stringClassSymbolTableIndex = symbolTable.addToSymbolTable(
            symbol: ClassSymbol(
                name: "String<>",
                displayName: "String",
                nonSignatureName: "String",
                classScopeSymbolTableIndex: stringClassScopeSymbol,
                upperClass: nil,
                depth: 1,
                parentOf: []
            )
        )
        let stringClassType = QsClass(name: "String", id: stringClassSymbolTableIndex)
        symbolTable.addToSymbolTable(symbol: ClassNameSymbol(name: "String"))
        symbolTable.gotoTable(stringClassScopeSymbol)
        defer {
            symbolTable.resetScope()
        }
        func addMethod(name: String, functionParams: [FunctionParam], paramRange: ClosedRange<Int>, isStatic: Bool, returnType: QsType) {
            let symbolIndex = symbolTable.addToSymbolTable(
                symbol: FunctionSymbol(
                    name: name,
                    functionParams: functionParams,
                    paramRange: paramRange,
                    returnType: returnType
                )
            )
            let funcNameSymbolName = "#FuncName#\(name)"
            if let functionNameSymbol = symbolTable.queryAtScopeOnly(funcNameSymbolName) as? FunctionNameSymbol {
                functionNameSymbol.belongingFunctions.append(symbolIndex)
            } else {
                symbolTable.addToSymbolTable(
                    symbol: FunctionNameSymbol(
                        isForMethods: true,
                        name: funcNameSymbolName,
                        belongingFunctions: [symbolIndex]
                    )
                )
            }
        }
        
        // the instance methods
        addMethod(
            name: "charAt",
            functionParams: [.init(name: "index", type: QsInt())],
            paramRange: 1...1,
            isStatic: false,
            returnType: stringClassType
        )
        addMethod(
            name: "codePointAt",
            functionParams: [.init(name: "index", type: QsInt())],
            paramRange: 1...1,
            isStatic: false,
            returnType: QsInt()
        )
        addMethod(
            name: "length",
            functionParams: [],
            paramRange: 0...0,
            isStatic: false,
            returnType: QsInt()
        )
        addMethod(
            name: "contains",
            functionParams: [.init(name: "substring", type: stringClassType)],
            paramRange: 1...1,
            isStatic: false,
            returnType: QsBoolean()
        )
        addMethod(
            name: "indexOf",
            functionParams: [.init(name: "substring", type: stringClassType)],
            paramRange: 1...1,
            isStatic: false,
            returnType: QsInt()
        )
        addMethod(
            name: "substring",
            functionParams: [.init(name: "startIndex", type: QsInt()), .init(name: "endIndex", type: QsInt())],
            paramRange: 1...2,
            isStatic: false,
            returnType: stringClassType
        )
        addMethod(
            name: "toLowerCase",
            functionParams: [],
            paramRange: 0...0,
            isStatic: false,
            returnType: stringClassType
        )
        addMethod(
            name: "toUpperCase",
            functionParams: [],
            paramRange: 0...0,
            isStatic: false,
            returnType: stringClassType
        )
        addMethod(
            name: "replace",
            functionParams: [.init(name: "of", type: stringClassType), .init(name: "with", type: stringClassType)],
            paramRange: 2...2,
            isStatic: false,
            returnType: stringClassType
        )
        
        // the static methods
        addMethod(
            name: "fromCharCode",
            functionParams: [.init(name: "charCode", type: QsInt())],
            paramRange: 1...1,
            isStatic: true,
            returnType: stringClassType
        )
        addMethod(
            name: "fromCharCodes",
            functionParams: [.init(name: "charCodes", type: QsArray(contains: QsInt()))],
            paramRange: 1...1,
            isStatic: true,
            returnType: stringClassType
        )
        addMethod(
            name: "valueOf",
            functionParams: [.init(name: "value", type: QsInt())],
            paramRange: 1...1,
            isStatic: true,
            returnType: stringClassType
        )
        addMethod(
            name: "valueOf",
            functionParams: [.init(name: "value", type: QsDouble())],
            paramRange: 1...1,
            isStatic: true,
            returnType: stringClassType
        )
    }
}
