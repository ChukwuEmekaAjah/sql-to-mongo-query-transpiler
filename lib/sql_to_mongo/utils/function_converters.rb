module SQLToMongo
    module Utils
        module FunctionConverters
            extend self

            def between(arguments, column_name)
                return {column_name => {'$gte' => arguments['$and'][0], '$lte': arguments['$and'][1]}}
            end

            def is(arguments, column_name)
                return {column_name => {'$eq': arguments}}
            end

            def in(arguments, column_name)
                return {column_name => {'$in' => arguments}}
            end

            def like(arguments, column_name)
                return {column_name => {'$regex' => arguments}}
            end

            def avg(arguments, column_name)
                return {'$avg' => arguments.map {|arg| "$#{arg}" } }
            end
        end
    end
end