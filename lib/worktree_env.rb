# frozen_string_literal: true

require "digest"

# Worktree-aware defaults, so running tests from a git worktree (.worktrees/ or
# .claude/worktrees/) needs no tribal-knowledge env vars:
#
# * each worktree gets its own test database (concurrent suites sharing
#   motzi_test clobber each other's fixtures), and
# * Spring is disabled (it cross-loads apps between worktrees and hangs).
#
# The main checkout and CI are never worktrees, so they keep motzi_test and
# Spring. Plain Ruby with no gem dependencies: bin/rails and bin/rake load this
# before Bundler or Spring.
module WorktreeEnv
  ROOT = File.expand_path("..", __dir__)
  PATH_MARKERS = %w[/.worktrees/ /.claude/worktrees/].freeze
  MAX_IDENTIFIER_BYTES = 63 # Postgres NAMEDATALEN - 1
  # Rails appends "_<worker>" to the name for each parallel test worker.
  PARALLEL_SUFFIX_BYTES = 4

  module_function

  # A linked worktree has a `.git` *file* (pointing at the main repo's gitdir)
  # instead of a directory; the path markers cover checkouts where that isn't
  # visible (e.g. copied trees).
  def worktree?(root = ROOT)
    File.file?(File.join(root, ".git")) ||
      PATH_MARKERS.any? { |marker| "#{root}/".include?(marker) }
  end

  # "motzi_test_<worktree dir>" inside a worktree, nil otherwise. Keyed on the
  # worktree directory (not the branch) so switching branches keeps the same,
  # already-prepared database.
  def test_database_name(root = ROOT, base: "motzi_test")
    return unless worktree?(root)

    identifier("#{base}_#{sanitize(File.basename(root))}")
  end

  def sanitize(name)
    slug = name.downcase.gsub(/[^a-z0-9_]+/, "_").squeeze("_").delete_prefix("_").delete_suffix("_")
    slug.empty? ? "worktree" : slug
  end

  # Fit within Postgres's identifier limit, leaving room for the parallel
  # worker suffix. Truncated names get a short digest so they stay unique.
  def identifier(name)
    limit = MAX_IDENTIFIER_BYTES - PARALLEL_SUFFIX_BYTES
    return name if name.bytesize <= limit

    digest = Digest::SHA256.hexdigest(name)[0, 8]
    "#{name.byteslice(0, limit - digest.size - 1)}_#{digest}"
  end
end
