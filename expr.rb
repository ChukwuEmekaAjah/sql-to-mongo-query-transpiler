class DDL
    attr_reader :command, :object, :identifier

    def initialize(command, object, identifier)
        @command = command
        @object = object
        @identifier = identifier
    end

    def name
        self.class.to_s
    end

    def to_s
        self.class.to_s
    end

    def accept(visitor)
        visitor.call(self)
    end
end

class DML
    def name
        self.class.to_s
    end

    def to_s
        self.class.to_s
    end

    def accept(visitor)
        visitor.call(self)
    end
end

class DeleteDML < DML
    attr_reader :command, :object_name, :conditions
    def initialize(command, object_name, conditions)
        @command = command
        @object_name = object_name
        @conditions = conditions
    end

    def print
        puts "<DeleteDML @command= #{@command} @object_name= #{@object_name} @conditions= #{@conditions}>"
    end
end

class ExplainDML < DML
    attr_reader :statement

    def initialize(statement)
        @statement = statement
    end

    def print
        puts "<ExplainDML @statement = #{@statement}>"
    end
end

class UpdateDML < DML
    attr_reader :command, :object_name, :conditions, :assignments
    def initialize(command, object_name, assignments, conditions)
        @command = command
        @object_name = object_name
        @conditions = conditions
        @assignments = assignments
    end

    def print
        puts "<UpdateDML @assignments = #{@assignments} @command= #{@command} @object_name= #{@object_name} @conditions= #{@conditions}>"
    end
end

class SelectDML < DML
    attr_reader :command, :object_name, :conditions, :selected_fields
    def initialize(command, object_name, selected_fields, conditions)
        @command = command
        @object_name = object_name
        @conditions = conditions
        @selected_fields = selected_fields
    end

    def print
        puts "<SelectDML @selected_fields = #{@selected_fields} @command= #{@command} @object_name= #{@object_name} @conditions= #{@conditions}>"
    end
end

class InsertDML < DML
    attr_reader :command, :object_name, :assignments, :values
    def initialize(command, object_name, assignments, values)
        @command = command
        @object_name = object_name
        @values = values
        @assignments = assignments
    end

    def print
        puts "<InsertDML @assignments = #{@assignments} @command= #{@command} @object_name= #{@object_name} @values= #{@values}>"
    end
end

class Expr

    def name
        self.class.to_s
    end

    def accept(visitor)
        visitor.call(self)
    end
end

class Binary < Expr
    attr_reader :left, :operator, :right
    def initialize(left, operator, right)
        @left = left
        @operator = operator
        @right = right
    end
end

class Logical < Expr
    attr_reader :left, :operator, :right
    def initialize(left, operator, right)
        @left = left
        @operator = operator
        @right = right
    end
end

class Literal < Expr
    attr_reader :value
    def initialize(value)
        @value = value
    end
end

class Field < Expr
    attr_reader :value
    def initialize(value)
        @value = value
    end
end

class Unary < Expr
    attr_reader :operator, :right
    def initialize(operator, right)
        @operator = operator
        @right = right
    end
end

class Grouping < Expr
    attr_reader :expression
    def initialize(expression)
        @expression = expression
    end
end

class ProjectedField < Expr
    attr_reader :original_name, :alias_name

    def initialize(original_name, alias_name)
        @original_name = original_name
        @alias_name = alias_name
    end

end
