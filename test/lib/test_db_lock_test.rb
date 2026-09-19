require "test_helper"

class TestDbLockTest < ActiveSupport::TestCase
  DATABASE = "motzi_test_lock_check_#{Process.pid}".freeze

  teardown { File.delete(TestDbLock.path(DATABASE)) if File.exist?(TestDbLock.path(DATABASE)) }

  test "a second run on the same database has to wait" do
    held = TestDbLock.acquire!(DATABASE)

    # flock is per open file, so a second handle in this process contends
    # exactly like another test run would.
    other = File.open(TestDbLock.path(DATABASE))
    refute other.flock(File::LOCK_EX | File::LOCK_NB), "lock should be held"

    held.close
    assert other.flock(File::LOCK_EX | File::LOCK_NB), "lock should be free once the holder exits"
  ensure
    other&.close
  end

  test "different databases don't block each other" do
    held = TestDbLock.acquire!(DATABASE)
    other = TestDbLock.acquire!("#{DATABASE}_other", out: StringIO.new)
    assert other
  ensure
    held&.close
    other&.close
    File.delete(TestDbLock.path("#{DATABASE}_other")) if File.exist?(TestDbLock.path("#{DATABASE}_other"))
  end
end
