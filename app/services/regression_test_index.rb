# Finds which production errors have a regression test.
#
# Convention: a test written for a production error cites it in a comment or
# test name as "error_events #<id>" (several ids: "error_events #2048, #2214").
# Test files ship in the Heroku slug, so in production this reads the tests of
# the deployed release and can be checked with
# `heroku run rake error_events:untested`.
class RegressionTestIndex
  CITATION = /error_events\s+((?:#\d+(?:,\s*)?)+)/

  Reference = Struct.new(:event_id, :path, :line)

  def initialize(root: Rails.root.join("test"))
    @root = Pathname(root)
  end

  # { event_id => [Reference, ...] }
  def references
    @references ||= scan.group_by(&:event_id)
  end

  # References citing any event in the fingerprint's group.
  def for_fingerprint(fingerprint)
    ids = ErrorEvent.where(fingerprint: fingerprint).pluck(:id)
    references.values_at(*ids).compact.flatten
  end

  # Resolved error groups (latest occurrence within `since`) that no test cites.
  # Returns [{ fingerprint:, latest_id:, error_class:, message:, resolved_at: }].
  def untested_resolved(since: 90.days.ago)
    cited = references.keys
    groups = ErrorEvent.resolved.where(occurred_at: since..)
      .group(:fingerprint)
      .pluck(:fingerprint, Arel.sql("MAX(id)"), Arel.sql("ARRAY_AGG(id)"),
        Arel.sql("MAX(error_class)"), Arel.sql("MAX(message)"), Arel.sql("MAX(resolved_at)"))

    groups.filter_map do |fingerprint, latest_id, ids, error_class, message, resolved_at|
      next if ids.intersect?(cited)

      { fingerprint:, latest_id:, error_class:, message: message.to_s.lines.first.to_s.strip, resolved_at: }
    end.sort_by { |g| -g[:latest_id] }
  end

  private

  def scan
    Dir.glob(@root.join("**/*.rb")).flat_map do |path|
      relative = Pathname(path).relative_path_from(@root.parent).to_s
      File.foreach(path).with_index(1).flat_map do |text, line|
        text.scan(CITATION).flat_map do |(ids)|
          ids.scan(/\d+/).map { |id| Reference.new(id.to_i, relative, line) }
        end
      end
    end
  end
end
