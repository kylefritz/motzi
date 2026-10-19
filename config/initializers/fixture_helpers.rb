# Fixture ERB calls helpers like `this_week` (test/support/fixture_helpers.rb).
# Include them whenever fixtures load, not just under test_helper, so
# `bin/rails db:fixtures:load` works too (the LLM evals workflow loads fixtures
# into a throwaway dev database). Production never loads fixtures.
unless Rails.env.production?
  ActiveSupport.on_load(:active_record_fixture_set) do
    require Rails.root.join("test/support/fixture_helpers").to_s
    context_class.include(FixtureHelpers)
  end
end
