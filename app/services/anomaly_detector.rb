class AnomalyDetector
  MODEL = "claude-opus-4-6"

  def initialize(week_id, comparison_weeks: 4)
    @week_id = week_id
    @comparison_weeks = comparison_weeks
  end

  def analyze(trigger:, user: nil)
    user_message = build_user_message
    response = call_claude(user_message)

    AnomalyAnalysis.create!(
      week_id: @week_id,
      result: response[:text],
      prompt_used: user_message,
      model_used: MODEL,
      input_tokens: response[:input_tokens],
      output_tokens: response[:output_tokens],
      trigger: trigger,
      user: user
    )
  end

  private

  def build_user_message
    parts = []
    parts << "## Current Week: #{@week_id} (analyze this week for anomalies)"
    parts << ""
    parts << ActivityFeed.new(@week_id).to_text(verbose: true)
    parts << ""

    prior_week_ids.each do |wid|
      parts << "## Comparison Week: #{wid}"
      parts << ""
      parts << ActivityFeed.new(wid).to_text(verbose: false)
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

    {
      text: text,
      input_tokens: response.usage.input_tokens,
      output_tokens: response.usage.output_tokens
    }
  end
end
