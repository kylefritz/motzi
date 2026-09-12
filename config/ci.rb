# Local CI (Rails 8.1): run the same checks as .github/workflows/ci.yml with `bin/ci`.

CI.run do
  step "Style: Ruby", "bin/rubocop"

  step "Security: Gem audit", "bin/bundler-audit"
  step "Security: Brakeman code analysis", "bin/brakeman --quiet --no-pager --exit-on-warn --exit-on-error"

  step "Tests: Rails", "bin/rails test"
  step "Tests: JS", "bun run test"
  step "Typecheck", "bun run typecheck"
end
