require "sidekiq/deploy"

desc "post-release tasks run by Heroku"
task release: :environment do
  # Run rails db:migrate
  puts "Running db:migrate"
  begin
    ActiveRecord::Tasks::DatabaseTasks.migrate
  rescue => e
    puts "Error during db:migrate: #{e.message}. Rethrowing exception to cancel release."
    raise e  # Re-raise the error because we want the release to fail
  end

  if ShopConfig.uses_sidekiq?
    gitdesc = ENV['HEROKU_RELEASE_VERSION'] || `git log -1 --format="%h %s"`.strip
    puts "Running Sidekiq::Deploy.mark! #{gitdesc}"

    begin
      Sidekiq::Deploy.mark!(gitdesc)
    rescue => e
      puts "Error during Sidekiq::Deploy.mark!: #{e.message}"
    end
  end
end
