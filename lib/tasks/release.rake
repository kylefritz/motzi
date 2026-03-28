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
end
