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
      stripe_charge_amount: 4800,
      memo: "test purchase",
      good_for_weeks: 7,
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
      stripe_charge_amount: 4800,
      memo: "test purchase",
      good_for_weeks: 7,
      created_at: week_start + 1.hour
    )

    feed = ActivityFeed.new(@week_id)
    evts = feed.verbose_events
    credit_events = evts.select { |e| e.action == "credit_purchased" }

    assert credit_events.any?, "Verbose should show individual credit purchases"
    assert_includes credit_events.first.description, "Kyle Fritz"
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

  test "watchlist flags low orders and repeated anomaly jobs" do
    feed = ActivityFeed.new(@week_id)
    feed.define_singleton_method(:comparison_snapshot) do |lookback: 4|
      {
        label: "through Fri 1/4 so far",
        current: { orders: 18, items: 30, visitors: 60, visits: 72, credit_purchases: 1, credit_credits: 13, emails_sent: 50, emails_opened: 25, email_open_rate: 50, job_runs: 4, anomaly_jobs: 6, incomplete_jobs: 1 },
        previous: Array.new(lookback) { {} },
        average: { orders: 30, items: 40, visitors: 80, visits: 95, credit_purchases: 2, credit_credits: 8, emails_sent: 48, emails_opened: 24, email_open_rate: 50, job_runs: 2, anomaly_jobs: 1, incomplete_jobs: 0 }
      }
    end
    feed.define_singleton_method(:mailer_open_rate_trend) do |_mailer, lookback: 4|
      { current_rate: 40, average_rate: 50 }
    end

    items = feed.watchlist_items

    assert items.any? { |item| item[:title].include?("Orders are tracking below normal") }
    assert items.any? { |item| item[:title].include?("Background job activity needs a look") }
    assert items.any? { |item| item[:title].include?("Haven't-ordered reminder engagement is slipping") }
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
    feed.define_singleton_method(:local_git_commits) { [commit] }

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
    assert_match(/2 R14/, text)
  end

  test "to_text omits dyno memory section when no metrics" do
    feed = ActivityFeed.new(@week_id)
    text = feed.to_text

    assert_no_match(/Dyno Memory/, text)
  end

  test "to_text includes Application Errors section when error events exist" do
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
        environment: Rails.env,
        occurred_at: week_start + (i + 1).hours
      )
    end
    ErrorEvent.create!(
      fingerprint: "fp-browser",
      source: "browser",
      error_class: "TypeError",
      message: "Cannot read 'foo' of undefined",
      environment: Rails.env,
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
      Ahoy::Message.create!(mailer: "ConfirmationMailer#order_email", menu: @menu, user: users(:kyle), sent_at: first_send)
      Ahoy::Message.create!(mailer: "ConfirmationMailer#order_email", menu: @menu, user: users(:kyle), sent_at: first_send + 30.seconds)
    end

    text = ActivityFeed.new(@week_id).to_text(verbose: true)
    assert_match(/RAPID DUPLICATE/, text, "sub-minute-gap confirmations are the real bug signal")
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
      { date: "2026-01-01", stats: [{ metrics: { requests: 20, delivered: 18, bounces: 2, blocks: 1, spam_reports: 1, invalid_emails: 0 } }] }
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
    week_id = Time.zone.now.week_id
    week_start = Time.zone.from_week_id(week_id)

    ErrorEvent.create!(
      fingerprint: "fp-resolved", source: "server", error_class: "ResolvedError",
      message: "triaged by operator", environment: Rails.env,
      occurred_at: week_start + 1.hour, resolved_at: Time.current
    )
    ErrorEvent.create!(
      fingerprint: "fp-open", source: "server", error_class: "OpenError",
      message: "still live", environment: Rails.env, occurred_at: week_start + 2.hours
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
      message: "old occurrence", environment: Rails.env,
      occurred_at: week_start + 1.hour, resolved_at: Time.current
    )
    ErrorEvent.create!(
      fingerprint: "fp-recur", source: "server", error_class: "RecurError",
      message: "new occurrence", environment: Rails.env, occurred_at: week_start + 5.hours
    )

    text = ActivityFeed.new(week_id).to_text

    assert_match(/RecurError/, text)
    assert_match(/recurred after resolve/, text)
  end

  test "to_text notes when all error events are resolved" do
    week_id = Time.zone.now.week_id
    week_start = Time.zone.from_week_id(week_id)

    2.times do |i|
      ErrorEvent.create!(
        fingerprint: "fp-quiet", source: "server", error_class: "QuietError",
        message: "handled", environment: Rails.env,
        occurred_at: week_start + (i + 1).hours, resolved_at: Time.current
      )
    end

    text = ActivityFeed.new(week_id).to_text

    assert_no_match(/QuietError/, text)
    assert_match(/2 resolved events excluded/, text)
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
end
