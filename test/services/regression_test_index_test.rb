require "test_helper"

class RegressionTestIndexTest < ActiveSupport::TestCase
  setup do
    ErrorEvent.delete_all
    @dir = Pathname(Dir.mktmpdir)
    @tests = @dir.join("test").tap(&:mkpath)
  end

  teardown { FileUtils.remove_entry(@dir) }

  def event(fingerprint, resolved: true, occurred_at: 1.day.ago)
    ErrorEvent.create!(fingerprint:, source: "server", error_class: "NameError",
      message: "uninitialized constant OpenStruct\nmore detail", occurred_at:,
      resolved_at: (resolved ? Time.current : nil))
  end

  def write_test(name, body)
    @tests.join(name).write(body)
  end

  def index = RegressionTestIndex.new(root: @tests)

  test "finds single and comma-separated citations with file and line" do
    write_test("a_test.rb", "# nothing here\n# Regression for error_events #12\n")
    write_test("b_test.rb", "# error_events #7, #9 (menu copy)\n")

    refs = index.references
    assert_equal [ 7, 9, 12 ], refs.keys.sort
    assert_equal [ "test/a_test.rb", 2 ], refs[12].first.to_a.drop(1)
  end

  test "a group counts as tested when any of its events is cited" do
    first = event("dup")
    event("dup")
    write_test("a_test.rb", "# error_events ##{first.id}\n")

    assert_empty index.untested_resolved
    assert_equal 1, index.for_fingerprint("dup").size
  end

  test "lists resolved, uncited groups newest first with a one-line message" do
    older = event("older")
    newer = event("newer")

    untested = index.untested_resolved
    assert_equal [ newer.id, older.id ], untested.map { |g| g[:latest_id] }
    assert_equal "uninitialized constant OpenStruct", untested.first[:message]
  end

  test "ignores open errors and ones resolved outside the window" do
    event("open", resolved: false)
    event("ancient", occurred_at: 200.days.ago)

    assert_empty index.untested_resolved(since: 90.days.ago)
  end

  test "the real test suite cites the errors fixed after the OpenStruct incident" do
    ids = RegressionTestIndex.new.references.keys
    assert_includes ids, 2312 # OpenStruct NameError on /admin/activity_feed
    assert_includes ids, 2218 # AmbiguousColumn on Item's default scope
  end
end
