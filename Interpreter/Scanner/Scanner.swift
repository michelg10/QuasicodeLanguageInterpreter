class Scanner {
    private var source: String
    private var tokens: [Token] = []
    private var problems: [InterpreterProblem] = []
    private var start: String.Index
    private var startLocation = InterpreterLocation.init(line: 1, column: 1)
    private var current: String.Index
    private var currentLocation = InterpreterLocation.init(line: 1, column: 1)
    
    func trimWhitespaceOfSingleLineStringWithTrailingForwardSlash(_ s: String.SubSequence) -> String.SubSequence {
        if s.count == 0 {
            return s
        }
        var i=s.endIndex
        while i != s.startIndex {
            i = s.index(i, offsetBy: -1)
            
            if !isWhiteSpace(s[i]) {
                if s[i] != "\\" {
                    return s
                }
                break
            }
        }
        
        return s[s.startIndex...i]
    }
    
    func trimWhitespaceOfMultilineString(_ s: String) -> String {
        var lines = s.split(separator: "\n", omittingEmptySubsequences: false)
        for i in 0..<lines.count {
            lines[i] = trimWhitespaceOfSingleLineStringWithTrailingForwardSlash(lines[i])
        }
        
        var result = ""
        for i in 0..<lines.count {
            result += lines[i] + "\n"
        }
        
        return result
    }
    
    static let keywords:[String:TokenType] = [
        "int"      : .INT,
        "double"   : .DOUBLE,
        "boolean"  : .BOOLEAN,
        "any"      : .ANY,
        "new"      : .NEW,
        
        "true"     : .TRUE,
        "false"    : .FALSE,
        "null"     : .NULL,
        
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
        
        "mod"      : .MOD,
        "div"      : .DIV,
        "and"      : .AND,
        "or"       : .OR,
        "not"      : .NOT,
        "MOD"      : .MOD,
        "DIV"      : .DIV,
        "AND"      : .AND,
        "OR"       : .OR,
        "NOT"      : .NOT,
        
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
        
        "end"      : .END,
    ]
    
    init(source: String) {
        self.source = source
        self.start = source.startIndex
        self.current = self.start;
        
        self.source = trimWhitespaceOfMultilineString(self.source)
    }
    
    private func isAtEnd() -> Bool {
        return current == source.endIndex;
    }
    
    private func isAtEnd(_ index:String.Index) -> Bool {
        return index == source.endIndex
    }
    
    func scanTokens() -> ([Token], [InterpreterProblem]) {
        while !isAtEnd() {
            start = current
            startLocation = currentLocation
            scanToken()
        }
        
        tokens.append(.init(tokenType: .EOL, lexeme: "", start: .init(line: currentLocation.line, column: 0), end: .init(line: currentLocation.line, column: 0)))
        tokens.append(.init(tokenType: .EOF, lexeme: "", start: .init(line: currentLocation.line, column: 0), end: .init(line: currentLocation.line, column: 0)))
        return (tokens, problems)
    }
    
    private func consumeWhiteSpace() {
        while !isAtEnd() && !isWhiteSpace(peek()!) {
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
            // add new problem
//            problems
        }
    }
    
    private func scanToken() {
        let c = advance()
        switch c {
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
            } else if match(expected: "*") {
                blockComment()
            } else {
                addToken(type: .SLASH)
            }
        case " ": break
        case "\r": break
        case "\t": break
        case "\n":
            addToken(type: .EOL)
        case "\"":
            string();
        default:
            if isDigit(c) {
                number()
            } else if isAlpha(c) {
                identifier()
            } else if c == "!" && peek() == "=" {
                advance()
                addToken(type: .BANG_EQUAL)
            } else {
                problems.append(.init(message: "Unexpected character \(c)", start: currentLocation, end: currentLocation))
            }
        }
    }
    
    private func blockComment() {
        
        var blockCommentLevel = 1
        while blockCommentLevel>0 {
            let c = advance()
            if c == "*" {
                if match(expected: "/") {
                    blockCommentLevel-=1
                }
            } else if c == "/" {
                if match(expected: "*") {
                    blockCommentLevel+=1
                }
            }
        }
    }
    
    private func number() {
        // handle number literals
        
        var isDouble = false
        
        while isDigit(peek()) {
            advance()
        }
        
        // if there is a decimal
        if peek() == "."&&isDigit(peekNext()) {
            isDouble = true
            // consume the decimal point
            advance()
            
            while isDigit(peek()) {
                advance()
            }
        }
        
        let nextCharacter = peek()
        if nextCharacter == "f" {
            isDouble = true
        } else if nextCharacter == "l" {
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
        let startingQuoteLocation = InterpreterLocation.init(line: currentLocation.line, column: currentLocation.column-1)
        var value = ""
        while peek() != "\"" && !isAtEnd() {
            let c = advance()
            if c == "\\" {
                if isAtEnd() {
                    problems.append(.init(message: "Empty escape sequence", start: .init(line: currentLocation.line, column: currentLocation.column-1), end: .init(line: currentLocation.line, column: currentLocation.column-1)))
                    return
                }
                let next = advance()
                switch next {
                case "\n":
                    // ignore it
                    break
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
                    // error!
                    problems.append(.init(message: "Invalid escape sequence \"\\\(next)\"", start: .init(line: currentLocation.line, column: currentLocation.column-2), end: .init(line: currentLocation.line, column: currentLocation.column-1)))
                }
            } else {
                value = value+String(c)
            }
        }
        
        if isAtEnd() {
            problems.append(.init(message: "Unterminated string literal", start: startingQuoteLocation, end: startingQuoteLocation))
            return
        }
        
        advance() // consume the closing "
        
        addToken(type: .STRING, value: value)
    }
    
    private func isWhiteSpace(_ c:Character) -> Bool {
        if c.isASCII {
            if c==" " || c=="\r" || c=="\t" {
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
        
        if (!isAtEnd(nextIndex)) {
            return source[nextIndex]
        }
        
        return nil
    }
    
    private func isAlpha(_ c:Character?) -> Bool {
        if c == nil {
            return false
        }
        if c!.isASCII {
            let asciiValue = c!.asciiValue!
            if asciiValue>=97 && asciiValue<=122 {
                return true
            }
            if asciiValue>=65 && asciiValue<=90 {
                return true
            }
        }
        return false
    }
    
    private func isDigit(_ c: Character?) -> Bool {
        if c == nil {
            return false
        }
        if c!.isASCII {
            let asciiValue = c!.asciiValue!
            if asciiValue>=48 && asciiValue<=57 {
                return true
            }
        }
        return false
    }
    
    private func isAlphaNumeric(_ c:Character?) -> Bool {
        return isAlpha(c) || isDigit(c)
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
    
    private func advance() -> Character {
        let value = source[current]
        current = source.index(current, offsetBy: 1)
        
        if !isAtEnd() {
            if value == "\n" {
                currentLocation.line += 1
                currentLocation.column = 1
            } else {
                currentLocation.column+=1 
            }
        }
        
        return value
    }
    
    private func addToken(type: TokenType, value: Any? = nil) {
        let lexeme: String = String(source[start..<current])
        tokens.append(.init(tokenType: type, lexeme: lexeme, start: startLocation, end: .init(line: currentLocation.line - (type == .EOL ? 1 : 0), column: currentLocation.column), value: value))
    }
}
