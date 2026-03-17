desc 'post-release tasks run by Heroku'
task release: :environment do
  if ENV['REVIEW_APP'].present?
    puts 'Review app detected — skipping all release tasks (postdeploy handles setup)'
    next
  end

  # Run rails db:migrate
  puts 'Running db:migrate'
  begin
    ActiveRecord::Tasks::DatabaseTasks.migrate
  rescue StandardError => e
    puts "Error during db:migrate: #{e.message}. Rethrowing exception to cancel release."
    raise e # Re-raise the error because we want the release to fail
  end

  puts 'Ensuring Solid Queue tables exist'
  begin
    Rake::Task['solid_queue:bootstrap'].invoke
  rescue StandardError => e
    puts "Error during solid_queue:bootstrap: #{e.message}. Rethrowing exception to cancel release."
    raise e
  end

  # Run rails db:seed
  puts 'Running db:seed'
  begin
    ActiveRecord::Tasks::DatabaseTasks.load_seed
  rescue StandardError => e
    puts "Error during db:seed: #{e.message}. Rethrowing exception to cancel release."
    raise e # Re-raise the error because we want the release to fail
  end

  # Notify Sentry of the deploy
  release_version = ENV['HEROKU_RELEASE_VERSION']
  release = release_version || `git log -1 --format="%h %s"`.strip

  if defined?(Sentry)
    puts "Notifying Sentry of release and deploy: #{release}"

    begin
      Sentry.sdk_create_deploy(
        release: release,
        environment: Rails.env,
        url: release_version ? "https://dashboard.heroku.com/apps/#{ENV['HEROKU_APP_NAME']}/activity/releases/#{release_version}" : nil
      )
    rescue StandardError => e
      puts "Error notifying Sentry of release/deploy: #{e.message}"
    end
  end
end
