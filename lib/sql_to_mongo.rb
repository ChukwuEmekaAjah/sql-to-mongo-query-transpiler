require_relative './sql_to_mongo/scanner'
require_relative './sql_to_mongo/parser'
require_relative './sql_to_mongo/interpreter'

module SQLToMongo
    class Transpiler
        attr_accessor :statement
        attr_reader :parsed_statement, :tokens, :interpreter

        def initialize(statement)
            @statement = statement
            @tokens = SQLToMongo::Scanner.new(@statement).scan_tokens
            @interpreter = SQLToMongo::Interpreter.new
        end

        def rescan
            @tokens = SQLToMongo::Scanner.new(@statement).scan_tokens
            self
        end

        def parse
            @parsed_statement = SQLToMongo::Parser.new(@tokens).parse
            self
        end

        def transpile
            raise SQLToMongo::Errors::Error, "Please first parse statement before transpiling" unless @parsed_statement
            @interpreter.interpret(@parsed_statement)
        end

    end
end