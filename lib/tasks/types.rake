namespace :types do
  desc "Generate TypeScript API types from test/schemas JSON schemas"
  task :generate do
    unless system("bin/generate_schema_types")
      abort("Failed to generate schema types")
    end
  end
end
