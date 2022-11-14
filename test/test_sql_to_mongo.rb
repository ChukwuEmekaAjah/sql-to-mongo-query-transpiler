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

    def test_transpile_returns_aggregate_query_for_renamed_sql_columns
        sql_query = 'select name as fname, age from Customers where Country=\'Mexico\';'
        expected_mongodb_query = 'db.Customers.aggregate([{"$match":{"Country":"Mexico"}},{"$project":{"fname":"$name","age":1}}])'
        mongodb_query = SQLToMongo::Transpiler.new(sql_query).parse.transpile
        assert expected_mongodb_query == mongodb_query
    end
end