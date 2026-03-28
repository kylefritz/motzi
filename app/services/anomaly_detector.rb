# Analyzes weekly activity for anomalies using Claude.
# Prompt tuning: use `rake ai:eval` to test against historical weeks.
# See also: rake ai:full_prompt, rake ai:analysis, rake ai:history
class AnomalyDetector
  MODEL = "claude-opus-4-6"
  # Per-token pricing (dollars per token)
  INPUT_COST_PER_TOKEN = 5.0 / 1_000_000
  OUTPUT_COST_PER_TOKEN = 25.0 / 1_000_000

  def self.estimate_cost(input_tokens, output_tokens)
    (input_tokens * INPUT_COST_PER_TOKEN) + (output_tokens * OUTPUT_COST_PER_TOKEN)
  end

  def initialize(week_id, comparison_weeks: 4, &on_progress)
    @week_id = week_id
    @comparison_weeks = comparison_weeks
    @on_progress = on_progress || ->(_msg) {}
  end

  def analyze(trigger:, user: nil)
    result = run_analysis
    @on_progress.call("Analysis received, saving…")

    AnomalyAnalysis.create!(
      week_id: @week_id,
      result: result[:text],
      prompt_used: result[:prompt],
      model_used: MODEL,
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
    @on_progress.call("Sending to Claude (#{MODEL})…")
    response = call_claude(user_message)
    cost = self.class.estimate_cost(response[:input_tokens], response[:output_tokens])
    response.merge(prompt: user_message, cost: cost)
  end

  def system_prompt
    template = File.read(Rails.root.join("app/prompts/anomaly_detection.txt"))
    prompt = template.gsub("%{recurring_jobs}", recurring_jobs_summary)
    "Current date/time: #{Time.zone.now.strftime('%A, %B %-d, %Y at %-l:%M%P %Z')}\n\n#{prompt}"
  end

  def build_user_message
    parts = []
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
      end
    end

    parts.join("\n")
  end

  private

  def recurring_jobs_summary
    config = YAML.load_file(Rails.root.join("config/recurring.yml"))
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
    AnomalyAnalysis.order(created_at: :desc).limit(6).to_a.reverse
  end

  def call_claude(user_message)
    client = Anthropic::Client.new
    response = client.messages.create(
      model: MODEL,
      max_tokens: 4096,
      system_: system_prompt,
      messages: [{role: "user", content: user_message}]
    )

    text = response.content.filter_map { |block|
      block.text if block.respond_to?(:text)
    }.join("\n")

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
