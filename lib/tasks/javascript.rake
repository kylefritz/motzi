namespace :javascript do
  desc "Build JavaScript bundles with Bun"
  task :build do
    unless system("bun run build")
      abort("JavaScript build failed")
    end
  end
end

if Rake::Task.task_defined?("assets:precompile")
  Rake::Task["assets:precompile"].enhance(["javascript:build"])
end
