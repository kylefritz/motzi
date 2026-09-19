# Serializes test runs that share a database. Two suites on one DB (two Claude
# sessions in the same worktree, or a run while another is still going) load
# fixtures over each other and fail with spurious RecordNotFound errors.
#
# The lock is an flock on a file keyed by database name, held for the life of
# the process. Parallel workers are forked and inherit the open file, so the
# lock covers the whole run and is released when every process exits.
module TestDbLock
  module_function

  def path(database)
    File.join(Dir.tmpdir, "motzi-test-db-#{database}.lock")
  end

  def acquire!(database, out: $stderr)
    file = File.open(path(database), File::RDWR | File::CREAT, 0o644)
    unless file.flock(File::LOCK_EX | File::LOCK_NB)
      out.puts "Another test run is using #{database}; waiting for it to finish..."
      file.flock(File::LOCK_EX)
    end
    file
  end
end
