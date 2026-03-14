ActiveAdmin.register_page "Activity Feed" do
  menu priority: 2, label: "Activity"

  # Preview the full prompt that would be sent to Claude
  page_action :prompt_preview, method: :get do
    week_id = params[:week_id] || Time.zone.now.week_id
    detector = AnomalyDetector.new(week_id)

    text = "=== SYSTEM PROMPT ===\n\n#{detector.system_prompt}\n\n=== USER MESSAGE ===\n\n#{detector.build_user_message}"
    render plain: text, content_type: "text/plain"
  end

  # Analyze with Claude (enqueues background job)
  page_action :analyze, method: :post do
    week_id = params[:week_id] || Time.zone.now.week_id
    AnalyzeAnomaliesJob.perform_later(week_id: week_id, trigger: "manual", user_id: current_admin_user.id)
    redirect_to admin_activity_feed_path(week_id: week_id),
      notice: "Analysis queued — results will appear below when ready."
  end

  content title: "Activity Feed" do
    week_id = params[:week_id] || Time.zone.now.week_id
    feed = ActivityFeed.new(week_id)
    events = feed.summary
    email_summary = feed.email_summary
    analyses = AnomalyAnalysis.for_week(week_id).order(created_at: :desc)

    week_start = Time.zone.from_week_id(week_id)
    week_end = week_start + 6.days

    # Week header
    menu = Menu.find_by(week_id: week_id)
    div class: "activity-feed-header" do
      span(menu&.name || week_id, class: "week-id")
      span "#{week_id} · #{week_start.strftime('%A %-m/%-d')} — #{week_end.strftime('%A %-m/%-d/%Y')}", class: "date-range"
    end

    # Week navigation + controls on same line
    div class: "activity-toolbar" do
      div class: "activity-feed-nav" do
        weeks = (0..8).map { |i| (Time.zone.now - i.weeks).week_id }.uniq
        weeks.each do |wid|
          if wid == week_id
            span wid
          else
            a wid, href: admin_activity_feed_path(week_id: wid)
          end
        end
      end

      div class: "activity-controls" do
        div class: "export-links" do
          a "Prompt Preview", href: admin_activity_feed_prompt_preview_path(week_id: week_id), target: "_blank"
        end

        analyze_tooltip = "Sends this week's verbose activity feed plus 4 prior weeks' summaries to Claude (#{AnomalyDetector::MODEL}). Claude compares order counts, email delivery rates, credit purchases, visitor traffic, and job runs against recent patterns to flag missing actions, unusual volumes, timing anomalies, or delivery problems. Results are emailed to the bakery operator."
        div class: "analyze-area" do
          text_node button_to(
            "Analyze with Claude",
            admin_activity_feed_analyze_path(week_id: week_id),
            method: :post,
            title: analyze_tooltip
          )
          div id: "analysis-status", "data-week-id": week_id, class: "analysis-progress" do
            span id: "analysis-loader", class: "spinner"
            span id: "analysis-timer", class: "elapsed"
            span id: "analysis-message", class: "progress-msg"
          end
        end
      end
    end

    # Activity panel (email health + daily grid)
    grid = feed.daily_grid
    grid_columns = feed.grid_columns

    panel "Activity" do
      # Email health cards
      if email_summary.any?
        label_order = ActivityFeed::MAILER_LABELS.keys
        sorted_stats = email_summary.sort_by { |k, _| label_order.index(k) || label_order.size }.map(&:last)
        div class: "email-health-row" do
          sorted_stats.each do |row|
            div class: "email-stat" do
              div class: "email-stat-label" do
                text_node row[:label]
              end
              if row[:sent] > 0
                span row[:sent].to_s, class: "email-stat-num"
                span " sent", class: "cell-label"
                rate = row[:open_rate]
                rate_color = rate >= 50 ? "green" : rate >= 20 ? "orange" : "red"
                span " · #{rate}% opened", style: "color: #{rate_color}", title: "Tracking pixel open-rate percent"
                if row[:clicked] > 0
                  span " · #{row[:clicked]} clicked", class: "cell-dim"
                end
              else
                span "—", class: "cell-dim"
              end
            end
          end
        end
      end

      # Daily grid
      if grid_columns.empty?
        para "No activity for #{week_id}", style: "color: #999"
      else
        div style: "overflow-x: auto" do
          table class: "activity-grid" do
            thead do
              tr do
                th "Day"
                grid_columns.each do |col|
                  th(ActivityFeed::GRID_COLUMN_LABELS[col] || col.humanize)
                end
              end
            end
            tbody do
              grid.each do |date, actions|
                is_today = date == Time.zone.today
                tr class: is_today ? "is-today" : nil do
                  td do
                    text_node date.strftime("%A %-m/%-d")
                    span "today", class: "today-label" if is_today
                  end
                  grid_columns.each do |col|
                    td do
                      evts_for_cell = actions[col] || []
                      if evts_for_cell.any?
                        evts_for_cell.each do |e|
                          div class: "cell-item" do
                            case e.action
                            when "daily_visits"
                              next_day = (Date.parse(e.details[:date]) + 1).to_s
                              a href: admin_visits_path(q: { started_at_gteq: e.details[:date], started_at_lteq: next_day }), class: "cell-link" do
                                span e.details[:unique].to_s, class: "cell-num"
                                span " visitors ", class: "cell-label"
                                span "(#{e.details[:visits]} hits)", class: "cell-dim"
                              end
                            when "orders_summary"
                              d = e.details
                              next_day = (Date.parse(d[:date]) + 1).to_s
                              a href: admin_orders_path(q: { created_at_gteq: d[:date], created_at_lteq: next_day }), class: "cell-link" do
                                span d[:count].to_s, class: "cell-num"
                                span " orders", class: "cell-label"
                              end
                            when "credits_summary"
                              d = e.details
                              next_day = (Date.parse(d[:date]) + 1).to_s
                              a href: admin_credit_items_path(q: { created_at_gteq: d[:date], created_at_lteq: next_day }), class: "cell-link" do
                                span d[:count].to_s, class: "cell-num"
                                span " purchases ", class: "cell-label"
                                span "$#{'%.0f' % d[:total_credits].to_f}", class: "cell-dim"
                              end
                            when "email_summary"
                              d = e.details
                              rate_color = d[:open_rate] >= 50 ? "green" : d[:open_rate] >= 20 ? "orange" : "red"
                              label = ActivityFeed::MAILER_LABELS[d[:mailer]]&.downcase&.gsub(/ (email|confirmations|reminders)/, "") || d[:mailer]
                              next_day = (Date.parse(d[:date]) + 1).to_s
                              a href: admin_emails_path(q: { sent_at_gteq: d[:date], sent_at_lteq: next_day }), class: "cell-link" do
                                span d[:sent].to_s, class: "cell-num"
                                span " #{label} sent", class: "cell-label"
                                span " · #{d[:open_rate]}% opened", style: "color: #{rate_color}", class: "cell-dim", title: "Tracking pixel open-rate percent"
                              end
                            when "recurring_jobs_summary"
                              span e.description, class: "cell-label"
                            else
                              text_node e.description
                            end
                          end
                        end
                      else
                        span "—", class: "cell-empty"
                      end
                    end
                  end
                end
              end
            end
            tfoot do
              tr class: "totals-row" do
                td do
                  strong "Total"
                end
                grid_columns.each do |col|
                  td do
                    all_events = grid.values.flat_map { |actions| actions[col] || [] }
                    case col
                    when "daily_visits"
                      total_unique = all_events.sum { |e| e.details[:unique].to_i }
                      total_visits = all_events.sum { |e| e.details[:visits].to_i }
                      span total_unique.to_s, class: "cell-num"
                      span " visitors ", class: "cell-label"
                      span "(#{total_visits} hits)", class: "cell-dim"
                    when "orders_summary"
                      total = all_events.sum { |e| e.details[:count].to_i }
                      span total.to_s, class: "cell-num"
                      span " orders", class: "cell-label"
                    when "credits_summary"
                      total_count = all_events.sum { |e| e.details[:count].to_i }
                      total_credits = all_events.sum { |e| e.details[:total_credits].to_f }
                      span total_count.to_s, class: "cell-num"
                      span " purchases ", class: "cell-label"
                      span "$#{'%.0f' % total_credits}", class: "cell-dim"
                    when "email_summary"
                      total_sent = all_events.sum { |e| e.details[:sent].to_i }
                      total_opened = all_events.sum { |e| e.details[:opened].to_i }
                      rate = total_sent > 0 ? (total_opened.to_f / total_sent * 100).round : 0
                      span total_sent.to_s, class: "cell-num"
                      span " sent", class: "cell-label"
                      rate_color = rate >= 50 ? "green" : rate >= 20 ? "orange" : "red"
                      span " · #{rate}% opened", style: "color: #{rate_color}", class: "cell-dim"
                    when "recurring_jobs_summary"
                      total = all_events.size
                      span total.to_s, class: "cell-num"
                      span " runs", class: "cell-label"
                    else
                      span "—", class: "cell-empty"
                    end
                  end
                end
              end
            end
          end
        end
      end
    end

    # Admin events
    admin_events = events.select { |e| e.category == "admin" }
    if admin_events.any?
      panel "Admin Events (#{admin_events.size})" do
        table_for admin_events do
          column("Time") { |e| e.timestamp&.strftime("%y-%m-%d %l:%M%P") }
          column("Action") { |e| e.action.to_s.humanize }
          column("Description") { |e| e.description }
        end
      end
    end

    # Claude Analyses
    if analyses.any?
      markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML, tables: true, fenced_code_blocks: true, autolink: true)
      panel "Claude Analyses" do
        analyses.each do |analysis|
          div class: "analysis-card" do
            div class: "analysis-header" do
              span analysis.created_at.strftime("%-m/%-d %l:%M%P").strip, class: "analysis-time"
              span "(#{analysis.trigger})", class: "analysis-meta"
              if analysis.user
                span "by #{analysis.user.name}", class: "analysis-meta"
              end
            end

            div class: "analysis-body" do
              text_node markdown.render(analysis.result).html_safe
            end

            div class: "analysis-footer" do
              cost = analysis.cost || AnomalyDetector.estimate_cost(analysis.input_tokens, analysis.output_tokens)
              span do
                span "Model", class: "meta-label"
                text_node(analysis.api_model || analysis.model_used)
              end
              span do
                span "Tokens", class: "meta-label"
                text_node "#{analysis.input_tokens.to_i.to_fs(:delimited)} in / #{analysis.output_tokens.to_i.to_fs(:delimited)} out"
              end
              if analysis.cache_creation_input_tokens.to_i > 0 || analysis.cache_read_input_tokens.to_i > 0
                span do
                  span "Cache", class: "meta-label"
                  parts = []
                  parts << "#{analysis.cache_creation_input_tokens.to_i.to_fs(:delimited)} write" if analysis.cache_creation_input_tokens.to_i > 0
                  parts << "#{analysis.cache_read_input_tokens.to_i.to_fs(:delimited)} read" if analysis.cache_read_input_tokens.to_i > 0
                  text_node parts.join(" / ")
                end
              end
              if analysis.stop_reason.present?
                span do
                  span "Stop", class: "meta-label"
                  text_node analysis.stop_reason
                end
              end
              span do
                span "Cost", class: "meta-label"
                text_node "$#{'%.4f' % cost}"
              end
            end
          end
        end
      end
    end
  end
end
