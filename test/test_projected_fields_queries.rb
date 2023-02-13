require "minitest/autorun"
require_relative "../lib/sql_to_mongo"

class SQLToMongo::TranspilerTest < Minitest::Test

    def test_transpile_returns_mongodb_projected_field_query
        sql_query = 'select lname + fname as full_name, friends_counts as number_of_friends from friends;'
        expected_mongodb_query = 'db.friends.aggregate([{"$match":{}},{"$project":{"full_name":{"$sum":["$lname","$fname"]},"number_of_friends":"friends_counts"}}])'
        mongodb_query = SQLToMongo::Transpiler.new(sql_query).parse.transpile
        assert expected_mongodb_query == mongodb_query
    end

    def test_transpile_returns_mongodb_aggregate_query_with_condition
        sql_query = 'select name, age * 3 as age_multiple from friends;'
        expected_mongodb_query = 'db.friends.aggregate([{"$match":{}},{"$project":{"name":1,"age_multiple":{"$multiply":["$age",3.0]}}}])'
        mongodb_query = SQLToMongo::Transpiler.new(sql_query).parse.transpile
        assert expected_mongodb_query == mongodb_query
    end

    def test_transpile_returns_mongodb_aggregate_query_with_having_condition
        sql_query = 'select age + 3 as next_three_years from friends where name like "ajah" ;'
        expected_mongodb_query = 'db.friends.aggregate([{"$match":{"name":{"$regex":"ajah"}}},{"$project":{"next_three_years":{"$sum":["$age",3.0]}}}])'
        mongodb_query = SQLToMongo::Transpiler.new(sql_query).parse.transpile
        assert expected_mongodb_query == mongodb_query
    end
    
end