require "test_helper"

class TestDbLockTest < ActiveSupport::TestCase
  # Named per test, not per class: a class-level constant is evaluated before
  # parallelize forks, so every worker shared one lock file and the two tests
  # blocked on and deleted each other's locks.
  setup { @database = "motzi_test_lock_check_#{Process.pid}_#{SecureRandom.hex(4)}" }

  teardown do
    FileUtils.rm_f(TestDbLock.path(@database))
    FileUtils.rm_f(TestDbLock.path("#{@database}_other"))
  end

  test "a second run on the same database has to wait" do
    held = TestDbLock.acquire!(@database)

    # flock is per open file, so a second handle in this process contends
    # exactly like another test run would.
    other = File.open(TestDbLock.path(@database))
    refute other.flock(File::LOCK_EX | File::LOCK_NB), "lock should be held"

    held.close
    assert other.flock(File::LOCK_EX | File::LOCK_NB), "lock should be free once the holder exits"
  ensure
    other&.close
  end

  test "different databases don't block each other" do
    held = TestDbLock.acquire!(@database)
    other = TestDbLock.acquire!("#{@database}_other", out: StringIO.new)
    assert other
  ensure
    held&.close
    other&.close
  end
end
