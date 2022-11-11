Gem::Specification.new do |s|
    s.name        = "sql_to_mongo"
    s.version     = "1.0.0"
    s.summary     = "SQL query to MongoDB query transpiler."
    s.description = "A transpiler that converts MySQL data manipulation queries (select, update, insert and delete) into their equivalent MongoDB queries."
    s.authors     = ["Chukwuemeka Ajah"]
    s.email       = "talk2ajah@gmail.com"
    s.files       = Dir.glob(["lib/**/*.rb", "*.md", "bin/*"])
    s.homepage    = "https://github.com/ChukwuEmekaAjah/sql-to-mongo-query-transpiler"
    s.license     = "MIT"
    s.executables = []
end