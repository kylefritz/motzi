require "sidekiq/deploy"

desc "post-release tasks run by Heroku"
task release: :environment do
  # run rails db:migrate
  ActiveRecord::Tasks::DatabaseTasks.migrate

  # notify sidekiq of new release
  gitdesc = `git log -1 --format="%h %s"`.strip
  Sidekiq::Deploy.mark!(gitdesc)
end
