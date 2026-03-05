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
    user_message = build_user_message
    @on_progress.call("Sending to Claude (#{MODEL})…")
    response = call_claude(user_message)
    @on_progress.call("Analysis received, saving…")

    AnomalyAnalysis.create!(
      week_id: @week_id,
      result: response[:text],
      prompt_used: user_message,
      model_used: MODEL,
      api_model: response[:model],
      input_tokens: response[:input_tokens],
      output_tokens: response[:output_tokens],
      cache_creation_input_tokens: response[:cache_creation_input_tokens],
      cache_read_input_tokens: response[:cache_read_input_tokens],
      stop_reason: response[:stop_reason],
      trigger: trigger,
      user: user
    )
  end

  private

  def build_user_message
    parts = []
    @on_progress.call("Building feed for #{@week_id} (verbose)…")
    current_feed = ActivityFeed.new(@week_id)
    current_events = current_feed.verbose_events
    @on_progress.call("#{@week_id}: #{current_events.size} events collected")
    parts << "## Current Week (analyze this week for anomalies):"
    parts << current_feed.to_text(verbose: true)
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

    parts.join("\n")
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

  def call_claude(user_message)
    system_prompt = File.read(Rails.root.join("app/prompts/anomaly_detection.txt"))
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
