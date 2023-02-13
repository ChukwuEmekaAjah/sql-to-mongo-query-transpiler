require "minitest/autorun"
require_relative "../lib/sql_to_mongo"

class SQLToMongo::TranspilerTest < Minitest::Test

    def test_transpile_returns_mongodb_aggregate_query
        sql_query = 'select name, avg(age) as average_age from friends group by id;'
        expected_mongodb_query = 'db.friends.aggregate([{"$match":{}},{"$project":{"name":1,"average_age":{"$avg":["$age"]}}},{"$group":{"_id":{"id":"$id"}}}])'
        mongodb_query = SQLToMongo::Transpiler.new(sql_query).parse.transpile
        assert expected_mongodb_query == mongodb_query
    end

    def test_transpile_returns_mongodb_aggregate_query_with_condition
        sql_query = 'select name, avg(age) as average_age from friends where age >= 10 && friends_count < 5 group by id;'
        expected_mongodb_query = 'db.friends.aggregate([{"$match":{"$and":[{"age":{"$gte":10.0}},{"friends_count":{"$lt":5.0}}]}},{"$project":{"name":1,"average_age":{"$avg":["$age"]}}},{"$group":{"_id":{"id":"$id"}}}])'
        mongodb_query = SQLToMongo::Transpiler.new(sql_query).parse.transpile
        assert expected_mongodb_query == mongodb_query
    end

    def test_transpile_returns_mongodb_aggregate_query_with_having_condition
        sql_query = 'select name, avg(age) as average_age from friends where age >= 10 && friends_count < 5 group by id having average_age >= 24;'
        expected_mongodb_query = 'db.friends.aggregate([{"$match":{"$and":[{"age":{"$gte":10.0}},{"friends_count":{"$lt":5.0}}]}},{"$project":{"name":1,"average_age":{"$avg":["$age"]}}},{"$group":{"_id":{"id":"$id"}}},{"$match":{"average_age":{"$gte":24.0}}}])'
        mongodb_query = SQLToMongo::Transpiler.new(sql_query).parse.transpile
        assert expected_mongodb_query == mongodb_query
    end
    
end