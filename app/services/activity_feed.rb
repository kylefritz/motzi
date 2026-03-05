class ActivityFeed
  Event = Struct.new(:timestamp, :category, :action, :description, :details, keyword_init: true)

  RECURRING_JOB_LABELS = {
    "SendDayOfReminderJob" => "Day-of reminder job",
    "SendHaventOrderedReminderJob" => "Haven't-ordered reminder job",
    "SendWeeklyMenuJob" => "Weekly menu email job",
    "AnalyzeAnomaliesJob" => "Anomaly analysis job",
    "SolidQueue::RecurringJob" => "Recurring command"
  }.freeze

  MAILER_LABELS = {
    "MenuMailer#weekly_menu_email" => "Weekly menu email",
    "ConfirmationMailer#order_email" => "Order confirmations",
    "ReminderMailer#day_of_email" => "Day-of reminders",
    "ReminderMailer#havent_ordered_email" => "Haven't-ordered reminders",
    "ConfirmationMailer#credit_email" => "Credit purchase confirmations"
  }.freeze

  def initialize(week_id)
    @week_id = week_id
    @week_start = Time.zone.from_week_id(week_id)
    @week_end = @week_start + 7.days
    @menus = [
      Menu.find_by(week_id: week_id, menu_type: "regular"),
      Menu.find_by(week_id: week_id, menu_type: "holiday")
    ].compact
  end

  def events(verbose: false)
    all = []
    all.concat(activity_events(verbose: verbose))
    all.concat(order_events(verbose: verbose))
    all.concat(credit_events(verbose: verbose))
    all.concat(email_events(verbose: verbose))
    all.concat(recurring_job_events(verbose: verbose))
    all.concat(visit_events(verbose: verbose))
    all.sort_by(&:timestamp)
  end

  def summary
    events(verbose: false)
  end

  def verbose_events
    events(verbose: true)
  end

  def email_summary
    stats = {}
    @menus.each do |menu|
      menu.messages.group_by(&:mailer).each do |mailer, messages|
        existing = stats[mailer]
        if existing
          existing[:sent] += messages.size
          existing[:opened] += messages.count { |m| m.opened_at.present? }
          existing[:clicked] += messages.count { |m| m.clicked_at.present? }
        else
          sent = messages.size
          opened = messages.count { |m| m.opened_at.present? }
          clicked = messages.count { |m| m.clicked_at.present? }
          stats[mailer] = {
            label: MAILER_LABELS[mailer] || mailer,
            sent: sent,
            opened: opened,
            clicked: clicked,
            open_rate: sent > 0 ? (opened.to_f / sent * 100).round : 0
          }
        end
      end
    end
    # Recalculate open_rate after merging
    stats.each do |_, s|
      s[:open_rate] = s[:sent] > 0 ? (s[:opened].to_f / s[:sent] * 100).round : 0
    end
    stats
  end

  def to_text(verbose: false)
    lines = []
    lines << "Activity Feed: #{@week_id}"
    lines << "=" * 40
    lines << ""

    es = email_summary
    if es.any?
      lines << "== Email Health =="
      MAILER_LABELS.each do |mailer, _|
        next unless es[mailer]
        s = es[mailer]
        parts = ["#{s[:sent]} sent", "#{s[:opened]} opened (#{s[:open_rate]}%)"]
        parts << "#{s[:clicked]} clicked" if s[:clicked] > 0
        lines << "#{s[:label]}: #{parts.join(', ')}"
      end
      # Any mailers not in MAILER_LABELS
      es.each do |mailer, s|
        next if MAILER_LABELS.key?(mailer)
        parts = ["#{s[:sent]} sent", "#{s[:opened]} opened (#{s[:open_rate]}%)"]
        parts << "#{s[:clicked]} clicked" if s[:clicked] > 0
        lines << "#{s[:label]}: #{parts.join(', ')}"
      end
      lines << ""
    end

    evts = events(verbose: verbose)
    lines << "== Events =="
    evts.each do |e|
      ts = e.timestamp.strftime("%-m/%d %l:%M%P").strip
      lines << "[#{ts}] [#{e.category}] #{e.description}"
    end
    lines << ""
    lines << "#{evts.size} events"

    lines.join("\n")
  end

  private

  def activity_events(verbose: false)
    ActivityEvent.for_week(@week_id).order(:created_at).map do |ae|
      desc = ae.description
      desc = "#{desc} #{ae.metadata.to_json}" if verbose && ae.metadata.present? && ae.metadata != {}
      Event.new(
        timestamp: ae.created_at,
        category: "admin",
        action: ae.action,
        description: desc,
        details: { source: "activity_event", id: ae.id }
      )
    end
  end

  def order_events(verbose: false)
    events = []
    @menus.each do |menu|
      orders = menu.orders.includes(:user, order_items: :item)

      if verbose
        orders.each do |order|
          events << Event.new(
            timestamp: order.created_at,
            category: "customer",
            action: "order_placed",
            description: "#{order.user.name} ordered: #{order.item_list}",
            details: { source: "order", id: order.id, menu_id: menu.id }
          )
        end

        # Order edits via PaperTrail
        order_ids = orders.map(&:id)
        if order_ids.any?
          PaperTrail::Version.where(item_type: "Order", item_id: order_ids, event: "update").each do |version|
            events << Event.new(
              timestamp: version.created_at,
              category: "customer",
              action: "order_edited",
              description: "Order ##{version.item_id} edited",
              details: { source: "paper_trail", id: version.id }
            )
          end
        end
      else
        if orders.any?
          events << Event.new(
            timestamp: orders.maximum(:created_at),
            category: "customer",
            action: "orders_summary",
            description: "#{orders.size} orders placed for #{menu.name}",
            details: { source: "orders", menu_id: menu.id, count: orders.size }
          )
        end
      end
    end
    events
  end

  def credit_events(verbose: false)
    events = []
    purchases = CreditItem.bought.where(created_at: @week_start..@week_end).includes(:user)

    if verbose
      purchases.each do |ci|
        events << Event.new(
          timestamp: ci.created_at,
          category: "customer",
          action: "credit_purchased",
          description: "#{ci.user.name} purchased #{ci.quantity} credits ($#{'%.2f' % (ci.stripe_charge_amount / 100.0)})",
          details: { source: "credit_item", id: ci.id }
        )
      end
    else
      if purchases.any?
        total_credits = purchases.sum(:quantity)
        total_dollars = purchases.sum(:stripe_charge_amount) / 100.0
        events << Event.new(
          timestamp: purchases.maximum(:created_at),
          category: "customer",
          action: "credits_summary",
          description: "#{purchases.size} purchases (#{total_credits} credits, $#{'%.2f' % total_dollars})",
          details: { source: "credit_items", count: purchases.size, total_credits: total_credits }
        )
      end
    end
    events
  end

  def recurring_job_events(verbose: false)
    events = []
    return events unless defined?(SolidQueue::Job)

    jobs = SolidQueue::Job.where(created_at: @week_start..@week_end)
      .where(class_name: RECURRING_JOB_LABELS.keys)
      .order(:created_at)

    if verbose
      jobs.each do |job|
        label = RECURRING_JOB_LABELS[job.class_name] || job.class_name
        status = job.finished? ? "completed" : "running"
        events << Event.new(
          timestamp: job.created_at,
          category: "system",
          action: "recurring_job",
          description: "#{label} #{status}",
          details: { source: "solid_queue", id: job.id, class_name: job.class_name }
        )
      end
    else
      jobs.group_by(&:class_name).each do |class_name, class_jobs|
        label = RECURRING_JOB_LABELS[class_name] || class_name
        finished = class_jobs.count(&:finished?)
        failed = class_jobs.size - finished
        desc = "#{label}: #{finished} runs"
        desc += " (#{failed} incomplete)" if failed > 0
        events << Event.new(
          timestamp: class_jobs.last.created_at,
          category: "system",
          action: "recurring_jobs_summary",
          description: desc,
          details: { source: "solid_queue", class_name: class_name, total: class_jobs.size, finished: finished }
        )
      end
    end
    events
  end

  def visit_events(verbose: false)
    events = []
    visits = Ahoy::Visit.where(started_at: @week_start..@week_end)

    daily = visits.group("started_at::date")
    daily_visits = daily.count
    daily_unique = daily.distinct.count(:visitor_token)

    if verbose
      daily_visits.sort.each do |date, count|
        unique = daily_unique[date] || 0
        events << Event.new(
          timestamp: date.to_time.in_time_zone,
          category: "traffic",
          action: "daily_visits",
          description: "#{unique} unique visitors (#{count} visits)",
          details: { source: "ahoy_visits", date: date.to_s, visits: count, unique: unique }
        )
      end
    else
      if daily_visits.any?
        total_visits = daily_visits.values.sum
        total_unique = visits.distinct.count(:visitor_token)
        avg_daily = (total_unique.to_f / daily_visits.size).round
        events << Event.new(
          timestamp: @week_start,
          category: "traffic",
          action: "visits_summary",
          description: "#{total_unique} unique visitors (#{total_visits} visits, ~#{avg_daily}/day)",
          details: { source: "ahoy_visits", total_visits: total_visits, unique: total_unique, days: daily_visits.size }
        )
      end
    end
    events
  end

  def email_events(verbose: false)
    events = []
    @menus.each do |menu|
      messages_by_mailer = menu.messages.includes(:user).group_by(&:mailer)

      messages_by_mailer.each do |mailer, messages|
        label = MAILER_LABELS[mailer] || mailer

        if verbose
          messages.each do |msg|
            user_name = msg.user&.name || "Unknown"
            parts = ["sent #{msg.sent_at&.strftime('%-m/%d %l:%M%P')&.strip}"]
            parts << "opened #{msg.opened_at.strftime('%-m/%d %l:%M%P').strip}" if msg.opened_at
            parts << "clicked #{msg.clicked_at.strftime('%-m/%d %l:%M%P').strip}" if msg.clicked_at
            events << Event.new(
              timestamp: msg.sent_at || msg.created_at,
              category: "email",
              action: "email_sent",
              description: "#{label} to #{user_name} (#{parts.join(', ')})",
              details: { source: "ahoy_message", id: msg.id, mailer: mailer }
            )
          end
        else
          sent_count = messages.size
          opened_count = messages.count { |m| m.opened_at.present? }
          open_rate = sent_count > 0 ? (opened_count.to_f / sent_count * 100).round : 0
          timestamp = messages.filter_map(&:sent_at).min || messages.map(&:created_at).min

          events << Event.new(
            timestamp: timestamp,
            category: "email",
            action: "email_summary",
            description: "#{opened_count}/#{sent_count} #{label.downcase} opened (#{open_rate}%)",
            details: { source: "ahoy_messages", mailer: mailer, sent: sent_count, opened: opened_count, open_rate: open_rate }
          )
        end
      end
    end
    events
  end
end
