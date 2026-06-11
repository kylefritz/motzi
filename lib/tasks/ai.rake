namespace :ai do
  task :quiet => :environment do
    ActiveRecord::Base.logger = nil
  end

  def expectations_path
    Rails.root.join("test/anomaly_expectations.yml")
  end

  def eval_results_dir
    Rails.root.join("tmp/ai_eval")
  end

  desc "Show activity feed prompt for a week (default: current week). Usage: rake ai:activity_feed_prompt[26w11]"
  task :activity_feed_prompt, [:week_id] => :quiet do |_t, args|
    week_id = args[:week_id] || Time.zone.now.week_id
    feed = ActivityFeed.new(week_id)
    puts feed.to_text(verbose: false)
  end

  desc "Show historical analyses and menu data. Usage: rake ai:history"
  task :history => :quiet do
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
  task :analysis, [:week_id] => :quiet do |_t, args|
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
  task :activity_feed_verbose, [:week_id] => :quiet do |_t, args|
    week_id = args[:week_id] || Time.zone.now.week_id
    feed = ActivityFeed.new(week_id)
    puts feed.to_text(verbose: true)
  end

  desc "Show the full prompt that would be sent to Claude. Usage: rake ai:full_prompt[26w11]"
  task :full_prompt, [:week_id] => :quiet do |_t, args|
    week_id = args[:week_id] || Time.zone.now.week_id
    detector = AnomalyDetector.new(week_id) { |msg| $stderr.puts msg }
    puts "=== SYSTEM PROMPT ==="
    puts detector.system_prompt
    puts
    puts "=== USER MESSAGE ==="
    puts detector.build_user_message
  end

  desc "Evaluate anomaly detector against historical weeks. Usage: rake ai:eval or rake ai:eval[26w05]. EVAL_THREADS=3 to change parallelism."
  task :eval, [:week_id] => :quiet do |_t, args|
    expectations = YAML.load_file(expectations_path)
    FileUtils.mkdir_p(eval_results_dir)

    weeks = if args[:week_id]
      { args[:week_id] => expectations[args[:week_id]] }.tap do |h|
        abort "No expectation defined for #{args[:week_id]}" unless h.values.first
      end
    else
      expectations
    end

    thread_count = (ENV["EVAL_THREADS"] || 3).to_i.clamp(1, 6)
    puts "Evaluating #{weeks.size} weeks with #{thread_count} threads (model: #{AnomalyDetector.model}, judge: #{AnomalyReportGrader.judge_model})..."

    queue = Queue.new
    weeks.each_with_index { |(week_id, expectation), i| queue << [week_id, expectation, i] }
    mutex = Mutex.new
    results = []
    done = 0

    workers = thread_count.times.map do
      Thread.new do
        loop do
          week_id, expectation, _i = begin
            queue.pop(true)
          rescue ThreadError
            break
          end

          row = ActiveRecord::Base.connection_pool.with_connection do
            evaluate_week(week_id, expectation)
          end
          mutex.synchronize do
            results << row
            done += 1
            print_week_result(row, done, weeks.size)
          end
        end
      end
    end
    workers.each(&:join)

    results.sort_by! { |r| r[:week_id] }
    total_cost = results.sum { |r| r[:cost].to_f }

    timestamp = Time.zone.now.strftime("%Y%m%d_%H%M%S")
    results_file = eval_results_dir.join("eval_#{timestamp}.yml")
    File.write(results_file, results.to_yaml)

    print_scorecard(results, total_cost, results_file)
  end

  # Run the detector on one labeled week and grade the output.
  # The prompt only sees analyses that existed by the end of that week, so
  # historical evals can't leak reports from the future.
  def evaluate_week(week_id, expectation)
    expected = expectation["expected_status"]
    must_flag = expectation["must_flag"] || []
    must_not_flag = expectation["must_not_flag"] || []
    week_end = Time.zone.from_week_id(week_id) + 7.days

    detector = AnomalyDetector.new(week_id, analyses_before: week_end)
    result = detector.run_analysis
    grade = AnomalyReportGrader.new(result[:text], must_flag: must_flag, must_not_flag: must_not_flag).grade

    status_ok = grade[:status] == expected
    {
      week_id: week_id,
      expected: expected,
      actual: grade[:status],
      status_ok: status_ok,
      misses: grade[:misses],
      violations: grade[:violations],
      must_flag_detail: grade[:must_flag],
      must_not_flag_detail: grade[:must_not_flag],
      passed: status_ok && grade[:misses].empty? && grade[:violations].empty?,
      cost: result[:cost],
      notes: expectation["notes"],
      tldr: result[:text].lines.first&.strip,
      full_result: result[:text],
      input_tokens: result[:input_tokens],
      output_tokens: result[:output_tokens]
    }
  rescue StandardError => e
    {
      week_id: week_id, expected: expected, actual: "ERROR", status_ok: false,
      misses: must_flag, violations: [], must_flag_detail: [], must_not_flag_detail: [],
      passed: false, cost: 0.0, notes: expectation["notes"],
      tldr: "ERROR: #{e.class}: #{e.message}", full_result: "#{e.class}: #{e.message}\n#{e.backtrace.first(5).join("\n")}",
      input_tokens: 0, output_tokens: 0
    }
  end

  def print_week_result(row, done, total)
    icon = row[:passed] ? "PASS" : "FAIL"
    puts "[#{done}/#{total}] #{icon}  #{row[:week_id]}  status: #{row[:actual]} (expected #{row[:expected]})  $#{'%.4f' % row[:cost]}"
    row[:misses].each { |m| puts "         MISSED: #{m}" }
    row[:violations].each { |v| puts "         FALSE ALARM: #{v}" }
  end

  desc "Dry run: show prompts that would be sent without calling Claude. Usage: rake ai:eval_dry or rake ai:eval_dry[26w05]"
  task :eval_dry, [:week_id] => :quiet do |_t, args|
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
  task :eval_report => :quiet do
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
        Array(r[:misses]).each { |m| puts "MISSED: #{m}" }
        Array(r[:violations]).each do |v|
          detail = Array(r[:must_not_flag_detail]).find { |d| d[:item] == v }
          puts "FALSE ALARM: #{v}"
          puts "  evidence: #{detail[:evidence]}" if detail && detail[:evidence].present?
        end
        puts r[:full_result]
      end
    end
  end

  desc "Show weekly metrics for a year. Usage: rake ai:metrics[25] or rake ai:metrics[24]"
  task :metrics, [:year] => :quiet do |_t, args|
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
    status_ok = results.count { |r| r[:status_ok] }
    total_required = results.sum { |r| Array(r[:must_flag_detail]).size }
    total_found = results.sum { |r| Array(r[:must_flag_detail]).count { |d| d[:found] } }
    total_misses = results.sum { |r| Array(r[:misses]).size }
    total_violations = results.sum { |r| Array(r[:violations]).size }
    weeks_with_forbidden = results.count { |r| Array(r[:must_not_flag_detail]).any? }

    puts "\n#{'=' * 72}"
    puts "SCORECARD"
    puts "=" * 72
    results.each do |r|
      icon = r[:passed] ? "PASS" : "FAIL"
      finding_note = []
      finding_note << "#{Array(r[:misses]).size} missed" if Array(r[:misses]).any?
      finding_note << "#{Array(r[:violations]).size} false alarm#{'s' if Array(r[:violations]).size != 1}" if Array(r[:violations]).any?
      suffix = finding_note.any? ? "  [#{finding_note.join(', ')}]" : ""
      puts "  #{icon}  #{r[:week_id]}  expected=#{r[:expected].to_s.ljust(8)}  got=#{r[:actual].to_s.ljust(8)}  $#{'%.4f' % r[:cost]}#{suffix}"
    end
    puts "-" * 72
    puts "  Weeks fully passed:   #{passed}/#{results.size}"
    puts "  Status accuracy:      #{status_ok}/#{results.size}"
    puts "  Required findings:    #{total_found}/#{total_required} caught (#{total_misses} missed)" if total_required.positive?
    puts "  Noise violations:     #{total_violations} false alarm#{'s' if total_violations != 1} across #{weeks_with_forbidden} weeks with forbidden checks"
    puts "  Total cost:           $#{'%.4f' % total_cost}"
    puts "  Results saved to:     #{results_file}"
    puts "=" * 72
  end
end
