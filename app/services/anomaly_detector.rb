# Analyzes weekly activity for anomalies using Claude.
# Prompt tuning: use `rake ai:eval` to test against historical weeks.
# See also: rake ai:full_prompt, rake ai:analysis, rake ai:history
class AnomalyDetector
  DEFAULT_MODEL = "claude-sonnet-5-5"

  # The models an admin can pick, with pricing in dollars per million tokens.
  # Haiku 5.5 bills a higher rate once the prompt passes 100K tokens.
  MODEL_PRICING = {
    "claude-opus-5-5"   => { input: 4.0, output: 20.0, label: "Opus 5.5" },
    "claude-sonnet-5-5" => { input: 2.0, output: 10.0, label: "Sonnet 5.5" },
    "claude-haiku-5-5"  => { input: 0.10, output: 0.50, label: "Haiku 5.5",
                             long_prompt: { over: 100_000, input: 0.50, output: 2.50 } }
  }.freeze

  # Models this app used to run. Old analyses still name them (so their label
  # and cost keep working), and a stored setting that names one moves to its
  # successor.
  RETIRED_MODELS = {
    "claude-opus-4-6"   => { input: 5.0, output: 25.0, label: "Opus 4.6", successor: "claude-opus-5-5" },
    "claude-sonnet-4-6" => { input: 3.0, output: 15.0, label: "Sonnet 4.6", successor: "claude-sonnet-5-5" },
    "claude-haiku-4-5"  => { input: 1.0, output: 5.0, label: "Haiku 4.5", successor: "claude-haiku-5-5" }
  }.freeze

  # The model declined to write the report, or returned no text.
  class NoReport < StandardError; end

  def self.model
    chosen = Setting.anomaly_model.presence || DEFAULT_MODEL
    RETIRED_MODELS.dig(chosen, :successor) || chosen
  end

  def self.model_label
    label_for(model)
  end

  def self.label_for(model_id)
    (MODEL_PRICING[model_id] || RETIRED_MODELS[model_id])&.fetch(:label) || model_id
  end

  def self.estimate_cost(input_tokens, output_tokens, model_id = nil)
    pricing = MODEL_PRICING[model_id || model] || RETIRED_MODELS[model_id] || MODEL_PRICING[DEFAULT_MODEL]
    long = pricing[:long_prompt]
    pricing = long if long && input_tokens > long[:over]
    (input_tokens * pricing[:input] / 1_000_000) + (output_tokens * pricing[:output] / 1_000_000)
  end

  # analyses_before: timestamp cutoff for the prior-analyses context. Used by
  # rake ai:eval so a historical week's prompt only sees analyses that existed
  # at the time, never reports from its future.
  def initialize(week_id, comparison_weeks: 4, analyses_before: nil, &on_progress)
    @week_id = week_id
    @comparison_weeks = comparison_weeks
    @analyses_before = analyses_before
    @on_progress = on_progress || ->(_msg) { }
  end

  def analyze(trigger:, user: nil)
    result = run_analysis
    @on_progress.call("Analysis received, saving…")

    AnomalyAnalysis.create!(
      week_id: @week_id,
      result: result[:text],
      prompt_used: result[:prompt],
      model_used: self.class.model,
      api_model: result[:model],
      input_tokens: result[:input_tokens],
      output_tokens: result[:output_tokens],
      cache_creation_input_tokens: result[:cache_creation_input_tokens],
      cache_read_input_tokens: result[:cache_read_input_tokens],
      stop_reason: result[:stop_reason],
      cost_cents: (result[:cost] * 100).round,
      trigger: trigger,
      user: user
    )
  end

  # Run analysis and return results without persisting to the database.
  def run_analysis
    user_message = build_user_message
    @on_progress.call("Sending to Claude (#{self.class.model_label})…")
    response = call_claude(user_message)
    cost = self.class.estimate_cost(response[:input_tokens], response[:output_tokens], self.class.model)
    response.merge(prompt: user_message, cost: cost)
  end

  def system_prompt
    template = File.read(Rails.root.join("app/prompts/anomaly_detection.txt"))
    prompt = template.gsub("%{recurring_jobs}", recurring_jobs_summary)
    "Current date/time: #{Time.zone.now.strftime('%A, %B %-d, %Y at %-l:%M%P %Z')}\n\n#{prompt}"
  end

  def build_user_message
    parts = []

    probe = UptimeProbe.check
    if probe
      timestamp = probe[:checked_at].strftime("%-l:%M%P")
      parts << "## Uptime Probe"
      parts << if probe[:status]
        "GET #{probe[:url]} responded #{probe[:status]} in #{probe[:latency_ms]}ms at #{timestamp} — the site was reachable when this report ran."
      else
        "GET #{probe[:url]} FAILED at #{timestamp}: #{probe[:error]}"
      end
      parts << ""
    end

    @on_progress.call("Building feed for #{@week_id} (verbose)…")
    current_feed = ActivityFeed.new(@week_id)
    current_events = current_feed.verbose_events
    @on_progress.call("#{@week_id}: #{current_events.size} events collected")
    parts << "## Current Week (analyze this week for anomalies):"
    parts << ""
    parts << "### Summary of Events:"
    parts << current_feed.to_text(verbose: false)
    parts << ""
    parts << "### Detailed Events:"
    parts << current_feed.to_text(verbose: true, header: false)
    parts << ""

    prior_week_ids.each do |wid|
      @on_progress.call("Building feed for #{wid}…")
      comparison_feed = ActivityFeed.new(wid)
      event_count = comparison_feed.summary.size
      @on_progress.call("#{wid}: #{event_count} events collected")
      parts << "## Comparison Week: #{wid}"
      parts << comparison_feed.to_text(verbose: false)
      parts << ""
    end

    prior_analyses = recent_analyses
    if prior_analyses.any?
      @on_progress.call("Including #{prior_analyses.size} prior analyses for context…")
      parts << "---"
      parts << "## Prior Analyses (for context — avoid repeating resolved findings)"
      prior_analyses.each do |a|
        parts << ""
        parts << "### #{a.week_id} — #{a.created_at.strftime('%-m/%-d/%Y')} (#{a.trigger})"
        parts << a.result

        if a.replies.any?
          parts << ""
          parts << "**Operator replies:**"
          a.replies.each do |r|
            who = r.author_name.presence || r.author_email
            parts << "- #{who} (#{r.created_at.strftime('%-m/%-d')}): #{r.body}"
          end
        end
      end
    end

    parts.join("\n")
  end

  private

  def recurring_jobs_summary
    config = YAML.load_file(Rails.root.join("config/recurring.yml"), aliases: true)
    jobs = config.fetch("production", {})
    jobs.map { |key, cfg|
      job_class = cfg["class"] || "(inline command)"
      "- **#{key}**: #{cfg['schedule']} (#{job_class})"
    }.join("\n")
  end

  def prior_week_ids
    ids = []
    t = Time.zone.from_week_id(@week_id)
    @comparison_weeks.times do
      t -= 1.week
      ids << t.week_id
    end
    ids
  end

  def recent_analyses
    scope = AnomalyAnalysis.includes(:replies).order(created_at: :desc)
    scope = scope.where(created_at: ...@analyses_before) if @analyses_before
    scope.limit(6).to_a.reverse
  end

  def call_claude(user_message)
    client = Anthropic::Client.new
    # The 5.5 models think before answering and that thinking counts toward
    # max_tokens, so the cap leaves room for it on top of a ~1K-token report.
    response = client.messages.create(
      model: self.class.model,
      max_tokens: 16_000,
      output_config: { effort: :high },
      system_: system_prompt,
      messages: [ { role: "user", content: user_message } ]
    )

    text = response.content.filter_map { |block|
      block.text if block.respond_to?(:text)
    }.join("\n")

    # A refusal is an HTTP 200 with no report in it. Fail the job (it lands in
    # error tracking) rather than email an empty analysis.
    if response.stop_reason.to_s == "refusal" || text.blank?
      raise NoReport, "#{self.class.model} returned no report (stop_reason: #{response.stop_reason})"
    end

    usage = response.usage
    {
      text: text,
      model: response.model,
      input_tokens: usage.input_tokens,
      output_tokens: usage.output_tokens,
      cache_creation_input_tokens: usage.respond_to?(:cache_creation_input_tokens) ? usage.cache_creation_input_tokens : 0,
      cache_read_input_tokens: usage.respond_to?(:cache_read_input_tokens) ? usage.cache_read_input_tokens : 0,
      stop_reason: response.stop_reason
    }
  end
end
