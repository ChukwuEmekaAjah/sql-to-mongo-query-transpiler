# Hermes
A transpiler that converts an SQL query to an equivalent MongoDB query.
It boasts of a token scanner, parser and interpreter that churns out the equivalent MongoDB query for every SQL data manipulation query passed into it.
Bearing in mind that MongoDB is schemaless, some of the shorthand queries of SQL will not work.

## Examples

```ruby
t = SQLToMongo::Transpiler.new("drop database db1;").transpile
SQLToMongo::Transpiler.new("create database db1;").transpile
p = SQLToMongo::Transpiler.new("delete from 'table' where age = 30 or 2 > 2;").transpile
p = SQLToMongo::Transpiler.new("update Customers set ContactName='Juan', age=23 where Country='Mexico';").transpile
p = SQLToMongo::Transpiler.new("insert into table_name (column1, column2, column3) values ('value1', 'value2', 'value3');").transpile
p2 = SQLToMongo::Transpiler.new("insert into table_name values ('value1', 'value2', 'value3');").transpile
p = SQLToMongo::Transpiler.new("select * from Customers where Country='Mexico';").transpile
p2 = SQLToMongo::Transpiler.new("select name, age from Customers where Country='Mexico';").transpile
p2 = SQLToMongo::Transpiler.new("explain select name, age from Customers where Country='Mexico';").transpile
t = SQLToMongo::Transpiler.new("select name as lname, age from Customers where Country='Mexico';")

puts p2.print
t = SQLToMongo::Transpiler.new("select name, age as number from users where age in (23, 43) or firstname between 2 and 3 ;")
p = t.parse.transpile
puts "SQL Query is: \"#{t.statement}\""
puts "MongoDB equivalent query is: '#{p}'"
puts p.print


# t = SQLToMongo::Transpiler.new("select name, age as number from users where firstname in ('cute', 'ajah') and lname like put ;")
# p = t.parse.transpile
# puts "SQL Query is: \"#{t.statement}\""
# puts "MongoDB equivalent query is: '#{p}'"
```

## Quirks
This parser doesn't yet understand SQL-like regular expressions. You are encouraged to put the equivalent JavaScript/MongoDB regular expression string in your statement and it will function normally.
For example:
Actual SQL Query: `select name, age as number from users where firstname in ('cute', 'ajah') and lname like 'name%' ;`
Write the following query:  `select name, age as number from users where firstname in ('cute', 'ajah') and lname like '^name.*' ;`