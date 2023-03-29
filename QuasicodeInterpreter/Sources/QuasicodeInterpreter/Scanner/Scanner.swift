// swiftlint:disable:next type_body_length
public class Scanner {
    private var source: String
    private var tokens: [Token] = []
    private var problems: [InterpreterProblem] = []
    private var start: String.Index
    private var startLocation: InterpreterLocation = .init(index: 0, row: 1, column: 1, logicalRow: 1, logicalColumn: 1)
    private var current: String.Index
    private var currentLocation: InterpreterLocation = .init(index: 0, row: 1, column: 1, logicalRow: 1, logicalColumn: 1)
    
    /// Saves the current location state of the interpreter
    private struct LocationState {
        var start: String.Index
        var startLocation: InterpreterLocation
        var current: String.Index
        var currentLocation: InterpreterLocation
    }
    
    private func saveLocationState() -> LocationState {
        .init(
            start: start,
            startLocation: startLocation,
            current: current,
            currentLocation: currentLocation
        )
    }
    
    private func loadLocationState(_ state: LocationState) {
        start = state.start
        startLocation = state.startLocation
        current = state.current
        currentLocation = state.currentLocation
    }
    
    private static let keywords: [String:TokenType] = [
        "int"      : .INT,
        "double"   : .DOUBLE,
        "boolean"  : .BOOLEAN,
        "any"      : .ANY,
        "new"      : .NEW,
        
        "true"     : .TRUE,
        "false"    : .FALSE,
        
        "loop"     : .LOOP,
        "from"     : .FROM,
        "to"       : .TO,
        "while"    : .WHILE,
        "until"    : .UNTIL,
        "if"       : .IF,
        "then"     : .THEN,
        "else"     : .ELSE,
        "break"    : .BREAK,
        "continue" : .CONTINUE,
        "exit"     : .EXIT,
        
        "mod"      : .MOD,
        "div"      : .DIV,
        "and"      : .AND,
        "or"       : .OR,
        "not"      : .NOT,
        "is"       : .IS,
        "MOD"      : .MOD,
        "DIV"      : .DIV,
        "AND"      : .AND,
        "OR"       : .OR,
        "NOT"      : .NOT,
        "IS"       : .IS,
        
        "OUTPUT"   : .OUTPUT,
        "INPUT"    : .INPUT,
        "output"   : .OUTPUT,
        "input"    : .INPUT,
        
        "function" : .FUNCTION,
        "return"   : .RETURN,
        
        "class"    : .CLASS,
        "extends"  : .EXTENDS,
        "private"  : .PRIVATE,
        "public"   : .PUBLIC,
        "static"   : .STATIC,
        "this"     : .THIS,
        "super"    : .SUPER,
        
        "end"      : .END
    ]
    
    public init(source: String) {
        self.source = source
        self.start = source.startIndex
        self.current = self.start
    }
    
    private func isAtEnd() -> Bool {
        return current == source.endIndex
    }
    
    private func isAtEnd(_ index:String.Index) -> Bool {
        return index == source.endIndex
    }
    
    public func scanTokens(debugPrint: Bool = false) -> ([Token], [InterpreterProblem]) {
        if debugPrint {
            print("----- Scanner -----")
        }
        while !isAtEnd() {
            start = current
            startLocation = currentLocation
            scanToken()
        }
        
        let endOfDocumentLocation: InterpreterLocation = .init(index: source.count, row: startLocation.row + 1, column: 1, logicalRow: startLocation.logicalRow + 1, logicalColumn: 1)
        if tokens.last?.tokenType != .EOL {
            tokens.append(.init(
                tokenType: .EOL,
                lexeme: "",
                start: endOfDocumentLocation,
                end: endOfDocumentLocation
            ))
        }
        tokens.append(.init(
            tokenType: .EOF,
            lexeme: "",
            start: endOfDocumentLocation,
            end: endOfDocumentLocation
        ))
        if debugPrint {
            print("Scanned tokens")
            debugPrintTokens(tokens: tokens, printLocation: true)
            print("\nErrors")
            print(problems)
        }
        return (tokens, problems)
    }
    
    private func consumeWhiteSpace() {
        while !isAtEnd() && isWhiteSpace(peek()!) {
            advance()
        }
    }
    
    private func lineContinuation() {
        advance() // consume the line continuation
        consumeWhiteSpace()
        if isAtEnd() {
            return
        }
        if peek()! != "\n" {
            problems.append(.init(message: "Expected end-of-line after line continuation", start: currentLocation, end: currentLocation))
        } else {
            advance(doLogicalLineIncrement: false)
        }
    }
    
    private func scanToken() {
        let currentCharacter = advance()
        switch currentCharacter {
        case "(":
            addToken(type: .LEFT_PAREN)
        case ")":
            addToken(type: .RIGHT_PAREN)
        case "{":
            addToken(type: .LEFT_BRACE)
        case "}":
            addToken(type: .RIGHT_BRACE)
        case "[":
            addToken(type: .LEFT_BRACKET)
        case "]":
            addToken(type: .RIGHT_BRACKET)
        case ",":
            addToken(type: .COMMA)
        case ".":
            addToken(type: .DOT)
        case "-":
            addToken(type: .MINUS)
        case "+":
            addToken(type: .PLUS)
        case "*":
            addToken(type: .STAR)
        case ":":
            addToken(type: .COLON)
        case "=":
            addToken(type: match(expected: "=") ? .EQUAL_EQUAL : .EQUAL)
        case "<":
            addToken(type: match(expected: "=") ? .LESS_EQUAL : .LESS)
        case ">":
            addToken(type: match(expected: "=") ? .GREATER_EQUAL : .GREATER)
        case "/":
            if match(expected: "/") {
                while peek() != "\n" && !isAtEnd() {
                    let nextChar = advance()
                    if nextChar == "\\" && peek() == "\n" {
                        advance() // consume the \n and keep on going
                    }
                }
                addToken(type: .COMMENT)
            } else if match(expected: "*") {
                blockComment()
                addToken(type: .COMMENT)
            } else {
                addToken(type: .SLASH)
            }
        case "\\":
            lineContinuation()
        case " ": break
        case "\r": break
        case "\t": break
        case "\n":
            addToken(type: .EOL)
        case "\"":
            string()
        default:
            if isDigit(currentCharacter) {
                number()
            } else if isAlpha(currentCharacter) {
                identifier()
            } else if currentCharacter == "!" && peek() == "=" {
                advance()
                addToken(type: .BANG_EQUAL)
            } else {
                problems.append(.init(message: "Unexpected character \(currentCharacter)", start: currentLocation, end: currentLocation))
            }
        }
    }
    
    private func blockComment() {
        let startingCommentLocation: InterpreterLocation = currentLocation.offsetByOnSameLine(-2)
        var blockCommentLevel = 1
        while blockCommentLevel > 0 && !isAtEnd() {
            let currentCharacter = advance()
            if currentCharacter == "*" {
                if match(expected: "/") {
                    blockCommentLevel -= 1
                }
            } else if currentCharacter == "/" {
                if match(expected: "*") {
                    blockCommentLevel += 1
                }
            }
        }
        
        if isAtEnd() && blockCommentLevel != 0 {
            problems.append(.init(message: "Unterminated '/*' comment", start: startingCommentLocation, end: startingCommentLocation))
            return
        }
    }
    
    private func number() {
        // handle number literals
        
        var isDouble = false
        
        while isDigit(peek()) {
            advance()
        }
        
        // if there is a decimal
        if peek() == "." && isDigit(peekNext()) {
            isDouble = true
            // consume the decimal point
            advance()
            
            while isDigit(peek()) {
                advance()
            }
        }
        
        let nextCharacter = peek()
        if nextCharacter == "f" {
            advance()
            isDouble = true
        } else if nextCharacter == "l" {
            advance()
            isDouble = false
        }
        
        let literalString = source[start..<current]
        
        if isDouble {
            addToken(type: .FLOAT, value: Double(literalString))
        } else {
            addToken(type: .INTEGER, value: Int(literalString))
        }
    }
    
    private func identifier() {
        while isAlphaNumeric(peek()) {
            advance()
        }
        
        let text = source[start..<current]
        let type: TokenType = Scanner.keywords[String(text)] ?? .IDENTIFIER
        addToken(type: type)
    }
    
    private func string() {
        let startingQuoteLocation: InterpreterLocation = currentLocation.offsetByOnSameLine(-1)
        var value = ""
        while peek() != "\"" && !isAtEnd() {
            let currentCharacter = advance()
            if currentCharacter == "\\" {
                if isAtEnd() {
                    let problemLocation: InterpreterLocation = currentLocation.offsetByOnSameLine(-1)
                    problems.append(.init(
                        message: "Empty escape sequence",
                        start: problemLocation,
                        end: problemLocation
                    ))
                    return
                }
                let next = advance()
                switch next {
                case "\\":
                    value += "\\"
                case "t":
                    value += "\t"
                case "r":
                    value += "\r"
                case "n":
                    value += "\n"
                case "\"":
                    value += "\""
                default:
                    if isWhiteSpace(next) {
                        // try to see if its a line continuation
                        let locationState = saveLocationState()
                        while !isAtEnd() && isWhiteSpace(peek()!) {
                            advance()
                        }
                        if peek() == "\n" {
                            // it is a line continuation
                            advance()
                            break
                        } else {
                            loadLocationState(locationState)
                        }
                    }
                    
                    // error!
                    problems.append(.init(
                        message: "Invalid escape sequence \"\\\(next)\"",
                        start: currentLocation.offsetByOnSameLine(-2),
                        end: currentLocation.offsetByOnSameLine(-1)
                    ))
                }
            } else {
                value += String(currentCharacter)
            }
        }
        
        if isAtEnd() {
            problems.append(.init(message: "Unterminated string literal", start: startingQuoteLocation, end: startingQuoteLocation))
            return
        }
        
        advance() // consume the closing "
        
        addToken(type: .STRING, value: value)
    }
    
    private func isWhiteSpace(_ character:Character) -> Bool {
        if character.isASCII {
            if character == " " || character == "\r" || character == "\t" {
                return true
            }
        }
        return false
    }
    
    private func peek() -> Character? {
        if isAtEnd() {
            return nil
        }
        
        return source[current]
    }
    
    private func peekNext() -> Character? {
        if isAtEnd() {
            return nil
        }
        let nextIndex = source.index(current, offsetBy: 1)
        
        if !isAtEnd(nextIndex) {
            return source[nextIndex]
        }
        
        return nil
    }
    
    private func isAlpha(_ character:Character?) -> Bool {
        if character == nil {
            return false
        }
        if character == "$" || character == "_" {
            return true
        }
        if character!.isASCII {
            let asciiValue = character!.asciiValue!
            if asciiValue >= 97 && asciiValue <= 122 {
                return true
            }
            if asciiValue >= 65 && asciiValue <= 90 {
                return true
            }
        }
        return false
    }
    
    private func isDigit(_ character: Character?) -> Bool {
        if character == nil {
            return false
        }
        if character!.isASCII {
            let asciiValue = character!.asciiValue!
            if asciiValue >= 48 && asciiValue <= 57 {
                return true
            }
        }
        return false
    }
    
    private func isAlphaNumeric(_ character:Character?) -> Bool {
        return isAlpha(character) || isDigit(character)
    }
    
    private func match(expected: Character) -> Bool {
        if isAtEnd() {
            return false
        }
        if source[current] != expected {
            return false
        }
        
        advance()
        return true
    }
    
    private func advance(doLogicalLineIncrement: Bool = true) -> Character {
        let value = source[current]
        current = source.index(current, offsetBy: 1)
        
        if !isAtEnd() {
            currentLocation.index += 1
            currentLocation.column += 1
            currentLocation.logicalColumn += 1
            if value == "\n" {
                currentLocation.row += 1
                currentLocation.column = 1
                if doLogicalLineIncrement {
                    currentLocation.logicalRow += 1
                    currentLocation.logicalColumn = 1
                }
            }
        }
        
        return value
    }
    
    private func addToken(type: TokenType, value: Any? = nil) {
        let lexeme = String(source[start..<current])
        tokens.append(.init(
            tokenType: type,
            lexeme: lexeme,
            start: startLocation,
            end: currentLocation,
            value: value
        ))
    }
}
