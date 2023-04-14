require "sidekiq/deploy"

desc "post-release tasks run by Heroku"
task release: :environment do
  # run rails db:migrate
  print("Running db:migrate")
  ActiveRecord::Tasks::DatabaseTasks.migrate

  if ShopConfig.uses_sidekiq?
    gitdesc = `git log -1 --format="%h %s"`.strip
    print("Running Sidekiq::Deploy.mark! #{gitdesc}")
    Sidekiq::Deploy.mark!(gitdesc)
  end
end
