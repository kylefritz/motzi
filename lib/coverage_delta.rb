require "json"

# Compares two SimpleCov coverage.json reports (master baseline vs. a PR run)
# for the PR's changed files. Used by bin/coverage_delta in CI.
#
# Report-only except for one gate: a Ruby file the PR *adds* under app/ or lib/
# must reach NEW_FILE_MIN_LINE_PERCENT line coverage.
class CoverageDelta
  NEW_FILE_MIN_LINE_PERCENT = 50.0
  GATED_NEW_FILE = %r{\A(app|lib)/.+\.rb\z}
  # Percent changes smaller than this are rounding noise, not drops.
  EPSILON = 0.01

  Change = Struct.new(:status, :path) do
    def added? = status == "A"
  end

  # One row per changed file whose line or branch coverage dropped.
  Drop = Struct.new(:path, :line_before, :line_after, :branch_before, :branch_after)
  NewFile = Struct.new(:path, :line_percent, :covered, :total) do
    def failing? = line_percent < NEW_FILE_MIN_LINE_PERCENT
  end

  def self.load(path)
    JSON.parse(File.read(path, encoding: "UTF-8"))
  end

  # Parses `git diff --name-status` output. Renames (R100\told\tnew) count as
  # modifications of the new path.
  def self.parse_name_status(text)
    text.each_line.filter_map do |line|
      status, *paths = line.chomp.split("\t")
      next if status.nil? || paths.empty?

      Change.new(status[0], paths.last)
    end
  end

  # baseline may be nil (no master artifact); only the new-file gate runs then.
  def initialize(current:, changes:, baseline: nil)
    @current = files_of(current)
    @current_totals = current["total"] || {}
    @baseline = baseline && files_of(baseline)
    @baseline_totals = baseline && (baseline["total"] || {})
    @changes = changes
  end

  def baseline? = !@baseline.nil?

  def drops
    return [] unless baseline?

    @changes.reject(&:added?).filter_map do |change|
      before = @baseline[change.path]
      after = @current[change.path]
      next unless before && after

      row = Drop.new(change.path,
                     line_percent(before), line_percent(after),
                     branch_percent(before), branch_percent(after))
      row if dropped?(row.line_before, row.line_after) || dropped?(row.branch_before, row.branch_after)
    end
  end

  # Added app/lib Ruby files that SimpleCov tracked. Files it doesn't report
  # (filtered out, or with no executable lines) can't be judged, so they pass.
  def new_files
    @changes.select { |c| c.added? && c.path.match?(GATED_NEW_FILE) }.filter_map do |change|
      file = @current[change.path]
      next unless file && file["total_lines"].to_i.positive?

      NewFile.new(change.path, line_percent(file), file["covered_lines"].to_i, file["total_lines"].to_i)
    end
  end

  def failures = new_files.select(&:failing?)

  def passed? = failures.empty?

  def to_markdown
    out = [ "## Coverage delta", "" ]
    out << "_No master coverage baseline available (expired artifact or first run); showing this run only._" << "" unless baseline?
    out.concat(totals_table)
    out.concat(drops_section) if baseline?
    out.concat(new_files_section)
    out.join("\n") + "\n"
  end

  private

  # coverage.json keys are project-relative; strip meta.root just in case.
  def files_of(report)
    root = report.dig("meta", "root").to_s
    (report["coverage"] || {}).transform_keys do |path|
      root.empty? ? path : path.delete_prefix("#{root}/")
    end
  end

  def line_percent(file) = file["lines_covered_percent"]&.to_f

  def branch_percent(file)
    file["total_branches"].to_i.zero? ? nil : file["branches_covered_percent"]&.to_f
  end

  def dropped?(before, after)
    before && after && (before - after) > EPSILON
  end

  def totals_table
    rows = [ "| | master | this PR | change |", "|---|---:|---:|---:|" ]
    { "Lines" => "lines", "Branches" => "branches" }.each do |label, key|
      after = @current_totals.dig(key, "percent")
      before = @baseline_totals&.dig(key, "percent")
      rows << "| #{label} | #{pct(before)} | #{pct(after)} | #{delta(before, after)} |"
    end
    rows << ""
  end

  def drops_section
    rows = drops
    return [ "No changed files lost line or branch coverage.", "" ] if rows.empty?

    out = [ "### Changed files whose coverage dropped", "",
            "| File | Lines (master → PR) | Branches (master → PR) |", "|---|---:|---:|" ]
    rows.sort_by(&:path).each do |r|
      out << "| `#{r.path}` | #{pct(r.line_before)} → #{pct(r.line_after)} | #{pct(r.branch_before)} → #{pct(r.branch_after)} |"
    end
    out << ""
  end

  def new_files_section
    files = new_files
    return [] if files.empty?

    out = [ "### New app/lib files (gate: at least #{NEW_FILE_MIN_LINE_PERCENT.round}% line coverage)", "",
            "| File | Line coverage | Result |", "|---|---:|---|" ]
    files.sort_by(&:path).each do |f|
      out << "| `#{f.path}` | #{pct(f.line_percent)} (#{f.covered}/#{f.total}) | #{f.failing? ? "**FAIL**" : "ok"} |"
    end
    out << ""
  end

  def pct(value) = value.nil? ? "–" : format("%.1f%%", value)

  def delta(before, after)
    return "–" if before.nil? || after.nil?

    format("%+.2f pp", after - before)
  end
end
