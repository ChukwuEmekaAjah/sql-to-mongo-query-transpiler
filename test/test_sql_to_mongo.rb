require "minitest/autorun"
require_relative "../lib/sql_to_mongo"

class SQLToMongo::TranspilerTest < Minitest::Test
    def test_transpile_returns_simple_mongodb_query
        sql_query = 'select * from friends;'
        expected_mongodb_query = 'db.friends.find({}, {})'
        mongodb_query = SQLToMongo::Transpiler.new(sql_query).parse.transpile
        assert expected_mongodb_query == mongodb_query
    end

    def test_transpile_returns_mongodb_query_with_selected_fields
        sql_query = 'select name, age from friends;'
        expected_mongodb_query = 'db.friends.find({}, {"name":1,"age":1})'
        mongodb_query = SQLToMongo::Transpiler.new(sql_query).parse.transpile
        assert expected_mongodb_query == mongodb_query
    end

    def test_transpile_returns_mongodb_query_with_selected_fields_and_conditions
        sql_query = 'select name, age from friends where age >= 20 and age <= 30;'
        expected_mongodb_query = 'db.friends.find({"$and":[{"age":{"$gte":20.0}},{"age":{"$lte":30.0}}]}, {"name":1,"age":1})'
        mongodb_query = SQLToMongo::Transpiler.new(sql_query).parse.transpile
        assert expected_mongodb_query == mongodb_query
    end

    def test_transpile_returns_mongodb_query_explain_expression
        sql_query = 'explain select name, age from Customers where Country=\'Mexico\';'
        expected_mongodb_query = 'db.Customers.find({"Country":"Mexico"}, {"name":1,"age":1}).explain()'
        mongodb_query = SQLToMongo::Transpiler.new(sql_query).parse.transpile
        assert expected_mongodb_query == mongodb_query
    end

    def test_transpile_returns_mongodb_query_delete_expression
        sql_query = "delete from 'table' where age = 30 or friends > 2;"
        expected_mongodb_query = 'db.table.deleteMany({"$or":[{"age":30.0},{"friends":{"$gt":2.0}}]})'
        mongodb_query = SQLToMongo::Transpiler.new(sql_query).parse.transpile
        assert expected_mongodb_query == mongodb_query
    end

    def test_transpile_returns_mongodb_query_update_expression
        sql_query = "update Customers set ContactName='Juan', age=23;"
        expected_mongodb_query = 'db.Customers.updateMany({}, {"ContactName":"Juan","age":23.0})'
        mongodb_query = SQLToMongo::Transpiler.new(sql_query).parse.transpile
        assert expected_mongodb_query == mongodb_query
    end

    def test_transpile_returns_mongodb_query_update_expression_with_condition
        sql_query = "update Customers set ContactName='Juan', age=23 where Country='Mexico';"
        expected_mongodb_query = 'db.Customers.updateMany({"Country":"Mexico"}, {"ContactName":"Juan","age":23.0})'
        mongodb_query = SQLToMongo::Transpiler.new(sql_query).parse.transpile
        assert expected_mongodb_query == mongodb_query
    end

    def test_transpile_returns_mongodb_query_insert_expression
        sql_query = "insert into table_name (column1, column2, column3) values ('value1', 'value2', 'value3');"
        expected_mongodb_query = 'db.table_name.insertOne({"column1":"value1","column2":"value2","column3":"value3"})'
        mongodb_query = SQLToMongo::Transpiler.new(sql_query).parse.transpile
        assert expected_mongodb_query == mongodb_query
    end
end