ActiveAdmin.register_page "Activity Feed" do
  menu priority: 2, label: "Activity"

  controller do
    def index
      @week_id = params[:week_id] || Time.zone.now.week_id
      @verbose = params[:verbose] == "true"
      @feed = ActivityFeed.new(@week_id)
      @events = @verbose ? @feed.verbose_events : @feed.summary
      @email_summary = @feed.email_summary
      @analyses = AnomalyAnalysis.for_week(@week_id).order(created_at: :desc)
    end
  end

  # JSON endpoint
  page_action :json_feed, method: :get do
    week_id = params[:week_id] || Time.zone.now.week_id
    verbose = params[:verbose] == "true"
    feed = ActivityFeed.new(week_id)
    events = verbose ? feed.verbose_events : feed.summary

    render json: {
      week_id: week_id,
      verbose: verbose,
      email_summary: feed.email_summary,
      event_count: events.size,
      events: events.map do |e|
        {
          timestamp: e.timestamp&.iso8601,
          category: e.category,
          action: e.action,
          description: e.description,
          details: e.details
        }
      end
    }
  end

  # Plain text endpoint
  page_action :plain_feed, method: :get do
    week_id = params[:week_id] || Time.zone.now.week_id
    verbose = params[:verbose] == "true"
    feed = ActivityFeed.new(week_id)
    render plain: feed.to_text(verbose: verbose), content_type: "text/plain"
  end

  # Analyze with Claude
  page_action :analyze, method: :post do
    week_id = params[:week_id] || Time.zone.now.week_id
    detector = AnomalyDetector.new(week_id)
    analysis = detector.analyze(trigger: "manual", user: current_admin_user)
    AnomalyMailer.with(analysis: analysis).anomaly_report.deliver_now

    first_line = analysis.result.lines.first&.strip || "Complete"
    redirect_to admin_activity_feed_path(week_id: week_id),
      notice: "Analysis complete — #{first_line}"
  end

  content title: proc { "Activity Feed: #{@week_id}" } do
    # Week navigation
    div class: "activity-feed-nav", style: "margin-bottom: 16px" do
      weeks = (0..8).map { |i| (Time.zone.now - i.weeks).week_id }.uniq
      weeks.each do |wid|
        if wid == @week_id
          span wid, style: "margin-right: 12px; font-weight: bold; text-decoration: underline"
        else
          a wid, href: admin_activity_feed_path(week_id: wid), style: "margin-right: 12px"
        end
      end
    end

    # Format links and controls
    div style: "margin-bottom: 16px" do
      if @verbose
        a "Summary View", href: admin_activity_feed_path(week_id: @week_id)
      else
        a "Verbose View (all details)", href: admin_activity_feed_path(week_id: @week_id, verbose: true)
      end
      span " | ", style: "margin: 0 8px"
      a "JSON", href: admin_activity_feed_json_feed_path(week_id: @week_id, verbose: @verbose), target: "_blank"
      span " | ", style: "margin: 0 8px"
      a "Text", href: admin_activity_feed_plain_feed_path(week_id: @week_id, verbose: @verbose), target: "_blank"
      span " | ", style: "margin: 0 8px"
      text_node button_to("Analyze with Claude", admin_activity_feed_analyze_path(week_id: @week_id), method: :post, style: "display: inline")
    end

    # Email Health Panel
    panel "Email Health" do
      if @email_summary.empty?
        para "No email data for #{@week_id}", style: "color: #888"
      else
        table_for @email_summary.values do
          column("Email Type") { |row| row[:label] }
          column("Sent") { |row| row[:sent] }
          column("Opened") { |row|
            if row[:sent] > 0
              rate = row[:open_rate]
              color = if rate >= 50
                        "green"
                      elsif rate >= 20
                        "orange"
                      else
                        "red"
                      end
              span "#{row[:opened]}/#{row[:sent]} (#{rate}%)", style: "color: #{color}; font-weight: bold"
            else
              "—"
            end
          }
          column("Clicked") { |row| row[:clicked] > 0 ? row[:clicked] : "—" }
        end
      end
    end

    # Events table
    panel "Events (#{@events.size})" do
      if @events.empty?
        para "No activity for #{@week_id}", style: "color: #888"
      else
        table_for @events do
          column("Time") { |e| e.timestamp&.strftime("%y-%m-%d %l:%M%P") }
          column("Source") { |e|
            case e.category
            when "email"
              status_tag(e.category, color: "purple")
            when "admin"
              status_tag(e.category, color: "blue")
            when "customer"
              status_tag(e.category, color: "green")
            else
              status_tag(e.category)
            end
          }
          column("Action") { |e| e.action.to_s.humanize }
          column("Description") { |e| e.description }
        end
      end
    end

    # Past analyses
    if @analyses.any?
      panel "Claude Analyses" do
        @analyses.each do |analysis|
          div style: "margin-bottom: 16px; padding: 12px; background: #f9f9f9; border-radius: 4px" do
            div style: "margin-bottom: 8px" do
              strong analysis.created_at.strftime("%y-%m-%d %l:%M%P")
              span " (#{analysis.trigger})", style: "color: #888"
              if analysis.user
                span " by #{analysis.user.name}", style: "color: #888"
              end
            end
            div do
              text_node simple_format(analysis.result)
            end
            div style: "font-size: 0.8em; color: #aaa; margin-top: 4px" do
              text_node "#{analysis.model_used} · #{analysis.input_tokens} in / #{analysis.output_tokens} out"
            end
          end
        end
      end
    end
  end
end
