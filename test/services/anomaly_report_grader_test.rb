require "test_helper"

class AnomalyReportGraderTest < ActiveSupport::TestCase
  include WebMock::API

  REPORT = <<~TEXT
    **TL;DR:** Duplicate menu emails went out Saturday; everything else looks normal.

    Status: ⚠️ Warning

    ### 1. Duplicate menu emails (warning)
    - 973 menu emails sent vs ~500 normal.

    ### 2. R14 memory events on worker (warning)
    - worker dyno logged 40 R14 events this week.
  TEXT

  setup do
    @original_key = ENV["ANTHROPIC_API_KEY"]
    ENV["ANTHROPIC_API_KEY"] = "test-key"
  end

  teardown do
    @original_key ? ENV["ANTHROPIC_API_KEY"] = @original_key : ENV.delete("ANTHROPIC_API_KEY")
    WebMock.reset!
  end

  test "parses status deterministically without an API call" do
    assert_equal "warning", AnomalyReportGrader.parse_status(REPORT)
    assert_equal "healthy", AnomalyReportGrader.parse_status("Status: ✅ Healthy\nAll good.")
    assert_equal "problem", AnomalyReportGrader.parse_status("Overall status: 🔴 Problem")
    assert_equal "warning", AnomalyReportGrader.parse_status("no status line at all")
  end

  test "grades must_flag and must_not_flag via the judge" do
    judge_json = {
      must_flag: [ { index: 1, found: true, evidence: "973 menu emails sent" } ],
      must_not_flag: [ { index: 1, violated: true, evidence: "R14 memory events on worker (warning)" } ]
    }.to_json
    stub_request(:post, "https://api.anthropic.com/v1/messages")
      .to_return(status: 200, headers: { "Content-Type" => "application/json" }, body: {
        id: "msg_1", type: "message", role: "assistant", model: "claude-haiku-4-5",
        content: [ { type: "text", text: judge_json } ],
        stop_reason: "end_turn", usage: { input_tokens: 500, output_tokens: 80 }
      }.to_json)

    grade = AnomalyReportGrader.new(
      REPORT,
      must_flag: [ "duplicate menu email sends" ],
      must_not_flag: [ "R14 memory warnings raised as a finding" ]
    ).grade

    assert_equal "warning", grade[:status]
    assert_equal [], grade[:misses]
    assert_equal [ "R14 memory warnings raised as a finding" ], grade[:violations]
    assert_equal "973 menu emails sent", grade[:must_flag].first[:evidence]
  end

  test "reports misses when a required finding is absent" do
    judge_json = { must_flag: [ { index: 1, found: false, evidence: "" } ], must_not_flag: [] }.to_json
    stub_request(:post, "https://api.anthropic.com/v1/messages")
      .to_return(status: 200, headers: { "Content-Type" => "application/json" }, body: {
        id: "msg_1", type: "message", role: "assistant", model: "claude-haiku-4-5",
        content: [ { type: "text", text: judge_json } ],
        stop_reason: "end_turn", usage: { input_tokens: 400, output_tokens: 40 }
      }.to_json)

    grade = AnomalyReportGrader.new(REPORT, must_flag: [ "site outage on Tuesday" ]).grade

    assert_equal [ "site outage on Tuesday" ], grade[:misses]
    assert_equal [], grade[:violations]
  end

  test "handles a judge response wrapped in a code fence" do
    judge_json = "```json\n#{{ must_flag: [], must_not_flag: [ { index: 1, violated: false, evidence: "" } ] }.to_json}\n```"
    stub_request(:post, "https://api.anthropic.com/v1/messages")
      .to_return(status: 200, headers: { "Content-Type" => "application/json" }, body: {
        id: "msg_1", type: "message", role: "assistant", model: "claude-haiku-4-5",
        content: [ { type: "text", text: judge_json } ],
        stop_reason: "end_turn", usage: { input_tokens: 400, output_tokens: 40 }
      }.to_json)

    grade = AnomalyReportGrader.new(REPORT, must_not_flag: [ "hourly reminder job runs" ]).grade

    assert_equal [], grade[:violations]
  end

  test "retries once when the judge returns malformed JSON" do
    bad = { content: [ { type: "text", text: '{"must_flag": [{"index": 1, "found": true, "evidence": "broken "quote' } ],
            id: "msg_1", type: "message", role: "assistant", model: "claude-haiku-4-5",
            stop_reason: "max_tokens", usage: { input_tokens: 400, output_tokens: 40 } }.to_json
    good = { content: [ { type: "text", text: { must_flag: [ { index: 1, found: true, evidence: "ok" } ], must_not_flag: [] }.to_json } ],
             id: "msg_2", type: "message", role: "assistant", model: "claude-haiku-4-5",
             stop_reason: "end_turn", usage: { input_tokens: 400, output_tokens: 40 } }.to_json
    stub_request(:post, "https://api.anthropic.com/v1/messages")
      .to_return({ status: 200, headers: { "Content-Type" => "application/json" }, body: bad },
                 { status: 200, headers: { "Content-Type" => "application/json" }, body: good })

    grade = AnomalyReportGrader.new(REPORT, must_flag: [ "duplicate menu email sends" ]).grade

    assert_equal [], grade[:misses]
  end

  test "skips the judge call entirely when there is nothing to grade" do
    grade = AnomalyReportGrader.new(REPORT).grade

    assert_equal "warning", grade[:status]
    assert_equal [], grade[:misses]
    assert_equal [], grade[:violations]
  end
end
