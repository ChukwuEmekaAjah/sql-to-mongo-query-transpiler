# Hermes
A transpiler that converts an SQL query to an equivalent MongoDB query.
It boasts of a token scanner, parser and interpreter that churns out the equivalent MongoDB query for every SQL data manipulation query passed into it.
Bearing in mind that MongoDB is schemaless, some of the shorthand queries of SQL will not work.