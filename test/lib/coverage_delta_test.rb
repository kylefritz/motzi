require "test_helper"
require "coverage_delta"

class CoverageDeltaTest < ActiveSupport::TestCase
  NAME_STATUS = <<~DIFF
    M\tapp/models/order.rb
    M\tapp/models/menu.rb
    M\tapp/models/user.rb
    A\tapp/services/well_tested.rb
    A\tapp/services/untested.rb
    A\tlib/half_tested.rb
    A\tlib/absolute_path.rb
    A\tapp/models/only_constants.rb
    A\tapp/models/never_loaded.rb
    A\ttest/models/something_test.rb
    A\tapp/javascript/thing.ts
    D\tapp/models/deleted.rb
    R087\tapp/models/old_name.rb\tapp/models/menu.rb
  DIFF

  def fixture_json(name)
    CoverageDelta.load(file_fixture("coverage_delta/#{name}.json"))
  end

  def delta(baseline: fixture_json("baseline"))
    CoverageDelta.new(baseline: baseline, current: fixture_json("current"),
                      changes: CoverageDelta.parse_name_status(NAME_STATUS))
  end

  test "parses git name-status, using the new path for renames" do
    changes = CoverageDelta.parse_name_status(NAME_STATUS)

    assert_equal %w[M app/models/order.rb], changes.first.to_a
    assert_equal %w[R app/models/menu.rb], changes.last.to_a
    assert changes.find { |c| c.path == "app/services/untested.rb" }.added?
  end

  test "lists changed files whose line or branch coverage dropped" do
    drops = delta.drops.index_by(&:path)

    assert_equal %w[app/models/menu.rb app/models/order.rb], drops.keys.sort
    assert_equal [ 90.0, 80.0 ], drops["app/models/order.rb"].to_a.values_at(1, 2), "line drop"
    assert_equal [ 100.0, 50.0 ], drops["app/models/menu.rb"].to_a.values_at(3, 4), "branch drop"
  end

  test "ignores improvements and files the PR didn't touch" do
    paths = delta.drops.map(&:path)

    refute_includes paths, "app/models/user.rb"      # improved
    refute_includes paths, "app/models/untouched.rb" # dropped, but not in the PR
  end

  test "gates new app/lib ruby files below 50% line coverage" do
    d = delta

    assert_equal %w[app/services/untested.rb lib/absolute_path.rb], d.failures.map(&:path).sort
    refute d.passed?
  end

  test "new-file gate: 50% passes, untracked or empty files and non-app files are skipped" do
    judged = delta.new_files.map(&:path)

    assert_includes judged, "lib/half_tested.rb"
    refute delta.new_files.find { |f| f.path == "lib/half_tested.rb" }.failing?
    refute_includes judged, "app/models/only_constants.rb" # no executable lines
    refute_includes judged, "app/models/never_loaded.rb"   # not in the report
    refute_includes judged, "test/models/something_test.rb"
  end

  test "passes when no new file is under the bar" do
    d = CoverageDelta.new(baseline: fixture_json("baseline"), current: fixture_json("current"),
                          changes: CoverageDelta.parse_name_status("M\tapp/models/order.rb\nA\tlib/half_tested.rb\n"))

    assert d.passed?
  end

  test "markdown shows totals, drops, and the new-file gate" do
    md = delta.to_markdown

    assert_includes md, "| Lines | 80.0% | 70.8% | -9.17 pp |"
    assert_includes md, "| Branches | 75.0% | 70.5% | -4.55 pp |"
    assert_includes md, "| `app/models/order.rb` | 90.0% → 80.0% | 80.0% → 80.0% |"
    assert_includes md, "| `app/models/menu.rb` | 70.0% → 70.0% | 100.0% → 50.0% |"
    assert_includes md, "| `app/services/untested.rb` | 25.0% (1/4) | **FAIL** |"
    assert_includes md, "| `app/services/well_tested.rb` | 75.0% (3/4) | ok |"
  end

  test "without a baseline it reports this run and still applies the new-file gate" do
    d = delta(baseline: nil)
    md = d.to_markdown

    refute d.baseline?
    assert_empty d.drops
    assert_includes md, "No master coverage baseline available"
    assert_includes md, "| Lines | – | 70.8% | – |"
    refute_includes md, "coverage dropped"
    assert_equal %w[app/services/untested.rb lib/absolute_path.rb], d.failures.map(&:path).sort
  end
end
