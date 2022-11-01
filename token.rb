module TokenTypes
    TYPES = [:LEFT_PAREN, :RIGHT_PAREN,
    :COMMA, :DOT, :MINUS, :PLUS, :SEMICOLON, :SLASH, :STAR,
  
    # One or two character tokens.
    :BANG, :BANG_EQUAL,
    :EQUAL, :EQUAL_EQUAL,
    :GREATER, :GREATER_EQUAL,
    :LESS, :LESS_EQUAL,
  
    # Literals.
    :IDENTIFIER, :STRING, :NUMBER,
  
    # Keywords.
    :AND, :FALSE, :OR, :NOT,
    :TRUE, :EOl]
end

class Token
    attr_accessor :literal, :type, :line_position, :lexeme

    def initialize(literal, type, lexeme, line_position)
        @literal = literal
        @line_position = line_position
        @type = type
        @lexeme = lexeme
    end

    def to_s
        "<Token @literal= #{@literal} @line_position=#{@line_position} @type=#{@type}>"
    end
end