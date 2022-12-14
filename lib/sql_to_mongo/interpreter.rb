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
            return SQLToMongo::Utils::FunctionConverters.send(expr.function.literal.to_sym, arguments, column_name)
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
            {expr.alias_name.literal => expr.original_name.is_a?(Expr) ? execute(expr.original_name) : "$#{expr.original_name.value}"}
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
            if dml.clauses && dml.clauses.has_key?("where")
                result = execute(dml.clauses["where"])
                conditions.merge!(result) unless result.nil?
            end

            selected_fields = {}
            query_type = '.find'
            dml.selected_fields.each do |field|
                if field.is_a?(ProjectedField)
                    selected_fields.merge!(execute(field))
                    query_type = '.aggregate'
                    next
                end
                selected_fields.merge!({field.value => 1 })
            end

            query_type = '.aggregate' if dml.clauses.has_key?("group_by")
            if query_type == '.aggregate'
                aggregate_body = []

                unless conditions.nil?
                    aggregate_body << {
                        "$match": conditions
                    }
                end

                unless selected_fields.nil?
                    aggregate_body << {
                        "$project": selected_fields
                    }
                end

                if dml.clauses
                    if dml.clauses.has_key?("order_by")
                        aggregate_body << {
                            "$sort" => dml.clauses["order_by"].map { |k,v| [k, v.literal == 'asc' ? 1 : -1] }.to_h
                        }
                    end

                    if dml.clauses.has_key?("offset")
                        aggregate_body << {
                            "$skip" => execute(dml.clauses["offset"]).to_i
                        }
                    end

                    if dml.clauses.has_key?("limit")
                        aggregate_body << {
                            "$limit" => execute(dml.clauses["limit"]).to_i
                        }
                    end

                    if dml.clauses.has_key?("group_by")
                        aggregate_body << {
                            "$group" => {
                                "_id" => dml.clauses["group_by"].map { |k| [k.literal, "$#{k.literal}"]}.to_h
                            }
                        }
                    end

                    if dml.clauses.has_key?("having")
                        aggregate_body << {
                            "$match" => execute(dml.clauses["having"])
                        }
                    end
                    
                end

                query += "#{query_type}(#{JSON.generate(aggregate_body)})"
                return query
            end
            query += "#{query_type}(#{JSON.generate(conditions)}, #{JSON.generate(selected_fields)})"

            if dml.clauses
                if dml.clauses.has_key?("order_by")
                    order_fields = dml.clauses["order_by"].map { |k,v| [k, v.literal == 'asc' ? 1 : -1] }.to_h
                    query += ".sort(#{JSON.generate(order_fields)})"
                end

                if dml.clauses.has_key?("offset")
                    query += ".skip(#{execute(dml.clauses["offset"]).to_i})"
                end

                if dml.clauses.has_key?("limit")
                    query += ".limit(#{execute(dml.clauses["limit"]).to_i})"
                end
            end

            return query
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
                if left.is_a?(Float) && right.is_a?(Float)
                    return left - right
                end
                left = "$#{left}" if left.is_a?(String)
                right = "$#{right}" if right.is_a?(String)

                return {"$subtract" => [left, right]}
            when :SLASH
                if left.is_a?(Float) && right.is_a?(Float)
                    raise SQLToMongo::Errors::InterpreterError, "ZeroDivisionError for operator #{expr.operator}" if right.zero?
                    return Float(left) / Float(right)
                end

                left = "$#{left}" if left.is_a?(String)
                right = "$#{right}" if right.is_a?(String)

                return {"$divide" => [left, right]}
            when :STAR
                if left.is_a?(Float) && right.is_a?(Float)
                    return Float(left) * Float(right)
                end
                left = "$#{left}" if left.is_a?(String)
                right = "$#{right}" if right.is_a?(String)

                return {"$multiply" => [left, right]}
            when :PLUS
                if left.is_a?(Float) && right.is_a?(Float)
                    return left + right
                end
                left = "$#{left}" if left.is_a?(String)
                right = "$#{right}" if right.is_a?(String)

                return {"$sum" => [left, right]}
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