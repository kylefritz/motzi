require "test_helper"

class ActivityFeedTest < ActiveSupport::TestCase
  include WebMock::API

  setup do
    @week_id = "19w01"
    @menu = menus(:week1)
  end

  teardown do
    WebMock.reset!
  end

  test "summary returns an array of Events" do
    feed = ActivityFeed.new(@week_id)
    result = feed.summary

    assert_kind_of Array, result
    result.each do |event|
      assert_kind_of ActivityFeed::Event, event
      assert_respond_to event, :timestamp
      assert_respond_to event, :category
      assert_respond_to event, :action
      assert_respond_to event, :description
      assert_respond_to event, :details
    end
  end

  test "events are sorted chronologically" do
    travel_to_week_id(@week_id) do
      ActivityEvent.log(action: "late_event", week_id: @week_id, description: "Second event")
      travel -2.hours
      ActivityEvent.log(action: "early_event", week_id: @week_id, description: "First event")
    end

    feed = ActivityFeed.new(@week_id)
    evts = feed.events

    timestamps = evts.map(&:timestamp)
    assert_equal timestamps.sort, timestamps, "Events should be sorted chronologically"
  end

  test "verbose has at least as many events as summary" do
    travel_to_week_id(@week_id) do
      ActivityEvent.log(action: "test", week_id: @week_id, description: "Test event")
    end

    feed = ActivityFeed.new(@week_id)
    summary_count = feed.summary.size
    verbose_count = feed.verbose_events.size

    assert verbose_count >= summary_count,
      "Verbose (#{verbose_count}) should have >= events than summary (#{summary_count})"
  end

  test "email_summary returns hash with mailer stats" do
    travel_to_week_id(@week_id) do
      sent_time = Time.zone.now
      3.times do |i|
        Ahoy::Message.create!(
          mailer: "MenuMailer#weekly_menu_email",
          menu: @menu,
          user: users(:kyle),
          sent_at: sent_time + i.minutes,
          opened_at: i < 2 ? sent_time + (i + 10).minutes : nil,
          clicked_at: i == 0 ? sent_time + 15.minutes : nil
        )
      end
    end

    feed = ActivityFeed.new(@week_id)
    stats = feed.email_summary

    assert_kind_of Hash, stats
    assert stats.key?("MenuMailer#weekly_menu_email")

    mailer_stats = stats["MenuMailer#weekly_menu_email"]
    assert_equal 3, mailer_stats[:sent]
    assert_equal 2, mailer_stats[:opened]
    assert_equal 1, mailer_stats[:clicked]
    assert_equal 67, mailer_stats[:open_rate]
    assert_equal "Weekly menu email", mailer_stats[:label]
  end

  test "to_text returns formatted string" do
    travel_to_week_id(@week_id) do
      ActivityEvent.log(action: "test", week_id: @week_id, description: "Test event happened")
      Ahoy::Message.create!(
        mailer: "MenuMailer#weekly_menu_email",
        menu: @menu,
        user: users(:kyle),
        sent_at: Time.zone.now,
        opened_at: Time.zone.now + 5.minutes
      )
    end

    feed = ActivityFeed.new(@week_id)
    text = feed.to_text

    assert_kind_of String, text
    assert_includes text, "Activity Feed: #{@week_id}"
    assert_includes text, "=" * 40
    assert_includes text, "== Email Health =="
    assert_includes text, "== Events =="
    assert_includes text, "Weekly menu email"
    assert_match(/\d+ events/, text)
  end

  test "empty week returns empty results" do
    feed = ActivityFeed.new("99w52")
    assert_equal [], feed.summary
    assert_equal [], feed.verbose_events
    assert_equal({}, feed.email_summary)

    text = feed.to_text
    assert_includes text, "0 events"
  end

  test "order events appear in summary" do
    feed = ActivityFeed.new(@week_id)
    evts = feed.summary

    order_events = evts.select { |e| e.action == "orders_summary" }
    assert order_events.any?, "Should have order summary events for week with orders"
    assert_match(/\d+ orders placed/, order_events.first.description)
    assert_match(/\d+ items/, order_events.first.description)
    assert order_events.first.details[:item_count].is_a?(Integer), "Should include item_count in details"
  end

  test "verbose order events show individual orders" do
    feed = ActivityFeed.new(@week_id)
    evts = feed.verbose_events

    individual_orders = evts.select { |e| e.action == "order_placed" }
    assert individual_orders.any?, "Verbose should show individual order events"
    individual_orders.each do |e|
      assert_includes e.description, "ordered:"
    end
  end

  test "credit purchase events in summary" do
    week_start = Time.zone.from_week_id(@week_id)
    CreditItem.create!(
      user: users(:kyle),
      quantity: 6,
      stripe_charge_amount: 48, # dollars, as StripeCheckout::Payment stores it
      memo: "test purchase",
      created_at: week_start + 1.hour
    )

    feed = ActivityFeed.new(@week_id)
    evts = feed.summary
    credit_events = evts.select { |e| e.action == "credits_summary" }

    assert credit_events.any?, "Should have credit summary events"
    assert_match(/1 purchases.*6 credits.*\$48\.00/, credit_events.first.description)
    assert_equal week_start.to_date.to_s, credit_events.first.details[:date]
  end

  test "verbose credit events show individual purchases" do
    week_start = Time.zone.from_week_id(@week_id)
    CreditItem.create!(
      user: users(:kyle),
      quantity: 6,
      stripe_charge_amount: 48, # dollars
      memo: "test purchase",
      created_at: week_start + 1.hour
    )

    feed = ActivityFeed.new(@week_id)
    evts = feed.verbose_events
    credit_events = evts.select { |e| e.action == "credit_purchased" }

    assert credit_events.any?, "Verbose should show individual credit purchases"
    assert_includes credit_events.first.description, "Kyle Fritz"
    assert_includes credit_events.first.description, "($48.00)"
  end

  test "visit events show daily breakdown" do
    week_start = Time.zone.from_week_id(@week_id)
    3.times do |i|
      Ahoy::Visit.create!(started_at: week_start + i.days, visitor_token: "visitor_#{i}", visit_token: "visit_#{i}")
    end
    # duplicate visitor on a different day
    Ahoy::Visit.create!(started_at: week_start + 1.day, visitor_token: "visitor_0", visit_token: "visit_dup")

    feed = ActivityFeed.new(@week_id)
    evts = feed.summary.select { |e| e.action == "daily_visits" }

    assert_equal 3, evts.size, "Should have one event per day with visits"
    evts.each do |e|
      assert_match(/\d+ unique visitors/, e.description)
    end

    # Day with 2 visits but both from different visitor_tokens on that date group
    day2 = evts.find { |e| e.details[:date] == (week_start + 1.day).to_date.to_s }
    assert_match(/\d+ unique visitors \(2 visits\)/, day2.description)
  end

  test "same-day email open rates are marked still maturing" do
    week_start = Time.zone.from_week_id(@week_id)
    travel_to week_start + 4.days do
      # mature batch: sent 3 days ago, opens have settled
      2.times do
        Ahoy::Message.create!(mailer: "ReminderMailer#havent_ordered_email", menu: @menu,
          user: users(:kyle), sent_at: week_start + 1.day, opened_at: week_start + 1.day + 2.hours)
      end
      # fresh batch: sent 2 hours ago, opens still trickling in
      2.times do
        Ahoy::Message.create!(mailer: "ReminderMailer#havent_ordered_email", menu: @menu,
          user: users(:kyle), sent_at: 2.hours.ago)
      end

      feed = ActivityFeed.new(@week_id)
      evts = feed.summary.select do |e|
        e.action == "email_summary" && e.details[:mailer] == "ReminderMailer#havent_ordered_email"
      end

      fresh = evts.find { |e| e.details[:date] == Time.zone.today.to_s }
      mature = evts.find { |e| e.details[:date] == (week_start + 1.day).to_date.to_s }

      assert fresh, "Expected a summary event for today's batch"
      assert fresh.details[:maturing], "Fresh batch should be flagged maturing"
      assert_match(/still maturing/, fresh.description)
      refute mature.details[:maturing], "Settled batch should not be flagged maturing"
      refute_match(/still maturing/, mature.description)
    end
  end

  test "visit events bucket by app time zone, not UTC" do
    week_start = Time.zone.from_week_id(@week_id)
    # 9pm ET is already the next day in UTC — must still count toward the ET date
    day = (week_start + 1.day).to_date
    late_evening = Time.zone.local(day.year, day.month, day.day, 21, 0)
    Ahoy::Visit.create!(started_at: late_evening, visitor_token: "night_owl", visit_token: "visit_night")

    feed = ActivityFeed.new(@week_id)
    evts = feed.summary.select { |e| e.action == "daily_visits" }

    assert_equal 1, evts.size
    assert_equal day.to_s, evts.first.details[:date]
  end

  test "in-progress day is marked partial so it isn't read as a full day" do
    week_start = Time.zone.from_week_id(@week_id)
    travel_to week_start + 2.days + 21.hours + 21.minutes do # 9:21pm ET mid-week
      Ahoy::Visit.create!(started_at: 1.hour.ago, visitor_token: "v_today", visit_token: "t_today")
      Ahoy::Visit.create!(started_at: 2.days.ago, visitor_token: "v_past", visit_token: "t_past")

      feed = ActivityFeed.new(@week_id)
      evts = feed.summary.select { |e| e.action == "daily_visits" }

      today_evt = evts.find { |e| e.details[:date] == Time.zone.today.to_s }
      full_evt = evts.find { |e| e.details[:date] == 2.days.ago.to_date.to_s }

      assert today_evt, "Expected a visit event for today"
      assert today_evt.details[:partial], "Today's bucket should be flagged partial"
      assert_match(/partial/, today_evt.description)
      refute full_evt.details[:partial], "Past days should not be flagged partial"
      refute_match(/partial/, full_evt.description)
    end
  end

  test "activity events include metadata in verbose mode" do
    travel_to_week_id(@week_id) do
      ActivityEvent.log(
        action: "menu_published",
        week_id: @week_id,
        description: "Menu published",
        metadata: { menu_id: @menu.id, subscriber_count: 50 }
      )
    end

    feed = ActivityFeed.new(@week_id)

    summary_evts = feed.summary.select { |e| e.action == "menu_published" }
    assert summary_evts.any?
    refute_includes summary_evts.first.description, "menu_id"

    verbose_evts = feed.verbose_events.select { |e| e.action == "menu_published" }
    assert verbose_evts.any?
    assert_includes verbose_evts.first.description, "menu_id"
  end

  test "headline metrics summarize current totals" do
    feed = ActivityFeed.new(@week_id)
    feed.define_singleton_method(:comparison_snapshot) do |lookback: 4|
      {
        label: "through Fri 1/4 so far",
        current: { orders: 12, items: 20, visitors: 80, visits: 95, credit_purchases: 2, credit_credits: 13, emails_sent: 50, emails_opened: 25, email_open_rate: 50, job_runs: 3, anomaly_jobs: 1, incomplete_jobs: 0 },
        previous: Array.new(lookback) { {} },
        average: { orders: 10, items: 18, visitors: 75, visits: 90, credit_purchases: 1, credit_credits: 6, emails_sent: 48, emails_opened: 22, email_open_rate: 46, job_runs: 2, anomaly_jobs: 1, incomplete_jobs: 0 }
      }
    end

    cards = feed.headline_metrics

    assert_equal 4, cards.size
    assert_equal "Orders", cards.first[:label]
    assert_equal 12, cards.first[:value]
    assert_includes cards.first[:delta], "vs avg"
  end

  # Connection failures and timeouts are Faraday errors, not Octokit::Error,
  # so a GitHub blip used to fail the whole nightly analysis.
  test "a GitHub connection failure is reported and the feed goes on without GitHub's commits" do
    ENV["GITHUB_TOKEN"] = "test-token" # test_helper's teardown restores it
    feed = ActivityFeed.new(@week_id)
    feed.define_singleton_method(:local_git_commits) { [] }
    github = stub_request(:get, %r{\Ahttps://api\.github\.com/repos/.+/commits})
      .to_raise(Faraday::ConnectionFailed.new("execution expired"))

    commits = nil
    assert_error_reported(Faraday::ConnectionFailed) { commits = feed.git_commits }

    assert_requested github
    assert_equal [], commits
    assert_kind_of String, feed.to_text
  end

  test "a GitHub timeout is reported and falls back to local history" do
    ENV["GITHUB_TOKEN"] = "test-token"
    feed = ActivityFeed.new(@week_id)
    commit = ActivityFeed::Commit.new(sha: "abcdef123456", short_sha: "abcdef1", summary: "Local commit",
                                      committed_at: Time.zone.parse("2019-01-01 12:00"),
                                      url: "https://example.com/commit", current_week: true)
    feed.define_singleton_method(:local_git_commits) { [ commit ] }
    stub_request(:get, %r{\Ahttps://api\.github\.com/repos/.+/commits}).to_timeout

    commits = nil
    assert_error_reported(Faraday::Error) { commits = feed.git_commits }

    assert_equal [ "Local commit" ], commits.map(&:summary)
  end

  test "git commits falls back to local history" do
    feed = ActivityFeed.new(@week_id)
    feed.define_singleton_method(:github_commits) { [] }
    commit = ActivityFeed::Commit.new(
      sha: "abcdef123456",
      short_sha: "abcdef1",
      summary: "Test commit",
      committed_at: Time.zone.parse("2019-01-01 12:00"),
      url: "https://example.com/commit",
      current_week: true
    )
    feed.define_singleton_method(:local_git_commits) { [ commit ] }

    commits = feed.git_commits

    assert_equal 1, commits.size
    assert_equal "Test commit", commits.first.summary
  end

  test "to_text includes dyno memory section when metrics exist" do
    week_id = Time.zone.now.week_id
    week_start = Time.zone.from_week_id(week_id)
    DynoMetric.create!(recorded_at: week_start + 1.hour, dyno: "web.1", memory_total: 340, memory_rss: 300, memory_swap: 10, memory_quota: 512, r14_count: 0)
    DynoMetric.create!(recorded_at: week_start + 2.hours, dyno: "web.1", memory_total: 504, memory_rss: 480, memory_swap: 20, memory_quota: 512, r14_count: 2)

    feed = ActivityFeed.new(week_id)
    text = feed.to_text

    assert_match(/Dyno Memory/, text)
    assert_match(/web\.1/, text)
    assert_match(/max 504MB/, text)
    assert_match(/web\.1: .* — no R15 kills/, text)
    assert_no_match(/R14/, text, "R14 is routine swap; its running total read as a memory crisis (analyses 7360, 7393, 7426)")
  end

  test "to_text reports R15 dyno kills and leaves R14 out of the log errors too" do
    week_id = Time.zone.now.week_id
    week_start = Time.zone.from_week_id(week_id)
    DynoMetric.create!(
      recorded_at: week_start + 1.hour, dyno: "worker.1", memory_total: 900, memory_quota: 512, r14_count: 40, r15_count: 2,
      errors_summary: "Error R14 (Memory quota exceeded)\nError R15 (Memory quota vastly exceeded)\n" \
                      "ActionController::RoutingError (No route matches [GET] \"/wp-admin\"):\n" \
                      "I, [2026-11-10T02:19:30 #2]  INFO -- : Parameters: {\"error_class\"=>\"Error\"}"
    )

    text = ActivityFeed.new(week_id).to_text

    assert_match(/worker\.1: .* — 2 R15 KILLS \(dyno terminated\)/, text)
    assert_includes text, "Error R15 (Memory quota vastly exceeded)"
    assert_no_match(/R14/, text)
    assert_no_match(/RoutingError|INFO -- :/, text, "scanner 404s and INFO request logs are not app errors")
  end

  # Analysis 5842 read its own in-progress run as a failed job.
  test "the anomaly job writing the report is not counted as incomplete" do
    skip "needs Solid Queue tables" unless defined?(SolidQueue::Job)
    travel_to_week_id(@week_id) do
      travel 2.days
      SolidQueue::Job.create!(class_name: "AnalyzeAnomaliesJob", queue_name: "default", finished_at: 1.day.ago, created_at: 1.day.ago)
      SolidQueue::Job.create!(class_name: "AnalyzeAnomaliesJob", queue_name: "default", created_at: 2.minutes.ago)

      descriptions = ActivityFeed.new(@week_id).summary.select { |e| e.action == "recurring_jobs_summary" }.map(&:description)

      assert_includes descriptions, "Anomaly analysis: 0 runs (plus the run writing this report)"
      assert_empty descriptions.grep(/incomplete/)
    end
  end

  test "a week with no emails says so instead of dropping the Email Health section" do
    text = ActivityFeed.new("99w52").to_text

    assert_includes text, "== Email Health ==\nNo emails recorded for this week's menus."
  end

  # 53 of 57 reports (fall 2026) restated the same old error groups, because
  # the feed printed each one in full every night.
  test "errors already known from earlier weeks get one line; a spike gets full detail again" do
    ErrorEvent.delete_all
    week_id = Time.zone.now.week_id
    week_start = Time.zone.from_week_id(week_id)
    make = lambda do |fingerprint, klass, at, user: nil|
      ErrorEvent.create!(fingerprint: fingerprint, source: "browser", error_class: klass, message: "#{klass} happened",
                         url: "/menu", environment: "production", occurred_at: at, user: user)
    end

    3.times { |i| make.call("fp-known", "KnownError", week_start - (i + 1).weeks) }
    make.call("fp-known", "KnownError", week_start + 1.hour, user: users(:ljf))
    make.call("fp-spike", "SpikeError", week_start - 1.week)
    10.times { |i| make.call("fp-spike", "SpikeError", week_start + (i + 1).hours) }

    text = ActivityFeed.new(week_id).to_text

    assert_match(/Known from earlier weeks, at their usual rate/, text)
    assert_match(/\[browser\] KnownError ×1 this week, 3 in the prior 4 weeks \(1 signed-in member; id \d+\)/, text)
    assert_not_includes text, "msg: KnownError happened", "a known error at its usual rate is not spelled out again"
    assert_match(/SpikeError ×10 \(last .*, 0 signed-in members\) \[SPIKE — 10 this week vs 1 in the prior 4 weeks\]/, text)
    assert_includes text, "msg: SpikeError happened"
  end

  test "to_text omits dyno memory section when no metrics" do
    feed = ActivityFeed.new(@week_id)
    text = feed.to_text

    assert_no_match(/Dyno Memory/, text)
  end

  test "to_text includes Application Errors section when error events exist" do
    ErrorEvent.delete_all # counts events; start without the fixtures
    week_id = Time.zone.now.week_id
    week_start = Time.zone.from_week_id(week_id)

    3.times do |i|
      ErrorEvent.create!(
        fingerprint: "fp-recurring",
        source: "server",
        error_class: "RuntimeError",
        message: "kaboom #{i}",
        backtrace: "/app/services/foo.rb:42:in `bar'\n/gems/rails/foo.rb:1",
        url: "/menu",
        http_method: "GET",
        environment: "production",
        occurred_at: week_start + (i + 1).hours
      )
    end
    ErrorEvent.create!(
      fingerprint: "fp-browser",
      source: "browser",
      error_class: "TypeError",
      message: "Cannot read 'foo' of undefined",
      environment: "production",
      occurred_at: week_start + 4.hours
    )

    text = ActivityFeed.new(week_id).to_text

    assert_match(/Application Errors \(4 events:/, text)
    assert_match(/RuntimeError/, text)
    assert_match(/×3/, text)
    assert_match(/TypeError/, text)
    assert_match(%r{/app/services/foo\.rb}, text)
  end

  test "to_text omits Application Errors section when no error events" do
    feed = ActivityFeed.new(@week_id)
    text = feed.to_text

    assert_no_match(/Application Errors \(\d+ events/, text)
  end

  test "verbose feed does not tag order confirmations hours apart as DUPLICATE" do
    # Simulates an order edit: initial send, then a second confirmation 2 days later.
    travel_to_week_id(@week_id) do
      first_send = Time.zone.now + 2.days
      Ahoy::Message.create!(mailer: "ConfirmationMailer#order_email", menu: @menu, user: users(:kyle), sent_at: first_send)
      Ahoy::Message.create!(mailer: "ConfirmationMailer#order_email", menu: @menu, user: users(:kyle), sent_at: first_send + 2.days)
    end

    text = ActivityFeed.new(@week_id).to_text(verbose: true)
    assert_no_match(/DUPLICATE/, text, "order confirmations across an edit must not be tagged as duplicates")
    assert_match(/received >1 confirmation/, text, "should surface the edit pattern as expected behavior")
  end

  test "verbose feed tags order confirmations sent within 2 minutes as RAPID DUPLICATE" do
    travel_to_week_id(@week_id) do
      first_send = Time.zone.now + 2.days
      Ahoy::Message.create!(mailer: "ConfirmationMailer#order_email", menu: @menu, user: users(:ljf), sent_at: first_send)
      Ahoy::Message.create!(mailer: "ConfirmationMailer#order_email", menu: @menu, user: users(:ljf), sent_at: first_send + 30.seconds)
    end

    text = ActivityFeed.new(@week_id).to_text(verbose: true)
    assert_match(/RAPID DUPLICATE/, text, "sub-minute-gap confirmations are the real bug signal")
  end

  test "verbose feed does not tag admin self-test pairs as RAPID DUPLICATE" do
    travel_to_week_id(@week_id) do
      first_send = Time.zone.now + 2.days
      Ahoy::Message.create!(mailer: "ConfirmationMailer#order_email", menu: @menu, user: users(:kyle), sent_at: first_send)
      Ahoy::Message.create!(mailer: "ConfirmationMailer#order_email", menu: @menu, user: users(:kyle), sent_at: first_send + 30.seconds)
    end

    text = ActivityFeed.new(@week_id).to_text(verbose: true)
    assert_no_match(/RAPID DUPLICATE/, text, "team self-tests are not member-facing duplicate bugs")
  end

  test "to_text notes deliverability data is unavailable without SendGrid credentials" do
    travel_to_week_id(@week_id) do
      Ahoy::Message.create!(mailer: "MenuMailer#weekly_menu_email", menu: @menu, user: users(:kyle), sent_at: Time.zone.now)
    end

    text = ActivityFeed.new(@week_id).to_text

    assert_match(/Deliverability \(SendGrid\): data unavailable/, text)
  end

  test "to_text includes SendGrid bounce and spam counts when available" do
    ENV["SENDGRID_API_KEY"] = "SG.test-key"
    body = [
      { date: "2026-01-01", stats: [ { metrics: { requests: 20, delivered: 18, bounces: 2, blocks: 1, spam_reports: 1, invalid_emails: 0 } } ] }
    ].to_json
    stub_request(:get, "https://api.sendgrid.com/v3/stats")
      .with(query: hash_including({}))
      .to_return(status: 200, body: body, headers: { "Content-Type" => "application/json" })

    travel_to_week_id(@week_id) do
      Ahoy::Message.create!(mailer: "MenuMailer#weekly_menu_email", menu: @menu, user: users(:kyle), sent_at: Time.zone.now)
    end

    text = ActivityFeed.new(@week_id).to_text

    assert_match(/Deliverability \(SendGrid.*\): 18 delivered, 2 bounces, 1 block, 1 spam report/, text)
  ensure
    ENV.delete("SENDGRID_API_KEY")
  end

  test "to_text excludes fully resolved error fingerprints" do
    ErrorEvent.delete_all # counts events; start without the fixtures
    week_id = Time.zone.now.week_id
    week_start = Time.zone.from_week_id(week_id)

    ErrorEvent.create!(
      fingerprint: "fp-resolved", source: "server", error_class: "ResolvedError",
      message: "triaged by operator", environment: "production",
      occurred_at: week_start + 1.hour, resolved_at: Time.current
    )
    ErrorEvent.create!(
      fingerprint: "fp-open", source: "server", error_class: "OpenError",
      message: "still live", environment: "production", occurred_at: week_start + 2.hours
    )

    text = ActivityFeed.new(week_id).to_text

    assert_match(/OpenError/, text)
    assert_no_match(/ResolvedError/, text)
    assert_match(/1 resolved event excluded/, text)
  end

  test "to_text keeps fingerprints that recur after being resolved" do
    week_id = Time.zone.now.week_id
    week_start = Time.zone.from_week_id(week_id)

    ErrorEvent.create!(
      fingerprint: "fp-recur", source: "server", error_class: "RecurError",
      message: "old occurrence", environment: "production",
      occurred_at: week_start + 1.hour, resolved_at: Time.current
    )
    ErrorEvent.create!(
      fingerprint: "fp-recur", source: "server", error_class: "RecurError",
      message: "new occurrence", environment: "production", occurred_at: week_start + 5.hours
    )

    text = ActivityFeed.new(week_id).to_text

    assert_match(/RecurError/, text)
    assert_match(/recurred after resolve/, text)
  end

  test "to_text notes when all error events are resolved" do
    ErrorEvent.delete_all # counts events; start without the fixtures
    week_id = Time.zone.now.week_id
    week_start = Time.zone.from_week_id(week_id)

    2.times do |i|
      ErrorEvent.create!(
        fingerprint: "fp-quiet", source: "server", error_class: "QuietError",
        message: "handled", environment: "production",
        occurred_at: week_start + (i + 1).hours, resolved_at: Time.current
      )
    end

    text = ActivityFeed.new(week_id).to_text

    assert_no_match(/QuietError/, text)
    assert_match(/2 resolved events excluded/, text)
  end

  test "to_text tags error fingerprints not seen in prior 4 weeks as NEW" do
    week_id = Time.zone.now.week_id
    week_start = Time.zone.from_week_id(week_id)

    ErrorEvent.create!(
      fingerprint: "fp-brand-new", source: "browser", error_class: "BrandNewError",
      message: "first appearance", environment: "production", occurred_at: week_start + 1.hour
    )
    ErrorEvent.create!(
      fingerprint: "fp-carryover", source: "browser", error_class: "CarryoverError",
      message: "old friend", environment: "production", occurred_at: week_start - 2.weeks
    )
    ErrorEvent.create!(
      fingerprint: "fp-carryover", source: "browser", error_class: "CarryoverError",
      message: "old friend again", environment: "production", occurred_at: week_start + 2.hours
    )

    text = ActivityFeed.new(week_id).to_text

    assert_match(/BrandNewError ×1.*\[NEW this week/, text)
    assert_no_match(/CarryoverError ×1.*\[NEW this week/, text)
  end

  test "to_text reports zero rapid duplicate confirmations explicitly" do
    travel_to_week_id(@week_id) do
      Ahoy::Message.create!(mailer: "ConfirmationMailer#order_email", menu: @menu, user: users(:kyle), sent_at: Time.zone.now)
    end

    text = ActivityFeed.new(@week_id).to_text

    assert_match(/Rapid duplicate confirmations: 0 this week/, text)
  end

  test "to_text counts rapid duplicate confirmation pairs for the same order" do
    travel_to_week_id(@week_id) do
      sent = Time.zone.now + 1.day
      order = orders(:ljf_week1)
      Ahoy::Message.create!(mailer: "ConfirmationMailer#order_email", menu: @menu, user: users(:ljf), order: order, sent_at: sent)
      Ahoy::Message.create!(mailer: "ConfirmationMailer#order_email", menu: @menu, user: users(:ljf), order: order, sent_at: sent + 30.seconds)
    end

    text = ActivityFeed.new(@week_id).to_text

    assert_match(/Rapid duplicate confirmations: 1 pair for the same order within 2 min affecting 1 member/, text)
  end

  test "rapid duplicate counter ignores separate orders confirmed minutes apart" do
    # A card-paid specials order plus a credit order, placed back to back:
    # two orders, two legitimate confirmations (#363).
    travel_to_week_id(@week_id) do
      sent = Time.zone.now + 1.day
      Ahoy::Message.create!(mailer: "ConfirmationMailer#order_email", menu: @menu, user: users(:ljf), order: orders(:ljf_week1), sent_at: sent)
      Ahoy::Message.create!(mailer: "ConfirmationMailer#order_email", menu: @menu, user: users(:ljf), order: orders(:ljf_passover), sent_at: sent + 60.seconds)
    end

    text = ActivityFeed.new(@week_id).to_text
    verbose = ActivityFeed.new(@week_id).to_text(verbose: true)

    assert_match(/Rapid duplicate confirmations: 0 this week/, text)
    assert_no_match(/RAPID DUPLICATE/, verbose)
  end

  test "rapid duplicate counter keeps the timing check for messages without an order_id" do
    # Messages sent before ahoy_messages.order_id was tracked (#343).
    travel_to_week_id(@week_id) do
      sent = Time.zone.now + 1.day
      Ahoy::Message.create!(mailer: "ConfirmationMailer#order_email", menu: @menu, user: users(:ljf), sent_at: sent)
      Ahoy::Message.create!(mailer: "ConfirmationMailer#order_email", menu: @menu, user: users(:ljf), sent_at: sent + 30.seconds)
    end

    text = ActivityFeed.new(@week_id).to_text

    assert_match(/Rapid duplicate confirmations: 1 pair for the same order within 2 min affecting 1 member/, text)
  end

  test "verbose feed tags a same-order rapid pair as RAPID DUPLICATE" do
    travel_to_week_id(@week_id) do
      sent = Time.zone.now + 1.day
      order = orders(:ljf_week1)
      Ahoy::Message.create!(mailer: "ConfirmationMailer#order_email", menu: @menu, user: users(:ljf), order: order, sent_at: sent)
      Ahoy::Message.create!(mailer: "ConfirmationMailer#order_email", menu: @menu, user: users(:ljf), order: order, sent_at: sent + 30.seconds)
    end

    verbose = ActivityFeed.new(@week_id).to_text(verbose: true)

    assert_match(/RAPID DUPLICATE — same order confirmed twice/, verbose)
  end

  test "rapid pair with the order's items rewritten between the sends is an edit, not a duplicate" do
    # #424: member placed an order, then added an item 15s later.
    travel_to_week_id(@week_id) do
      sent = Time.zone.now + 1.day
      order = orders(:ljf_week1)
      Ahoy::Message.create!(mailer: "ConfirmationMailer#order_email", menu: @menu, user: users(:ljf), order: order, sent_at: sent)
      order.order_items.first.update_columns(created_at: sent + 14.seconds)
      Ahoy::Message.create!(mailer: "ConfirmationMailer#order_email", menu: @menu, user: users(:ljf), order: order, sent_at: sent + 15.seconds)
    end

    text = ActivityFeed.new(@week_id).to_text

    assert_match(/Rapid duplicate confirmations: 0 this week/, text)
  end

  test "identical sends a fraction of a second apart are still a RAPID DUPLICATE" do
    # The order_updated event and item rewrite both precede the first send:
    # one edit, two emails.
    travel_to_week_id(@week_id) do
      sent = Time.zone.now + 1.day
      order = orders(:ljf_week1)
      track_order_updated(users(:ljf), sent - 1.second)
      order.order_items.first.update_columns(created_at: sent - 1.second)
      Ahoy::Message.create!(mailer: "ConfirmationMailer#order_email", menu: @menu, user: users(:ljf), order: order, sent_at: sent)
      Ahoy::Message.create!(mailer: "ConfirmationMailer#order_email", menu: @menu, user: users(:ljf), order: order, sent_at: sent + 0.12.seconds)
    end

    text = ActivityFeed.new(@week_id).to_text
    verbose = ActivityFeed.new(@week_id).to_text(verbose: true)

    assert_match(/Rapid duplicate confirmations: 1 pair for the same order within 2 min affecting 1 member/, text)
    assert_match(/RAPID DUPLICATE — same order confirmed twice/, verbose)
  end

  test "an edit to the member's other order does not hide a rapid duplicate" do
    # Codex on #434: a user-wide edit signal let order B's edit mask order A's duplicate.
    travel_to_week_id(@week_id) do
      sent = Time.zone.now + 1.day
      order = orders(:ljf_week1)
      Ahoy::Message.create!(mailer: "ConfirmationMailer#order_email", menu: @menu, user: users(:ljf), order: order, sent_at: sent)
      orders(:ljf_passover).order_items.first.update_columns(created_at: sent + 10.seconds)
      track_order_updated(users(:ljf), sent + 10.seconds)
      Ahoy::Message.create!(mailer: "ConfirmationMailer#order_email", menu: @menu, user: users(:ljf), order: order, sent_at: sent + 30.seconds)
    end

    text = ActivityFeed.new(@week_id).to_text

    assert_match(/Rapid duplicate confirmations: 1 pair/, text)
  end

  test "menu context lists each menu's item names" do
    text = ActivityFeed.new(@week_id).to_text
    menu_context = text[/== Menu Context ==.*?(?=== Orders by Day ==)/m]

    assert menu_context, "expected a Menu Context section"
    assert_match(/Menu: week1/, menu_context)
    assert_match(/Items \(2\): .*Classic/, menu_context)
    assert_match(/Pumpkin/, menu_context)
  end

  test "browser 4xx warnings are listed as rejected requests, not application errors" do
    ErrorEvent.delete_all # counts events; start without the fixtures
    week_id = Time.zone.now.week_id
    week_start = Time.zone.from_week_id(week_id)

    2.times do |i|
      ErrorEvent.create!(
        fingerprint: "fp-decline", source: "browser", error_class: "AxiosError",
        message: "Request failed with status code 422", environment: "production",
        user: users(:ljf), occurred_at: week_start + (i + 1).hours,
        context: { kind: "create_order", status: 422, message: "Your card was declined.", severity: "warning" }
      )
    end
    ErrorEvent.create!(
      fingerprint: "fp-outage", source: "server", error_class: "UptimeCheck::OutageError",
      message: "menu down", environment: "production", occurred_at: week_start + 3.hours,
      context: { severity: "warning" }
    )

    text = ActivityFeed.new(week_id).to_text

    assert_match(/Application Errors \(1 events:/, text)
    assert_match(/UptimeCheck::OutageError/, text)
    assert_no_match(/AxiosError/, text)
    assert_match(/Rejected Requests \(2 browser 4xx responses/, text)
    assert_match(/create_order 422 ×2 \(1 member, .*\) — Your card was declined\./, text)
  end

  test "rapid duplicate counter ignores admin self-test pairs" do
    travel_to_week_id(@week_id) do
      sent = Time.zone.now + 1.day
      Ahoy::Message.create!(mailer: "ConfirmationMailer#order_email", menu: @menu, user: users(:kyle), sent_at: sent)
      Ahoy::Message.create!(mailer: "ConfirmationMailer#order_email", menu: @menu, user: users(:kyle), sent_at: sent + 30.seconds)
    end

    text = ActivityFeed.new(@week_id).to_text

    assert_match(/Rapid duplicate confirmations: 0 this week/, text)
  end

  test "error feed excludes non-production events" do
    week_id = Time.zone.now.week_id
    week_start = Time.zone.from_week_id(week_id)

    ErrorEvent.create!(
      fingerprint: "fp-local", source: "server", error_class: "LocalDevError",
      message: "SIGTERM from a local eval run", environment: "development",
      occurred_at: week_start + 1.hour
    )

    text = ActivityFeed.new(week_id).to_text

    assert_no_match(/LocalDevError/, text)
  end

  test "to_text reports zero failed jobs explicitly" do
    text = ActivityFeed.new(@week_id).to_text

    assert_match(/0 failed jobs/, text)
  end

  test "to_text includes failed job details when jobs failed" do
    travel_to_week_id(@week_id) do
      job = SolidQueue::Job.create!(queue_name: "default", class_name: "SendWeeklyMenuJob", arguments: "{}")
      SolidQueue::FailedExecution.create!(
        job: job,
        error: { exception_class: "RuntimeError", message: "boom went the bread", backtrace: [] }
      )
    end

    text = ActivityFeed.new(@week_id).to_text

    assert_match(/1 failed job/, text)
    assert_match(/SendWeeklyMenuJob/, text)
    assert_match(/RuntimeError/, text)
    assert_match(/boom went the bread/, text)
  end

  test "verbose feed still tags reminder emails with DUPLICATE when user/pickup_day collides" do
    travel_to_week_id(@week_id) do
      pd = @menu.pickup_days.first
      sent = Time.zone.now + 2.days
      Ahoy::Message.create!(mailer: "ReminderMailer#day_of_email", menu: @menu, user: users(:kyle), pickup_day: pd, sent_at: sent)
      Ahoy::Message.create!(mailer: "ReminderMailer#day_of_email", menu: @menu, user: users(:kyle), pickup_day: pd, sent_at: sent + 1.minute)
    end

    text = ActivityFeed.new(@week_id).to_text(verbose: true)
    assert_match(/DUPLICATE — 2x/, text, "reminder duplicates must still be flagged")
  end

  test "to_text includes an uptime section with per-target stats and failures" do
    week_start = Time.zone.from_week_id(@week_id)
    UptimeCheck.create!(target: "menu", url: "https://probe.test/menu.json", status: 200, latency_ms: 100, up: true, checked_at: week_start + 1.day)
    UptimeCheck.create!(target: "menu", url: "https://probe.test/menu.json", status: 503, latency_ms: 50, up: false, checked_at: week_start + 1.day + 15.minutes)
    UptimeCheck.create!(target: "admin", url: "https://probe.test/admin", status: 302, latency_ms: 80, up: true, checked_at: week_start + 1.day)

    text = ActivityFeed.new(@week_id).to_text

    assert_includes text, "== Uptime (scheduled probes) =="
    assert_includes text, "menu: 50.0% up (1/2 checks)"
    assert_includes text, "admin: 100.0% up (1/1 checks)"
    assert_match(/FAIL .* GET https:\/\/probe\.test\/menu\.json → HTTP 503/, text)
    assert_match(/missed slot/, text, "sparse checks in a past week should surface missed slots")
  end

  test "to_text omits the uptime section when there are no checks" do
    assert_not_includes ActivityFeed.new(@week_id).to_text, "== Uptime"
  end

  test "to_text omits the uptime section for weeks before monitoring existed" do
    week_start = Time.zone.from_week_id(@week_id)
    UptimeCheck.create!(target: "menu", url: "https://probe.test/menu.json", status: 200, latency_ms: 100, up: true, checked_at: week_start + 3.weeks)

    assert_not_includes ActivityFeed.new(@week_id).to_text, "== Uptime"
  end

  test "to_text flags a monitored target that recorded zero checks all week" do
    week_start = Time.zone.from_week_id(@week_id)
    # admin was monitored before this week, then went completely silent
    UptimeCheck.create!(target: "admin", url: "https://probe.test/admin", status: 302, latency_ms: 80, up: true, checked_at: week_start - 3.days)
    UptimeCheck.create!(target: "menu", url: "https://probe.test/menu.json", status: 200, latency_ms: 100, up: true, checked_at: week_start + 1.day)

    text = ActivityFeed.new(@week_id).to_text

    assert_match(/admin: NO CHECKS RECORDED — \d+ expected slots all missed/, text)
    assert_includes text, "menu: 100.0% up (1/1 checks)"
  end

  test "uptime checks roll up into one daily grid event per day" do
    week_start = Time.zone.from_week_id(@week_id)
    UptimeCheck.create!(target: "menu", url: "https://probe.test/menu.json", status: 200, latency_ms: 100, up: true, checked_at: week_start + 1.day + 9.hours)
    UptimeCheck.create!(target: "admin", url: "https://probe.test/admin", status: 302, latency_ms: 80, up: true, checked_at: week_start + 1.day + 10.hours)
    UptimeCheck.create!(target: "menu", url: "https://probe.test/menu.json", status: 500, latency_ms: 60, up: false, checked_at: week_start + 2.days + 9.hours)

    feed = ActivityFeed.new(@week_id)
    events = feed.summary.select { |e| e.action == "uptime_summary" }

    assert_equal 2, events.size
    assert_includes feed.grid_columns, "uptime_summary"

    day_one = events.find { |e| e.details[:checks] == 2 }
    assert_equal "system", day_one.category
    assert_equal 100, day_one.details[:pct]
    assert_equal "Uptime: 100% (2 checks)", day_one.description

    day_two = events.find { |e| e.details[:checks] == 1 }
    assert_equal 0, day_two.details[:pct]
    assert_equal 1, day_two.details[:failures]
  end

  # 26w46 (anomaly analysis 7558): the menu for 11/12–11/14 was filed as 26w47
  # and a blank placeholder sat at 26w46, so the report saw "untitled menu,
  # zero orders, no Email Health" and warned about a healthy week.
  test "a menu filed under the wrong week still belongs to the week it's picked up in" do
    week = misfiled_week

    travel_to(week[:start] + 3.days + 12.hours) do
      feed = ActivityFeed.new("24w20")
      text = feed.to_text

      assert_equal week[:menu], feed.primary_menu
      assert_match(/^Menu: Weekly Menu 5\/16 - 5\/18$/, text)
      assert_match(/Filed in admin under week 24w21, but it is picked up this week/, text)
      assert_match(/Draft menu \(ignore\): \(untitled\)/, text)
      assert_match(/Total so far: 2 orders \(2 items\)/, text)
      assert_includes text, "== Email Health =="
      assert_match(/Weekly menu email: 1 sent/, text)
      assert_includes text, "Weekly menu emailed", "admin events logged under the filed week come along"
      assert_equal 2, feed.headline_metrics.find { |m| m[:label] == "Orders" }[:value]
    end
  end

  test "a menu filed under the wrong week does not also show up in the week it was filed under" do
    week = misfiled_week

    feed = ActivityFeed.new("24w21")

    assert_nil feed.primary_menu
    assert_not_includes feed.to_text, week[:menu].name
    assert_empty feed.summary.select { |e| e.action == "orders_summary" }
  end

  test "holiday pre-orders placed this week are reported apart from the weekly menu" do
    week = misfiled_week
    holiday = holiday_preorders(week)

    travel_to(week[:start] + 3.days + 12.hours) do
      feed = ActivityFeed.new("24w20")
      text = feed.to_text

      assert_match(/Holiday pre-order menu \(open for orders now, picked up in a later week\): Thanksgiving Orders/, text)
      assert_match(/== Holiday Pre-orders: Thanksgiving Orders \(pickup Tue 5\/28\) ==/, text)
      assert_match(/This week: 1 orders \(1 items\)\. 1 since pre-orders opened\./, text)
      assert_match(/Total so far: 2 orders \(2 items\)/, text, "pre-orders stay out of the weekly menu's total")
      assert_match(/\[pre-order: Thanksgiving Orders\]/, text)
      assert_match(/Order email: 1 sent/, text, "the pre-order's confirmation counts in Email Health")

      preorders = feed.summary.select { |e| e.action == "orders_summary" && e.details[:preorder] }
      assert_equal 1, preorders.size
      assert_match(/1 holiday pre-orders placed for Thanksgiving Orders/, preorders.first.description)
      assert_equal holiday.id, preorders.first.details[:menu_id]
    end
  end

  test "a holiday menu's own week notes the pre-orders that came in earlier" do
    week = misfiled_week
    holiday_preorders(week)

    travel_to(week[:start] + 2.weeks + 1.day) do
      text = ActivityFeed.new("24w22").to_text

      assert_match(/^Holiday menu: Thanksgiving Orders$/, text)
      assert_match(/Total so far: 0 orders/, text)
      assert_match(/Plus 1 placed before this week began/, text)
      assert_not_includes text, "== Holiday Pre-orders"
    end
  end

  private

  # Week 24w20 (Sun 5/12/2024): a blank draft filed as 24w20, and the real
  # menu, picked up Thu 5/16 and Sat 5/18, filed as 24w21.
  def misfiled_week
    start = Time.zone.from_week_id("24w20")
    Menu.create!(week_id: "24w20", name: "")
    menu = Menu.create!(week_id: "24w21", name: "Weekly Menu 5/16 - 5/18", emailed_at: start + 9.hours)
    menu.menu_items.create!(item: items(:classic))
    thu = menu.pickup_days.create!(pickup_at: start + 4.days + 7.hours, order_deadline_at: start + 3.days + 12.hours)
    menu.pickup_days.create!(pickup_at: start + 6.days + 5.hours, order_deadline_at: start + 5.days + 12.hours)

    [ users(:adrian), users(:ljf) ].each_with_index do |user, i|
      order = user.orders.create!(menu: menu, created_at: start + (i + 1).days)
      order.order_items.create!(item: items(:classic), pickup_day: thu, quantity: 1)
    end
    Ahoy::Message.create!(mailer: "MenuMailer#weekly_menu_email", menu: menu, user: users(:adrian), sent_at: start + 9.hours)
    ActivityEvent.create!(action: "menu_emailed", week_id: "24w21", description: "Weekly menu emailed", created_at: start + 9.hours)

    { start: start, menu: menu }
  end

  # A holiday menu picked up two weeks later (Tue 5/28, week 24w22) that takes
  # one pre-order during 24w20.
  def holiday_preorders(week)
    start = week[:start]
    holiday = Menu.create!(week_id: "24w22", name: "Thanksgiving Orders", menu_type: "holiday")
    holiday.menu_items.create!(item: items(:rye))
    pickup = holiday.pickup_days.create!(pickup_at: start + 16.days + 8.hours, order_deadline_at: start + 14.days)
    order = users(:kyle).orders.create!(menu: holiday, created_at: start + 2.days)
    order.order_items.create!(item: items(:rye), pickup_day: pickup, quantity: 1)
    Ahoy::Message.create!(mailer: "ConfirmationMailer#order_email", menu: holiday, user: users(:kyle), order_id: order.id, sent_at: start + 2.days)
    holiday
  end

  def track_order_updated(user, time)
    visit = Ahoy::Visit.create!(user: user, started_at: time, visit_token: SecureRandom.hex(8), visitor_token: SecureRandom.hex(8))
    Ahoy::Event.create!(name: "order_updated", user: user, visit: visit, time: time)
  end
end
