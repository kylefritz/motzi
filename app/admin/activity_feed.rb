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
    weeks = (0..8).map { |i| (Time.zone.now - i.weeks).week_id }.uniq

    # Week header
    menu = Menu.find_by(week_id: week_id)
    div class: "activity-feed-header" do
      span(menu&.name || week_id, class: "week-id")
      span "#{week_id} · #{week_start.strftime('%A %-m/%-d')} — #{week_end.strftime('%A %-m/%-d/%Y')}", class: "date-range"
    end

    # Week navigation + controls on same line
    div class: "activity-toolbar" do
      div class: "activity-feed-nav" do
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
        end
      end
    end

    div id: "analysis-status", "data-week-id": week_id, class: "analysis-progress" do
      span id: "analysis-loader", class: "spinner"
      span id: "analysis-timer", class: "elapsed"
      span id: "analysis-message", class: "progress-msg"
    end

    # Weekly trends chart
    weeks = (0..8).map { |i| (Time.zone.now - i.weeks).week_id }
    trend_data = weeks.map do |wid|
      ws = Time.zone.from_week_id(wid)
      we = ws + 7.days
      menus = Menu.where(week_id: wid)
      order_count = menus.any? ? Order.where(menu_id: menus.select(:id)).count : 0
      email_count = menus.any? ? Ahoy::Message.where(menu_id: menus.select(:id)).count : 0
      visitor_count = Ahoy::Visit.where(started_at: ws..we).distinct.count(:visitor_token)
      { week: wid, orders: order_count, emails: email_count, visitors: visitor_count }
    end

    panel "Weekly Trends" do
      div style: "position: relative; width: 100%; height: 180px; min-width: 0; overflow: hidden;" do
        canvas id: "weekly-trends-chart"
      end
      script src: "https://cdn.jsdelivr.net/npm/chart.js@4/dist/chart.umd.min.js"
      script do
        text_node <<~JS.html_safe
          document.addEventListener('DOMContentLoaded', function() {
            var selectedWeek = #{week_id.to_json};
            var currentWeek = #{Time.zone.now.week_id.to_json};
            var chartConfig = {
              type: 'line',
              data: {
                labels: #{trend_data.map { |d| d[:week] }.to_json},
                datasets: [
                  {
                    label: 'Orders',
                    data: #{trend_data.map { |d| d[:orders] }.to_json},
                    borderColor: '#2E7D32',
                    backgroundColor: 'rgba(46, 125, 50, 0.1)',
                    borderWidth: 2,
                    tension: 0.3,
                    fill: true,
                    yAxisID: 'y_orders',
                    pointRadius: 3
                  },
                  {
                    label: 'Emails Sent',
                    data: #{trend_data.map { |d| d[:emails] }.to_json},
                    borderColor: '#D5482C',
                    backgroundColor: 'rgba(213, 72, 44, 0.1)',
                    borderWidth: 2,
                    tension: 0.3,
                    fill: true,
                    yAxisID: 'y_emails',
                    pointRadius: 3
                  },
                  {
                    label: 'Visitors',
                    data: #{trend_data.map { |d| d[:visitors] }.to_json},
                    borderColor: '#888888',
                    backgroundColor: 'rgba(136, 136, 136, 0.1)',
                    borderWidth: 2,
                    tension: 0.3,
                    fill: true,
                    yAxisID: 'y_emails',
                    pointRadius: 3
                  }
                ]
              },
              options: {
                responsive: true,
                maintainAspectRatio: false,
                interaction: { intersect: false, mode: 'index' },
                plugins: {
                  legend: { display: false }
                },
                scales: {
                  y_orders: { beginAtZero: true, position: 'left', grid: { color: 'rgba(0,0,0,0.05)' }, title: { display: true, text: 'Orders', color: '#2E7D32' } },
                  y_emails: { beginAtZero: true, position: 'right', grid: { drawOnChartArea: false }, title: { display: true, text: 'Emails / Visitors', color: '#888' } },
                  x: {
                    type: 'category',
                    grid: { display: false },
                    ticks: {
                      padding: 8,
                      font: function(context) {
                        var label = context.chart.data.labels[context.index];
                        if (label === currentWeek) return { weight: 'bold' };
                        return {};
                      },
                      color: function(context) {
                        var label = context.chart.data.labels[context.index];
                        return label === selectedWeek ? '#352C63' : '#666';
                      }
                    }
                  }
                },
                layout: { padding: { right: 16 } }
              }
            };

            chartConfig.plugins = [{
              afterDraw: function(chart) {
                var xAxis = chart.scales.x;
                var ctx = chart.ctx;
                var labels = chart.data.labels;
                labels.forEach(function(label, i) {
                  if (label === selectedWeek) {
                    var x = xAxis.getPixelForTick(i);
                    var y = xAxis.bottom - 2;
                    ctx.save();
                    ctx.strokeStyle = '#352C63';
                    ctx.lineWidth = 3;
                    ctx.beginPath();
                    ctx.moveTo(x - 20, y);
                    ctx.lineTo(x + 20, y);
                    ctx.stroke();
                    ctx.restore();
                  }
                });
              }
            }];
            var weekUrls = #{weeks.map { |wid| [wid, admin_activity_feed_path(week_id: wid)] }.to_h.to_json};
            var chart = new Chart(document.getElementById('weekly-trends-chart'), chartConfig);
            chart.canvas.addEventListener('click', function(e) {
              var xAxis = chart.scales.x;
              if (e.offsetY >= xAxis.top) {
                var labels = chart.data.labels;
                for (var i = 0; i < labels.length; i++) {
                  var x = xAxis.getPixelForTick(i);
                  if (Math.abs(e.offsetX - x) < 30) {
                    window.location.href = weekUrls[labels[i]];
                    break;
                  }
                }
              }
            });
            chart.canvas.addEventListener('mousemove', function(e) {
              var xAxis = chart.scales.x;
              if (e.offsetY >= xAxis.top) {
                var labels = chart.data.labels;
                for (var i = 0; i < labels.length; i++) {
                  var x = xAxis.getPixelForTick(i);
                  if (Math.abs(e.offsetX - x) < 30) {
                    chart.canvas.style.cursor = 'pointer';
                    return;
                  }
                }
              }
              chart.canvas.style.cursor = 'default';
            });
          });
        JS
      end
    end

    # Activity panel (email health + daily grid)
    grid = feed.daily_grid
    grid_columns = feed.grid_columns

    panel "Daily Stats" do
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
                                span " #{label}", class: "cell-label"
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

    # Email health cards
    if email_summary.any?
      panel "Email" do
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
