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

  # Run rails db:seed
  puts "Running db:seed"
  begin
    ActiveRecord::Tasks::DatabaseTasks.load_seed
  rescue => e
    puts "Error during db:seed: #{e.message}. Rethrowing exception to cancel release."
    raise e  # Re-raise the error because we want the release to fail
  end

  # Get release information
  gitdesc = ENV['HEROKU_RELEASE_VERSION'] || `git log -1 --format="%h %s"`.strip

  if defined?(Sentry)
    puts "Notifying Sentry of release and deploy: #{gitdesc}"
    
    begin
      Sentry.configuration.release = sentry_release
      
      Sentry.sdk_create_deploy(
        release: gitdesc,
        environment: Rails.env,
        url: "https://dashboard.heroku.com/apps/#{ENV['HEROKU_APP_NAME']}/activity/releases/#{release_version}"
      )
    rescue => e
      puts "Error notifying Sentry of release/deploy: #{e.message}"
    end
  end

  puts "Running Sidekiq::Deploy.mark! #{gitdesc}"
  begin
    Sidekiq::Deploy.mark!(gitdesc)
  rescue => e
    puts "Error during Sidekiq::Deploy.mark!: #{e.message}"
  end
end
