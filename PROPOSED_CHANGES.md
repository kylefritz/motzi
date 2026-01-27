# Proposed Changes (Draft)

Date: 2026-01-27

This document tracks potential improvements and follow-ups. It is a draft list,
not a committed roadmap.

## Short-Term (low-risk / maintenance)

- Update README setup steps to match current tooling:
  - Use `bundle exec` for Rails commands.
  - Note required services: Postgres + Redis.
- Reduce test noise:
  - Remove or gate `console.log` spam in Jest tests.
  - Add a note or config to silence React act() warnings if desired.
- Address known deprecation warnings (from latest test run):
  - DidYouMean `SPELL_CHECKERS.merge!` deprecation.
  - PG `PG::Coder.new(hash)` deprecation.
  - Rails: rendering action with `.` in name (admin/menus/menu_builder.json.jbuilder).
- Check browserslist data update workflow (optional):
  - Decide whether to add `npx update-browserslist-db@latest` to CI or a docs note.

## Medium-Term (compat / upgrades)

- Review PostgreSQL version in CI (currently 11.5) and align with production.
- Review pinned gems for compatibility reasons:
  - `concurrent-ruby`, `jaro_winkler`, `stripe-ruby-mock` are pinned.

## Product / Feature TODOs (from code comments)

- `app/javascript/packs/buy/App.js`: send completed payment request to Rails.
- `app/javascript/packs/builder/Builder.js`: explain or remove side-load path.
- `app/javascript/packs/menu/App.js`: fix `orderingDeadlineText`.
- `app/models/user.rb`: clarify menu-order relationship.
- `app/models/menu.rb`: decide representation of menu metadata.
- `app/sql_queries/_user_credits.sql.erb`: handle credit expiration.
- `app/admin/menus.rb`: evaluate POST vs DELETE for menu item removal.
- `app/jobs/send_weekly_menu_job.rb`: improve reliability strategy.
- `test/models/order_test.rb`: extract shared setup into test_helper.
