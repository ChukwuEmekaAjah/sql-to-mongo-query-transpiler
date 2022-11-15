require_relative './token'
require_relative './keywords'
require_relative './errors'

module SQLToMongo
    class Scanner
        attr_reader :source, :tokens

        def initialize(source)
            @source = source
            @tokens = []
            @current = 0
        end

        def scan_tokens()
            while !is_at_end? do
                @start = @current
                c = move_forward
                case c
                when '('
                    @tokens << Token.new('(', :LEFT_PAREN, nil, @current)
                when ')'
                    @tokens << Token.new(')', :RIGHT_PAREN, nil, @current)
                when ','
                    @tokens << Token.new(',', :COMMA, nil, @current)
                when '-'
                    @tokens << Token.new('-', :MINUS, nil, @current)
                when '+'
                    @tokens << Token.new('+', :PLUS, nil, @current)
                when '*'
                    @tokens << Token.new('*', :STAR, nil, @current)
                when '/'
                    @tokens << Token.new('/', :SLASH, nil, @current)
                when ';'
                    @tokens << Token.new(';', :SEMICOLON, nil, @current)
                when '|'
                    if peek == '|'
                        @tokens << Token.new('or', :KEYWORD, 'or', @current)
                    end
                when '&'
                    if peek == '&'
                        @tokens << Token.new('and', :KEYWORD, 'and', @current)
                    end
                when '!'
                    if peek == '='
                        @tokens << Token.new('!=', :BANG_EQUAL, nil, @current)
                        move_forward
                    end
                when '='
                    @tokens << Token.new('=', :EQUAL, nil, @current)
                when '>'
                    if peek == '='
                        @tokens << Token.new('>=', :GREATER_EQUAL, nil, @current)
                        move_forward
                    else
                        @tokens << Token.new('>', :GREATER, nil, @current)
                    end
                when '<'
                    if peek == '='
                        @tokens << Token.new('<=', :LESS_EQUAL, nil, @current)
                        move_forward
                    else
                        @tokens << Token.new('<', :LESS, nil, @current)
                    end
                when /^[0-9]/
                    number
                when /"/
                    string
                when /'/
                    param
                when /(\s|\t|\n|\r)+/
                    nil
                when /[a-zA-Z0-9]/
                    identifier
                else
                    raise SQLToMongo::Errors::StatementError, "Invalid character #{c} at position #{@current} in statement"
                end
            end
            return @tokens
        end

        def move_forward
            char = @source[@current]
            @current += 1
            char
        end

        def is_at_end?
            @current >= @source.length
        end

        def is_number?(c)
            /^[0-9]$/.match?(c)
        end

        def number
            while is_number?(peek)
                move_forward
            end
            
            if peek == '.' && is_number?(peek(1))
                move_forward
                while is_number?(peek)
                    move_forward
                end
            end
            @tokens << Token.new(@source[@start...@current].to_f, :NUMBER, @source[@start...@current].to_f, @start)
        end

        def string
            while !/"/.match?(peek) && !is_at_end?
                move_forward
            end
            move_forward
            @tokens << Token.new(@source[@start+1...@current-1], :STRING, @source[@start+1...@current-1], @start)
        end

        # Represents names/identifiers that have special meaning inside the db
        def param
            while !/'/.match?(peek) && !is_at_end?
                move_forward
            end
            move_forward
            @tokens << Token.new(@source[@start+1...@current-1], :PARAM, @source[@start+1...@current-1], @start)
        end

        def identifier
            while /[a-zA-Z_0-9]/.match?(peek) && !is_at_end?
                move_forward
            end
            
            identifier = @source[@start...@current]
            if Keywords::KEYWORDS[identifier.upcase.to_sym]
                @tokens << Token.new(identifier.downcase, :KEYWORD, identifier.downcase, @start)
                return
            end
            @tokens << Token.new(identifier, :IDENTIFIER, identifier, @start)
        end

        def peek(pos = 0)
            @source[@current + pos]
        end
    end
end
