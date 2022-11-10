require 'json'
require_relative './expr'
require_relative './utils/function_converters'

module SQLToMongo
    class Interpreter

        VISITORS = {
            "ExplainDML" => :visitExplainDML,
            "SelectDML" => :visitSelectDML,
            "UpdateDML" => :visitUpdateDML,
            "DeleteDML" => :visitDeleteDML,
            "InsertDML" => :visitInsertDML,
            "Literal" => :visitLiteralExpr,
            "Binary" => :visitBinaryExpr,
            "Grouping" => :visitGroupExpr,
            "Unary" => :visitUnaryExpr,
            "Field" => :visitFieldExpr,
            "Logical" => :visitLogicalExpr,
            "ProjectedField" => :visitProjectedFieldExpr,
            "Arguments" => :visitArgumentsExpr,
            "Function" => :visitFunctionExpr,
        }

        def visitFunctionExpr(expr)
            column_name = execute(expr.column_name)
            arguments = execute(expr.arguments)
            return {column_name => SQLToMongo::Utils::FunctionConverters.send(expr.function.literal.to_sym, arguments)}
        end

        def visitArgumentsExpr(expr)
            arguments = expr.arguments.map do |arg|
                execute(arg)
            end
            return arguments
        end

        def visitLogicalExpr(expr)
            left = execute(expr.left)
            right = execute(expr.right)

            return {"$#{expr.operator.literal}" => [left, right].compact}
        end

        def visitProjectedFieldExpr(expr)
            {expr.alias_name.literal => "$#{expr.original_name.literal}"}
        end

        def visitFieldExpr(expr)
            return expr.value
        end

        def visitExplainDML(dml)
            query = execute(dml.statement)
            query += '.explain()'
        end

        def visitSelectDML(dml)
            query = 'db.'
            collection = dml.object_name.lexeme
            query += collection

            conditions = {}
            if dml.conditions
                conditions.merge!(execute(dml.conditions))
            end

            selected_fields = {}
            query_type = '.find'
            dml.selected_fields.each do |field|
                if field.is_a?(ProjectedField)
                    selected_fields.merge!(execute(field))
                    query_type = '.aggregate'
                    next
                end
                selected_fields.merge!({field.literal => 1 })
            end

            if query_type == '.aggregate'
                aggregate_body = [
                    {
                        "$match": conditions
                    },
                    {
                        "$project": selected_fields
                    }
                ]
                query += "#{query_type}(#{JSON.generate(aggregate_body)})"
                return query
            end
            query += "#{query_type}(#{JSON.generate(conditions)}, #{JSON.generate(selected_fields)})"
        end

        def visitUpdateDML(dml)
            query = 'db.'
            collection = dml.object_name.lexeme
            query += collection
            query += '.updateMany'

            updates = {}
            dml.assignments.each do |key, value|
                updates[key] = execute(value)
            end

            conditions = {}
            if dml.conditions
                conditions.merge!(execute(dml.conditions))
            end

            query += "(#{JSON.generate(conditions)}, #{JSON.generate(updates)})"
        end

        def visitInsertDML(dml)
            query = 'db.'
            collection = dml.object_name.lexeme
            query += collection
            query += '.insertOne'

            insertions = {}
            dml.assignments.each_with_index do |assignment, index|
                insertions[assignment.lexeme] = execute(dml.values[index])
            end
            query += "(#{JSON.generate(insertions)})"
        end

        def visitDeleteDML(dml)
            query = 'db.'
            collection = dml.object_name.lexeme
            query += collection
            query += '.deleteMany'
            conditions = {}

            if dml.conditions
                conditions.merge!(execute(dml.conditions))
            end
            query += "(#{JSON.generate(conditions)})"
        end

        def visitLiteralExpr(expr)
            expr.value
        end

        def visitUnaryExpr(expr)
            right = execute(expr.right)

            case expr.operator.type
            when :BANG
                return !isTruthy(right)
            when :MINUS
                return -right
            end

            return nil
        end

        def checkNumberOperand(operator, operand)
            return nil if operand.is_a?(Float)
            raise SQLToMongo::Errors::InterpreterError,  "Operand for #{operator} must be a number"
        end

        def isTruthy(object)
            return false if object == nil
            if object.is_a?(TrueClass)
                return true
            elsif object.is_a?(FalseClass)
                return false
            end
            return true
        end

        def isEqual(left, right)
            return true if left == nil && right == nil
            return false if left == nil
            return left.eql?(right)
        end

        def visitGroupExpr(expr)
            execute(expr.expression)
        end

        def visitBinaryExpr(expr)
            left = execute(expr.left)
            right = execute(expr.right)

            case expr.operator.type
            when :MINUS
                checkNumberOperand(expr.operator, right)
                return left - right
            when :SLASH
                checkNumberOperands(expr.operator, left, right)
                raise SQLToMongo::Errors::InterpreterError, "ZeroDivisionError for operator #{expr.operator}" if right.zero?
                return Float(left)/Float(right)
            when :STAR
                checkNumberOperands(expr.operator, left, right)
                return Float(left) * Float(right)
            when :PLUS
                if left.is_a?(Float) && right.is_a?(Float)
                return left + right
                end

                if left.is_a?(String) && right.is_a?(String)
                return left + right
                end

                if left.is_a?(String) || right.is_a?(String)
                return left.to_s + right.to_s
                end
                raise SQLToMongo::Errors::InterpreterError, "Operands must be two numbers or two strings #{expr.operator}"
            when :GREATER
                return {left => {'$gt' => right}}
            when :GREATER_EQUAL
                return {left => {'$gte' => right}}
            when :LESS
                return {left => {'$lt' => right}}
            when :LESS_EQUAL
                return {left => {'$lte' => right}}
            when :BANG_EQUAL
                return {left => {'$ne' => right}}
            when :EQUAL
                return {left => right}
            end

            return nil
        end

        def checkNumberOperands(operator, left, right)
            return nil if left.is_a?(Float) && right.is_a?(Float)
            raise SQLToMongo::Errors::InterpreterError, "Operands must be a numbers for operator #{operator}"
        end

        def interpret(statement)
            execute(statement)
        end

        def execute(statement)
            return nil if statement.nil?
            statement.accept(method(VISITORS[statement.class.to_s]))
        end
    end
end