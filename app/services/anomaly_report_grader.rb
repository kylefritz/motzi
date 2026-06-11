# Grades an anomaly report against ground-truth expectations for `rake ai:eval`.
#
# Two layers:
#   - status: parsed deterministically from the "Status:" line (same rules as
#     AnomalyAnalysis#parse_status_from_result)
#   - findings: an LLM judge checks that each `must_flag` item is actually
#     reported and that no `must_not_flag` noise pattern is raised as an issue
#
# The judge is only called when there are findings to grade.
class AnomalyReportGrader
  DEFAULT_JUDGE_MODEL = "claude-haiku-4-5"

  def self.judge_model
    ENV["ANOMALY_JUDGE_MODEL"].presence || DEFAULT_JUDGE_MODEL
  end

  def self.parse_status(text)
    status_line = text[/(?:overall )?status:.*$/i]
    return "warning" unless status_line

    case status_line
    when /problem/i then "problem"
    when /warning/i then "warning"
    else "healthy"
    end
  end

  def initialize(report_text, must_flag: [], must_not_flag: [])
    @report_text = report_text
    @must_flag = Array(must_flag)
    @must_not_flag = Array(must_not_flag)
  end

  def grade
    result = {
      status: self.class.parse_status(@report_text),
      must_flag: [],
      must_not_flag: [],
      misses: [],
      violations: []
    }
    return result if @must_flag.empty? && @must_not_flag.empty?

    verdict = call_judge

    result[:must_flag] = @must_flag.each_with_index.map do |item, i|
      row = verdict["must_flag"].to_a.find { |r| r["index"] == i + 1 } || {}
      { item: item, found: !!row["found"], evidence: row["evidence"].to_s }
    end
    result[:must_not_flag] = @must_not_flag.each_with_index.map do |item, i|
      row = verdict["must_not_flag"].to_a.find { |r| r["index"] == i + 1 } || {}
      { item: item, violated: !!row["violated"], evidence: row["evidence"].to_s }
    end
    result[:misses] = result[:must_flag].reject { |r| r[:found] }.map { |r| r[:item] }
    result[:violations] = result[:must_not_flag].select { |r| r[:violated] }.map { |r| r[:item] }
    result
  end

  private

  def call_judge
    client = Anthropic::Client.new
    response = client.messages.create(
      model: self.class.judge_model,
      max_tokens: 1500,
      system_: judge_system_prompt,
      messages: [{ role: "user", content: judge_user_message }]
    )
    text = response.content.filter_map { |block| block.text if block.respond_to?(:text) }.join("\n")
    parse_judge_json(text)
  end

  def judge_system_prompt
    <<~PROMPT
      You grade weekly operations reports produced by an AI analyst for a small bakery.
      You will receive the report plus two checklists. Judge only what the report says.

      REQUIRED findings: decide whether the report actually reports each one as an issue
      or notable finding (a passing mention buried in raw data does not count).

      FORBIDDEN findings: decide whether the report raises each one as a finding, warning,
      problem, or action item. Mentioning it as normal/expected/info-only context is NOT
      a violation.

      Respond with ONLY a JSON object, no prose:
      {"must_flag": [{"index": 1, "found": true, "evidence": "<short quote from the report>"}],
       "must_not_flag": [{"index": 1, "violated": false, "evidence": ""}]}
      Use 1-based indexes matching the checklists. Include every checklist item exactly once.
    PROMPT
  end

  def judge_user_message
    parts = ["<report>", @report_text, "</report>", ""]
    if @must_flag.any?
      parts << "REQUIRED findings:"
      @must_flag.each_with_index { |item, i| parts << "#{i + 1}. #{item}" }
      parts << ""
    end
    if @must_not_flag.any?
      parts << "FORBIDDEN findings:"
      @must_not_flag.each_with_index { |item, i| parts << "#{i + 1}. #{item}" }
    end
    parts.join("\n")
  end

  def parse_judge_json(text)
    json = text[/\{.*\}/m]
    raise "Judge returned no JSON: #{text.truncate(200)}" unless json

    JSON.parse(json)
  end
end
