require_relative './scanner'
require_relative './parser'
require_relative './interpreter'

class Transpiler
    attr_accessor :statement, :parsed_statement, :tokens, :interpreter

    def initialize(statement)
        @statement = statement
        @tokens = Scanner.new(@statement).scan_tokens
        @interpreter = Interpreter.new
    end

    def rescan
        @tokens = Scanner.new(@statement).scan_tokens
        self
    end

    def parse
        @parsed_statement = Parser.new(@tokens).parse
        self
    end

    def transpile
        raise StandardError, "Please first parse statement before transpiling" unless @parsed_statement
        @interpreter.interpret(@parsed_statement)
    end

end

# t = Transpiler.new("drop database db1;").transpile
# Transpiler.new("create database db1;").transpile
# p = Transpiler.new("delete from 'table' where age = 30 or 2 > 2;").transpile
# p = Transpiler.new("update Customers set ContactName='Juan', age=23 where Country='Mexico';").transpile
# p = Transpiler.new("insert into table_name (column1, column2, column3) values ('value1', 'value2', 'value3');").transpile
# p2 = Transpiler.new("insert into table_name values ('value1', 'value2', 'value3');").transpile
# p = Transpiler.new("select * from Customers where Country='Mexico';").transpile
# p2 = Transpiler.new("select name, age from Customers where Country='Mexico';").transpile
# p2 = Transpiler.new("explain select name, age from Customers where Country='Mexico';").transpile
# t = Transpiler.new("select name as lname, age from Customers where Country='Mexico';")

# puts p2.print
# puts p.print

t = Transpiler.new("select name as lname, age as number from Customers where Country='Mexico';")
p = t.parse.transpile
puts "SQL Query is: \"#{t.statement}\""
puts "MongoDB equivalent query is: '#{p}'"
