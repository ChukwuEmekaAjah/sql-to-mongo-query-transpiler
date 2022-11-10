# SQLToMongo
A transpiler that converts an SQL query to an equivalent MongoDB query.
It boasts of a token scanner, parser and interpreter that churns out the equivalent MongoDB query for every SQL data manipulation query passed into it.
Bearing in mind that MongoDB is schemaless, some of the shorthand queries of SQL will not work.

# Installation
To install the package, just run:
`gem install sql_to_mongo`

If you intend to build it from source after cloning this repository, run:
`gem build sql_to_mongo.gemspec`

## Requirements
- Ruby 2.3+

## Bundler
To securely install the package using bundler, we encourage that you use the https rubygems source in your Gemfile so as to make sure that the installed packaged isn't compromised by any means.

```ruby
source 'https://rubygems.org'

gem sql_to_mongo
```
## Examples

```ruby
delete_query = SQLToMongo::Transpiler.new("delete from 'table' where age = 30 or friends > 2;").parse.transpile

cond_update = SQLToMongo::Transpiler.new("update Customers set ContactName='Juan', age=23 where Country='Mexico';").parse.transpile

insert = SQLToMongo::Transpiler.new("insert into table_name (column1, column2, column3) values ('value1', 'value2', 'value3');").parse
    .transpile

# raises an error because MongoDB is schemaless and won't understand an insert without column names
wrong_insert = SQLToMongo::Transpiler.new("insert into table_name values ('value1', 'value2', 'value3');").parse.transpile

cond_select = SQLToMongo::Transpiler.new("select * from Customers where Country='Mexico';").parse.transpile

alias_select = SQLToMongo::Transpiler.new("select name, age as number from Customers where Country='Mexico';").parse.transpile

basic_select = SQLToMongo::Transpiler.new("select name, age from Customers;").parse.transpile

explain_stm = SQLToMongo::Transpiler.new("explain select name, age from Customers where Country='Mexico';").parse.transpile

# SQL query with function operators
complex = SQLToMongo::Transpiler.new("select name, age as number from users where (age in (23, 43)) or (firstname between 2 and 3) ;")
result = complex.parse.transpile
puts "SQL Query is: \"#{complex.statement}\""
puts "MongoDB equivalent query is: '#{result}'"

# Filter query with text matching
t = SQLToMongo::Transpiler.new("select name, age as number from users where firstname in ('cute', 'ajah') and lname like 'put.*' ;")
p = t.parse.transpile
puts "SQL Query is: \"#{t.statement}\""
puts "MongoDB equivalent query is: '#{p}'"
```

# TODO
- Support use of SQL dialects
- Support more SQL functions
- Integrate code for aggregator commands like `group by, count, order by, etc`
- Support Data Definition Language (DDL) queries

## Quirks
- This parser doesn't yet understand SQL-like regular expressions. You are encouraged to put the equivalent JavaScript/MongoDB regular expression string in your statement and it will function normally.
For example:
Actual SQL Query: `select name, age as number from users where firstname in ('cute', 'ajah') and lname like 'name%' ;`
Write the following query:  `select name, age as number from users where firstname in ('cute', 'ajah') and lname like '^name.*' ;`
- The parser can be confused if brackets are not provided to segment parts of where conditions. Grouping `where` expressions will help with ensuring correct results at all times.