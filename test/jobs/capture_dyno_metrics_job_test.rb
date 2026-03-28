require "test_helper"
require "webmock/minitest"

class CaptureDynoMetricsJobTest < ActiveSupport::TestCase
  SAMPLE_LOGS = File.read(Rails.root.join("test/fixtures/files/heroku_memory_logs.txt"))

  test "parse_log_lines extracts memory samples grouped by dyno" do
    job = CaptureDynoMetricsJob.new
    result = job.send(:parse_log_lines, SAMPLE_LOGS)

    assert_equal 2, result.size
    assert_includes result.keys, "web.1"
    assert_includes result.keys, "worker.1"

    web = result["web.1"]
    assert_in_delta 958.8, web[:memory_total], 0.01
    assert_in_delta 750.0, web[:memory_rss], 0.01
    assert_in_delta 196.0, web[:memory_swap], 0.01
    assert_in_delta 512.0, web[:memory_quota], 0.01
    assert_equal 6, web[:r14_count]

    worker = result["worker.1"]
    assert_in_delta 200.0, worker[:memory_total], 0.01
    assert_equal 0, worker[:r14_count]
  end

  test "parse_log_lines returns empty hash for logs without memory samples" do
    job = CaptureDynoMetricsJob.new
    result = job.send(:parse_log_lines, "2026-03-28T16:33:03+00:00 app[web.1]: some random log line\n")
    assert_equal({}, result)
  end

  test "perform creates DynoMetric records" do
    stub_heroku_api(SAMPLE_LOGS) do
      assert_difference "DynoMetric.count", 2 do
        CaptureDynoMetricsJob.perform_now
      end
    end

    web_metric = DynoMetric.find_by(dyno: "web.1")
    assert_in_delta 958.8, web_metric.memory_total, 0.01
    assert_equal 6, web_metric.r14_count
  end

  test "perform logs warning and exits when HEROKU_API_KEY missing" do
    original = ENV["HEROKU_API_KEY"]
    ENV.delete("HEROKU_API_KEY")

    assert_no_difference "DynoMetric.count" do
      CaptureDynoMetricsJob.perform_now
    end
  ensure
    ENV["HEROKU_API_KEY"] = original
  end

  private

  def stub_heroku_api(log_content)
    log_session_response = {"logplex_url" => "https://example.com/logs"}.to_json

    session_stub = stub_request(:post, "https://api.heroku.com/apps/motzibread/log-sessions")
      .to_return(status: 200, body: log_session_response, headers: {"Content-Type" => "application/json"})

    logs_stub = stub_request(:get, "https://example.com/logs")
      .to_return(status: 200, body: log_content)

    yield

    assert_requested session_stub
    assert_requested logs_stub
  end
end
