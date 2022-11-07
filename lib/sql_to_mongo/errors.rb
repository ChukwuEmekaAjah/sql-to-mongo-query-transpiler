module SQLToMongo
    module Errors
        class Error < StandardError; end
        class StatementError < Error; end
        class InterpreterError < Error; end

        class ParserError < Error
            attr_reader :token
        
            def initialize(message, token)
                @token = token
                @message = message
                super(message)
            end
        end
        
        class ScannerError < Error
            attr_reader :message, :character, :position
        
            def initialize(message, character, position)
                @character = character
                @position = position
                @message = message
                super(message)
            end
        end
    end
end