require "test_helper"
require "tmpdir"

class WorktreeEnvTest < ActiveSupport::TestCase
  test "a .git file marks a linked worktree" do
    Dir.mktmpdir do |dir|
      root = File.join(dir, "motzi")
      Dir.mkdir(root)
      File.write(File.join(root, ".git"), "gitdir: /somewhere/.git/worktrees/motzi\n")

      assert WorktreeEnv.worktree?(root)
    end
  end

  test "a main checkout with a .git directory is not a worktree" do
    Dir.mktmpdir do |dir|
      root = File.join(dir, "motzi")
      FileUtils.mkdir_p(File.join(root, ".git"))

      assert_not WorktreeEnv.worktree?(root)
      assert_nil WorktreeEnv.test_database_name(root)
    end
  end

  test "worktree directories are detected by path" do
    assert WorktreeEnv.worktree?("/Users/kyle/code/motzi/.worktrees/fix-thing")
    assert WorktreeEnv.worktree?("/Users/kyle/code/motzi/.claude/worktrees/agent-abc123")
    assert_not WorktreeEnv.worktree?("/Users/kyle/code/motzi")
    assert_not WorktreeEnv.worktree?("/home/runner/work/motzi/motzi")
  end

  test "derives the test database from the worktree directory name" do
    assert_equal "motzi_test_agent_abc123",
      WorktreeEnv.test_database_name("/code/motzi/.claude/worktrees/agent-abc123")
    assert_equal "motzi_test_fix_378_worktree_defaults",
      WorktreeEnv.test_database_name("/code/motzi/.worktrees/Fix.378--Worktree Defaults")
  end

  test "sanitizes to postgres identifier characters" do
    assert_equal "dx_378_worktree", WorktreeEnv.sanitize("-dx/378.worktree-")
    assert_equal "worktree", WorktreeEnv.sanitize("---")
  end

  test "long names fit postgres's 63 byte limit with room for the parallel worker suffix" do
    long = "/code/motzi/.worktrees/#{"really-long-branch-name-" * 5}"
    name = WorktreeEnv.test_database_name(long)
    other = WorktreeEnv.test_database_name("#{long}x")

    assert_operator "#{name}_123".bytesize, :<=, 63
    assert_match(/\Amotzi_test_really_long_branch_name_.*_\h{8}\z/, name)
    assert_not_equal name, other
  end

  test "the test database follows TEST_DATABASE, then the worktree default, then motzi_test" do
    expected = ENV["TEST_DATABASE"] || WorktreeEnv.test_database_name || "motzi_test"

    assert_match(/\A#{Regexp.escape(expected)}(_\d+)?\z/, ActiveRecord::Base.connection.current_database)
  end
end
