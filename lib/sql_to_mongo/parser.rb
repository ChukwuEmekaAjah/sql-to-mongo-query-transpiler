require_relative './expr'
require_relative './errors'

module SQLToMongo
    class Parser
        
        def initialize(tokens)
            @tokens = tokens
            @current = 0
        end

        DML_KEYWORDS = {
            "SELECT" => true,
            "INSERT" => true,
            "UPDATE" => true,
            "DELETE" => true,
        }

        def parse
            statement
        end

        def statement
            return explain_statement if string_match('explain')
            return data_manipulation_statement if string_match(*DML_KEYWORDS.keys.map {|key| key.downcase})
        end

        def explain_statement
            advance
            dml_statement = data_manipulation_statement
            return ExplainDML.new(dml_statement)
        end

        def data_manipulation_statement
            command = previous
            return select_statement if command.lexeme == 'select'
            return update_statement if command.lexeme == 'update'
            return insert_statement if command.lexeme == 'insert'
            return delete_statement if command.lexeme == 'delete'

            raise SQLToMongo::Errors::ParserError.new(
                "Command #{command.lexeme} at position #{command.line_position} is not supported",
                command
            )
        end

        def select_statement
            command = previous
            selected_fields = []
            if peek.literal == '*'
                advance
            else
                while peek.literal != 'from'
                    selected_field = expression

                    if peek.literal == 'as' && ([:PARAM, :IDENTIFIER].include? peek(1).type)
                        selected_field = ProjectedField.new(selected_field, peek(1))
                        1.upto(2) {|_| advance}
                    end
                    selected_fields << selected_field
                    if peek.literal != 'from'
                        consume(:COMMA, "Expected ',' after each value in select statement") unless is_at_end?
                    end
                end
            end

            predicate = advance
            if predicate.type != :KEYWORD || predicate.literal != 'from'
                raise SQLToMongo::Errors::ParserError.new(
                    "Expected keyword 'from' in 'select' statement",
                    predicate
                )
            end

            object_name = identifier

            clause = clauses
            consume(:SEMICOLON, "Expected ';' at the end of statement")
            return SelectDML.new(command, object_name, selected_fields, clause)
        end

        def clauses
            {
                "where" => condition,
                **aggregators
            }
        end

        def aggregators
            filters = {}
            while peek.type == :KEYWORD
                if peek.literal == 'limit'
                    advance
                    filters['limit'] = expression
                end

                if peek.literal == 'offset'
                    advance
                    filters['offset'] = expression
                end

                if peek.literal == 'order' && peek(1).literal == 'by'
                    advance && advance
                    filters['order_by'] = ordering
                end

                if peek.literal == 'group' && peek(1).literal == 'by'
                    advance && advance
                    filters['group_by'] = grouping
                end

                if peek.literal == 'having'
                    filters['having'] = condition('having')
                end
            end
            return filters
        end

        def ordering(order_hash = {})
            while match(:PARAM, :IDENTIFIER)
                field = previous
                value = string_match('asc', 'desc') && previous
                order_hash[field.literal] = value
                if peek.literal != ';' && peek.type != :KEYWORD
                    consume(:COMMA, "Expected ',' after each value in group by clause") unless is_at_end?
                end
            end
            return order_hash
        end

        def grouping
            fields = []
            while match(:PARAM, :IDENTIFIER)
                fields << previous
                if peek.literal != ';' && peek.type != :KEYWORD
                    consume(:COMMA, "Expected ',' after each value in group by clause") unless is_at_end?
                end
            end
            return fields
        end

        def insert_statement
            command = previous
            predicate = advance

            if predicate.type != :KEYWORD || predicate.literal != 'into'
                raise SQLToMongo::Errors::StatementError, "Expected keyword 'into' in 'insert' statement"
            end

            object_name = identifier

            assignments = []
            
            if peek.type == :LEFT_PAREN
                advance
                while match(:PARAM, :IDENTIFIER)
                    assignments << previous
                    if peek.literal != 'values' && peek.type != :RIGHT_PAREN
                        consume(:COMMA, "Expected ',' after each value in insert statement") unless is_at_end?
                    end
                end
                consume(:RIGHT_PAREN, "Expected ')' at the end of insert keys")
            end
            advance

            if assignments.length == 0
                raise SQLToMongo::Errors::StatementError, "Expected column names for query since MongoDB is schemaless"
            end
            if previous.literal != 'values'
                raise SQLToMongo::Errors::StatementError, "Expected insert statement to have values"
            end
        
            values = []
            if peek.type == :LEFT_PAREN
                advance
                while !match(:RIGHT_PAREN)
                    values  << expression
                    
                    if peek.type != :RIGHT_PAREN
                        consume(:COMMA, "Expected ',' after each value in insert statement") unless is_at_end?
                    end
                end
            end

            unless assignments.length == values.length
                raise SQLToMongo::Errors::StatementError, "Expected equal number of values and assignment column pairs"
            end
        
            consume(:SEMICOLON, "Expected ';' at the end of statement")
            return InsertDML.new(command, object_name, assignments, values)

        end

        def update_statement
            command = previous
            object_name = identifier
            predicate = advance

            if predicate.type != :KEYWORD || predicate.literal != 'set'
                raise SQLToMongo::Errors::StatementError, "Expected keyword 'set' in 'update' statement"
            end
            assignments = {}

            # get all the assignments
            while match(:PARAM, :IDENTIFIER)
                key = previous.literal
                match(:EQUAL)
                assignments[key] = expression
                
                if peek.literal != 'where' && peek.literal != ';'
                    consume(:COMMA, "Expected ',' after each assignment in update statement") unless is_at_end?
                end
            end
            conditions = condition

            consume(:SEMICOLON, "Expected ';' at the end of statement")
            return UpdateDML.new(command, object_name, assignments, conditions)
        end

        def delete_statement
            command = previous
            predicate = advance
            if predicate.type != :KEYWORD || predicate.literal != 'from'
                raise SQLToMongo::Errors::StatementError, "Expected keyword 'from' after delete statement"
            end
            object_name = identifier
            conditions = condition

            consume(:SEMICOLON, "Expected ';' at the end of statement")
            return DeleteDML.new(command, object_name, conditions)
        end

        def condition(keyword = 'where')
            conditions = nil
            if string_match(keyword)
                conditions = expression
            end
            return conditions
        end

        def expression
            logical_or
        end

        def logical_or
            expr = logic_and

            while string_match( "or")
                operator = previous
                right = logic_and
                expr = Logical.new(expr, operator, right)
            end
            return expr
        end

        def logic_and
            expr = function

            while string_match("and")
                operator = previous
                right = function
                expr = Logical.new(expr, operator, right)
            end
            return expr
        end

        def function
            expr = equality
            if peek.literal == "between"
                while string_match( "between")
                    operator = previous
                    right = expression
                    expr = Function.new(expr, operator, right)
                end
            else
                while string_match("in", "like", "avg")
                    operator = previous
                    right = equality
                    expr = Function.new(expr, operator, right)
                end
            end
            return expr
        end

        def equality
            expr = comparison

            while match(:EQUAL, :BANG_EQUAL)
                operator = previous
                right = comparison
                expr = Binary.new(expr, operator, right)
            end
            return expr
        end

        def comparison
            expr = term

            while match(:GREATER, :GREATER_EQUAL, :LESS, :LESS_EQUAL)
                operator = previous
                right = term
                expr = Binary.new(expr, operator, right)
            end
            return expr
        end

        def term
            expr = factor

            while match(:PLUS, :MINUS)
                operator = previous
                right = factor
                expr = Binary.new(expr, operator, right)
            end
            return expr
        end

        def factor
            expr = unary

            while match(:STAR, :SLASH)
                operator = previous
                right = unary
                expr = Binary.new(expr, operator, right)
            end
            return expr
        end

        def unary
            while match(:BANG, :MINUS)
                operator = previous
                right = unary
                return Unary.new(operator, right)
            end
            return primary
        end

        def primary
            return Literal.new(false) if match(:FALSE)
            return Literal.new(true) if match(:TRUE)
            return Literal.new(nil) if match(:NIL)
    
            if match(:NUMBER, :STRING)
                return Literal.new(previous.literal)
            end

            return Field.new(previous.literal) if match(:IDENTIFIER, :PARAM)
    
            if match(:LEFT_PAREN)
                expr = expression

                if !peek.type == :COMMA
                    consume(:RIGHT_PAREN, "Expect ')' after expression.")
                    return Grouping.new(expr)
                end
                arguments = [expr]
                while match(:COMMA)
                    arguments << expression
                end
                consume(:RIGHT_PAREN, "Expect ')' after expression.")
                return Arguments.new(arguments)
            end
        end

        def match(*types)
            i = 0
            while i < types.length
                if(check(types[i]))
                    advance
                    return true
                end
                i += 1
            end
            return false
        end

        def string_match(*types)
            i = 0
            while i < types.length
                if(string_check(types[i]))
                    advance
                    return true
                end
                i += 1
            end
            return false
        end

        def identifier
            return previous if match(:IDENTIFIER, :PARAM)
        end
    
        def check(type)
            return false if(is_at_end?)
            return peek.type == type
        end

        def string_check(lexeme)
            return false if(is_at_end?)
            return peek.lexeme == lexeme
        end

        def consume(type, message)
            return advance if check(type)
            raise SQLToMongo::Errors::StatementError, message + " but got #{previous&.literal || previous&.value || previous&.lexeme}"
        end
    
        def advance
            @current += 1 if !is_at_end?
            return previous
        end
    
        def is_at_end?
            return @current >= @tokens.length
        end
    
        def peek(pos = 0)
            @tokens[@current + pos]
        end
    
        def previous
            @tokens[@current - 1]
        end
    end
end