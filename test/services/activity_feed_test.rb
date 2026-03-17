require "test_helper"

class ActivityFeedTest < ActiveSupport::TestCase
  setup do
    @week_id = "19w01"
    @menu = menus(:week1)
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
end
