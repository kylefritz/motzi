namespace :ai do
  task quiet: :environment do
    ActiveRecord::Base.logger = nil
  end

  def expectations_path
    Rails.root.join("test/anomaly_expectations.yml")
  end

  def eval_results_dir
    Rails.root.join("tmp/ai_eval")
  end

  desc "Show activity feed prompt for a week (default: current week). Usage: rake ai:activity_feed_prompt[26w11]"
  task :activity_feed_prompt, [ :week_id ] => :quiet do |_t, args|
    week_id = args[:week_id] || Time.zone.now.week_id
    feed = ActivityFeed.new(week_id)
    puts feed.to_text(verbose: false)
  end

  desc "Show historical analyses and menu data. Usage: rake ai:history"
  task history: :quiet do
    puts "=== Existing Analyses ==="
    AnomalyAnalysis.order(:created_at).each do |a|
      puts "#{a.week_id} | #{a.overall_status.to_s.ljust(8)} | #{a.trigger.ljust(9)} | #{a.created_at.strftime('%m/%d %H:%M')} | #{a.result.lines.first&.strip&.truncate(80)}"
    end

    puts ""
    puts "=== All Menus ==="
    Menu.order(:week_id).each do |m|
      order_count = m.orders.count
      item_count = OrderItem.joins(:order).where(orders: { menu_id: m.id }).count
      puts "#{m.week_id} | #{m.menu_type.to_s.ljust(8)} | #{m.name.to_s.ljust(35)} | #{order_count} orders | #{item_count} items"
    end
  end

  desc "Show full analysis result for a week. Usage: rake ai:analysis[26w11]"
  task :analysis, [ :week_id ] => :quiet do |_t, args|
    week_id = args[:week_id] || Time.zone.now.week_id
    analyses = AnomalyAnalysis.for_week(week_id).order(:created_at)

    if analyses.empty?
      puts "No analyses found for #{week_id}"
      next
    end

    analyses.each do |a|
      puts "=" * 60
      puts "Week: #{a.week_id} | Status: #{a.overall_status} | Trigger: #{a.trigger}"
      puts "Date: #{a.created_at.strftime('%Y-%m-%d %H:%M')} | Model: #{a.api_model || a.model_used}"
      puts "Tokens: #{a.input_tokens} in / #{a.output_tokens} out | Cost: $#{'%.4f' % a.cost}"
      puts "-" * 60
      puts a.result
      puts
    end
  end

  desc "Show verbose activity feed for a week. Usage: rake ai:activity_feed_verbose[26w11]"
  task :activity_feed_verbose, [ :week_id ] => :quiet do |_t, args|
    week_id = args[:week_id] || Time.zone.now.week_id
    feed = ActivityFeed.new(week_id)
    puts feed.to_text(verbose: true)
  end

  desc "Show the full prompt that would be sent to Claude. Usage: rake ai:full_prompt[26w11]"
  task :full_prompt, [ :week_id ] => :quiet do |_t, args|
    week_id = args[:week_id] || Time.zone.now.week_id
    detector = AnomalyDetector.new(week_id) { |msg| $stderr.puts msg }
    puts "=== SYSTEM PROMPT ==="
    puts detector.system_prompt
    puts
    puts "=== USER MESSAGE ==="
    puts detector.build_user_message
  end

  desc "Evaluate anomaly detector against historical weeks. Usage: rake ai:eval or rake ai:eval[26w05]"
  task :eval, [ :week_id ] => :quiet do |_t, args|
    expectations = YAML.load_file(expectations_path)
    FileUtils.mkdir_p(eval_results_dir)

    weeks = if args[:week_id]
      { args[:week_id] => expectations[args[:week_id]] }.tap do |h|
        abort "No expectation defined for #{args[:week_id]}" unless h.values.first
      end
    else
      expectations
    end

    results = []
    total_cost = 0.0

    weeks.each_with_index do |(week_id, expectation), i|
      expected = expectation["expected_status"]
      notes = expectation["notes"]

      puts "\n[#{i + 1}/#{weeks.size}] Evaluating #{week_id} (expected: #{expected})..."
      puts "  Notes: #{notes}"

      detector = AnomalyDetector.new(week_id) { |msg| puts "  #{msg}" }
      result = detector.run_analysis

      # Parse status from result text (same logic as AnomalyAnalysis model)
      status_line = result[:text][/(?:overall )?status:.*$/i]
      actual_status = if status_line
        case status_line.downcase
        when /problem|🔴/ then "problem"
        when /warning|⚠️/ then "warning"
        when /healthy|✅/ then "healthy"
        else "warning"
        end
      else
        "warning"
      end

      passed = actual_status == expected
      total_cost += result[:cost]

      results << {
        week_id: week_id,
        expected: expected,
        actual: actual_status,
        passed: passed,
        cost: result[:cost],
        tldr: result[:text].lines.first&.strip,
        full_result: result[:text],
        input_tokens: result[:input_tokens],
        output_tokens: result[:output_tokens]
      }

      icon = passed ? "PASS" : "FAIL"
      puts "  => #{icon}: got #{actual_status} (expected #{expected}) — $#{'%.4f' % result[:cost]}"
      puts "  TL;DR: #{result[:text].lines.first&.strip&.truncate(100)}"
    end

    # Save results
    timestamp = Time.zone.now.strftime("%Y%m%d_%H%M%S")
    results_file = eval_results_dir.join("eval_#{timestamp}.yml")
    File.write(results_file, results.to_yaml)

    # Print scorecard
    print_scorecard(results, total_cost, results_file)
  end

  desc "Dry run: show prompts that would be sent without calling Claude. Usage: rake ai:eval_dry or rake ai:eval_dry[26w05]"
  task :eval_dry, [ :week_id ] => :quiet do |_t, args|
    expectations = YAML.load_file(expectations_path)

    weeks = if args[:week_id]
      { args[:week_id] => expectations[args[:week_id]] }.tap do |h|
        abort "No expectation defined for #{args[:week_id]}" unless h.values.first
      end
    else
      expectations
    end

    weeks.each do |week_id, expectation|
      puts "=" * 60
      puts "Week: #{week_id} | Expected: #{expectation['expected_status']}"
      puts "Notes: #{expectation['notes']}"
      puts "-" * 60

      detector = AnomalyDetector.new(week_id) { |_| }
      prompt = detector.build_user_message
      puts "Prompt length: #{prompt.length} chars"
      puts "First 500 chars:"
      puts prompt[0..500]
      puts "..."
      puts
    end
  end

  desc "Show results from most recent eval run. Usage: rake ai:eval_report"
  task eval_report: :quiet do
    files = Dir.glob(eval_results_dir.join("eval_*.yml")).sort
    if files.empty?
      puts "No eval results found. Run `rake ai:eval` first."
      next
    end

    results_file = files.last
    results = YAML.load_file(results_file)
    total_cost = results.sum { |r| r[:cost] }

    print_scorecard(results, total_cost, results_file)

    # Show full results for failures
    failures = results.select { |r| !r[:passed] }
    if failures.any?
      puts "\n#{'=' * 60}"
      puts "FAILURE DETAILS"
      puts "=" * 60
      failures.each do |r|
        puts "\n--- #{r[:week_id]} (expected: #{r[:expected]}, got: #{r[:actual]}) ---"
        puts r[:full_result]
      end
    end
  end

  desc "Show weekly metrics for a year. Usage: rake ai:metrics[25] or rake ai:metrics[24]"
  task :metrics, [ :year ] => :quiet do |_t, args|
    year_prefix = args[:year] || "25"
    puts "week_id | menu_name                                      | orders | items | emails | opened | visitors | notes"
    puts "--------|------------------------------------------------|--------|-------|--------|--------|----------|------"

    Menu.where("week_id LIKE ?", "#{year_prefix}w%").where(menu_type: "regular").order(:week_id).each do |m|
      ws = Time.zone.from_week_id(m.week_id)
      we = ws + 7.days
      order_count = m.orders.count
      item_count = OrderItem.joins(:order).where(orders: { menu_id: m.id }).count
      email_count = Ahoy::Message.where(menu_id: m.id).count
      opened_count = Ahoy::Message.where(menu_id: m.id).where.not(opened_at: nil).count
      visitor_count = Ahoy::Visit.where(started_at: ws..we).distinct.count(:visitor_token)

      notes = []
      notes << "CLOSED" if m.name =~ /closed/i
      notes << "HOLIDAY" if m.name =~ /holiday|thanksgiving|challah|yom kippur|purim|hamantaschen|passover/i
      notes << "SPECIAL" if m.name =~ /special|valentine|vday/i
      notes << "REDUCED" if m.name =~ /wednesday|closed.*thurs|closed.*sat|no thursday/i

      puts "#{m.week_id} | #{m.name.to_s.truncate(46).ljust(46)} | #{order_count.to_s.rjust(6)} | #{item_count.to_s.rjust(5)} | #{email_count.to_s.rjust(6)} | #{opened_count.to_s.rjust(6)} | #{visitor_count.to_s.rjust(8)} | #{notes.join(', ')}"
    end
  end

  def print_scorecard(results, total_cost, results_file)
    passed = results.count { |r| r[:passed] }
    failed = results.count { |r| !r[:passed] }

    puts "\n#{'=' * 60}"
    puts "SCORECARD"
    puts "=" * 60
    results.each do |r|
      icon = r[:passed] ? "PASS" : "FAIL"
      puts "  #{icon}  #{r[:week_id]}  expected=#{r[:expected].ljust(8)}  got=#{r[:actual].ljust(8)}  $#{'%.4f' % r[:cost]}"
    end
    puts "-" * 60
    puts "  #{passed}/#{results.size} passed, #{failed} failed — total cost: $#{'%.4f' % total_cost}"
    puts "  Results saved to: #{results_file}"
    puts "=" * 60
  end
end
