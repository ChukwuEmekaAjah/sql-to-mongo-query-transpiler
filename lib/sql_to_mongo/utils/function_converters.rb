module SQLToMongo
    module Utils
        module FunctionConverters
            extend self

            def between(arguments)
                return {'$gte' => arguments['$and'][0], '$lte': arguments['$and'][1]}
            end

            def is(arguments)
                return {'$eq': arguments}
            end

            def in(arguments)
                return {'$in' => arguments}
            end

            def like(arguments)
                return {'$regex' => arguments}
            end
        end
    end
end