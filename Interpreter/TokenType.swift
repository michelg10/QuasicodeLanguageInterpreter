enum TokenType {
    // Single-character tokens
    case LEFT_PAREN, RIGHT_PAREN, LEFT_BRACE, RIGHT_BRACE, LEFT_BRACKET, RIGHT_BRACKET, COMMA, DOT, MINUS, PLUS, SLASH, STAR, COLON
    
    // One or two character tokens
    case BANG_EQUAL, EQUAL, EQUAL_EQUAL, GREATER, GREATER_EQUAL, LESS, LESS_EQUAL
    
    // Literals
    case IDENTIFIER, STRING, INTEGER, FLOAT
    
    // Keywords
    // Types
    case INT, DOUBLE, BOOLEAN, ANY, NEW
    
    // Literals
    case TRUE, FALSE, NULL
    
    // Control flow
    case LOOP, FROM, TO, WHILE, UNTIL, IF, THEN, ELSE, BREAK, CONTINUE
    
    // Operations
    case MOD, DIV, AND, OR, NOT, IS
    
    // Statements
    case OUTPUT, INPUT
    
    // Functions
    case FUNCTION, RETURN
    
    // Classes
    case CLASS, EXTENDS, PRIVATE, PUBLIC, STATIC, THIS, SUPER
    
    // Other
    case END
    
    // Other
    case EOF, EOL
}
