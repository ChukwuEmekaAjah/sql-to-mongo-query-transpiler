# Hermes
A transpiler that converts an SQL query to an equivalent MongoDB query.
It boasts of a token scanner, parser and interpreter that churns out the equivalent MongoDB query for every SQL data manipulation query passed into it.
Bearing in mind that MongoDB is schemaless, some of the shorthand queries of SQL will not work.

## Examples

```ruby
t = Transpiler.new("drop database db1;").transpile
Transpiler.new("create database db1;").transpile
p = Transpiler.new("delete from 'table' where age = 30 or 2 > 2;").transpile
p = Transpiler.new("update Customers set ContactName='Juan', age=23 where Country='Mexico';").transpile
p = Transpiler.new("insert into table_name (column1, column2, column3) values ('value1', 'value2', 'value3');").transpile
p2 = Transpiler.new("insert into table_name values ('value1', 'value2', 'value3');").transpile
p = Transpiler.new("select * from Customers where Country='Mexico';").transpile
p2 = Transpiler.new("select name, age from Customers where Country='Mexico';").transpile
p2 = Transpiler.new("explain select name, age from Customers where Country='Mexico';").transpile
t = Transpiler.new("select name as lname, age from Customers where Country='Mexico';")

puts p2.print
puts p.print

t = Transpiler.new("select name as lname, age as number from users where name>='Ajah' and age > 29 and age < 30000003;")
p = t.parse.transpile
puts "SQL Query is: \"#{t.statement}\""
puts "MongoDB equivalent query is: '#{p}'"
```