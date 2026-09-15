# Local CI (Rails 8.1): run the same checks as .github/workflows/ci.yml with `bin/ci`.

CI.run do
  step "Style: Ruby", "bin/rubocop"

  step "Security: Gem audit", "bin/bundler-audit"
  step "Security: Brakeman code analysis", "bin/brakeman --quiet --no-pager --exit-on-warn --exit-on-error"

  step "Contract: schema types up to date", "bin/generate_schema_types && git diff --exit-code app/javascript/types/api.generated.ts"

  # COVERAGE=1 writes a report-only SimpleCov report to coverage/index.html (no minimum).
  step "Tests: Rails", "COVERAGE=1 bin/rails test --profile 10"
  step "Tests: JS", "bun run test"
  step "Typecheck", "bun run typecheck"
  step "Typecheck: tests", "bun run typecheck:test"
end
