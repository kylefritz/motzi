require "test_helper"

# Pure comparison logic for the `rake ai:eval` regression gate. No API calls:
# re-judging is injected as a lambda.
class AnomalyEvalBaselineTest < ActiveSupport::TestCase
  setup do
    @baseline = AnomalyEvalBaseline.load(file_fixture("anomaly_eval/baseline.yml"))
    @scorecard = AnomalyEvalBaseline.load_scorecard(file_fixture("anomaly_eval/scorecard.yml"))
  end

  test "load returns nil when no baseline has been recorded" do
    assert_nil AnomalyEvalBaseline.load(Rails.root.join("tmp/does_not_exist.yml"))
  end

  test "load_scorecard reads the symbol-keyed rake output" do
    assert_equal "26w01", @scorecard.first[:week_id]
  end

  test "classifies weeks as regressed, improved, unchanged, new, and not run" do
    comparison = AnomalyEvalBaseline.new(@baseline).compare(@scorecard)

    assert_equal %w[26w02 26w04 26w05], comparison.regressed.map(&:week_id)
    assert_equal %w[26w03], comparison.improved.map(&:week_id)
    assert_equal %w[26w01], comparison.unchanged
    assert_equal %w[26w07], comparison.new_weeks
    assert_equal %w[26w06], comparison.not_run
    assert comparison.regressed?
  end

  test "reports what regressed and what improved" do
    comparison = AnomalyEvalBaseline.new(@baseline).compare(@scorecard)
    by_week = (comparison.regressed + comparison.improved).index_by(&:week_id)

    assert_equal [ "status: expected warning, got healthy (baseline got warning)" ], by_week["26w02"].regressions
    assert_equal [ "must_not_flag now violated: R14 memory warnings on worker" ], by_week["26w04"].regressions
    assert_equal [ "status: expected healthy, got ERROR (baseline got healthy)" ], by_week["26w05"].regressions
    assert_equal [
      "status: now problem as expected (baseline got warning)",
      "must_flag now caught: orders created with zero items"
    ], by_week["26w03"].improvements
  end

  test "only findings-only regressions are re-judged" do
    rejudged = []
    rejudge = ->(row) { rejudged << row[:week_id]; row }

    AnomalyEvalBaseline.new(@baseline).compare(@scorecard, rejudge: rejudge)

    assert_equal %w[26w04], rejudged, "status and ERROR regressions are deterministic and must not be re-judged"
  end

  test "a judge regression that clears on re-judge is flaky, not a failure" do
    rejudge = lambda do |row|
      row.merge(violations: [], must_not_flag_detail: row[:must_not_flag_detail].map { |d| d.merge(violated: false) })
    end

    comparison = AnomalyEvalBaseline.new(@baseline).compare(@scorecard, rejudge: rejudge)

    assert_equal %w[26w04], comparison.flaky.map(&:week_id)
    assert_includes comparison.unchanged, "26w04"
    assert_equal %w[26w02 26w05], comparison.regressed.map(&:week_id)
  end

  test "a judge regression that persists on re-judge still fails" do
    comparison = AnomalyEvalBaseline.new(@baseline).compare(@scorecard, rejudge: ->(row) { row })

    regressed = comparison.regressed.find { |d| d.week_id == "26w04" }
    assert regressed.rejudged
    assert_empty comparison.flaky
  end

  test "an unchanged known failure is not a regression" do
    row = @scorecard.find { |r| r[:week_id] == "26w03" }.merge(
      actual: "warning", status_ok: false,
      must_flag_detail: [
        { item: "orders created with zero items", found: false },
        { item: "checkout errors in error_events", found: true }
      ]
    )

    comparison = AnomalyEvalBaseline.new(@baseline).compare([ row ])

    assert_equal %w[26w03], comparison.unchanged
    refute comparison.regressed?
  end

  test "a different item regressing in an already-failing week still fails" do
    row = @scorecard.find { |r| r[:week_id] == "26w03" }.merge(
      actual: "warning", status_ok: false,
      must_flag_detail: [
        { item: "orders created with zero items", found: false },
        { item: "checkout errors in error_events", found: false }
      ]
    )

    comparison = AnomalyEvalBaseline.new(@baseline).compare([ row ])

    assert_equal [ "must_flag now missed: checkout errors in error_events" ], comparison.regressed.first.regressions
  end

  test "items added to expectations after the baseline cannot regress" do
    row = @scorecard.find { |r| r[:week_id] == "26w01" }.merge(
      must_flag_detail: [ { item: "a brand new label", found: false } ]
    )

    comparison = AnomalyEvalBaseline.new(@baseline).compare([ row ])

    assert_equal %w[26w01], comparison.unchanged
  end

  test "an empty baseline treats every week as new" do
    comparison = AnomalyEvalBaseline.new(nil).compare(@scorecard)

    assert_equal @scorecard.map { |r| r[:week_id] }.sort, comparison.new_weeks
    refute comparison.regressed?
  end

  test "merge refreshes run weeks, keeps the rest, skips errors, and drops unlabeled weeks" do
    expectations = %w[26w01 26w02 26w03 26w04 26w05 26w07].index_with { {} }

    weeks, skipped = AnomalyEvalBaseline.merge(@baseline, @scorecard, expectations: expectations)

    assert_equal %w[26w05], skipped
    assert_equal @baseline["26w05"], weeks["26w05"], "errored week keeps its previous entry"
    assert_equal "healthy", weeks["26w02"]["actual"]
    assert_equal({ "R14 memory warnings on worker" => "violated" }, weeks["26w04"]["must_not_flag"])
    assert weeks.key?("26w07")
    refute weeks.key?("26w06"), "weeks no longer in expectations are dropped"
  end

  test "write then load round-trips" do
    path = Rails.root.join("tmp/anomaly_eval_baseline_test_#{Process.pid}.yml")
    weeks, = AnomalyEvalBaseline.merge(nil, @scorecard, expectations: @scorecard.to_h { |r| [ r[:week_id], {} ] })
    AnomalyEvalBaseline.write(weeks, meta: { "source" => "fixture" }, path: path)

    assert_equal weeks, AnomalyEvalBaseline.load(path)
  ensure
    FileUtils.rm_f(path)
  end

  test "format lists regressed, improved, flaky, and new weeks" do
    rejudge = ->(row) { row.merge(violations: [], must_not_flag_detail: []) }
    output = AnomalyEvalBaseline.format(AnomalyEvalBaseline.new(@baseline).compare(@scorecard, rejudge: rejudge))

    assert_match(/REGRESSED  26w02/, output)
    assert_match(/IMPROVED   26w03/, output)
    assert_match(/FLAKY      26w04/, output)
    assert_match(/NEW        26w07/, output)
    assert_match(/Regressed: 2  Improved: 1  Unchanged: 2  Flaky: 1  New: 1  Not run: 1/, output)
  end
end
