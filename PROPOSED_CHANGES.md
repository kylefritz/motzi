# Proposed Changes (Draft)

Date: 2026-01-27

This document tracks potential improvements and follow-ups. It is a draft list, not a committed roadmap.

## Medium-Term (compat / upgrades)

- Review PostgreSQL version in CI (currently 11.5) and align with production.
- Review pinned gems for compatibility reasons:
  - `concurrent-ruby`, `jaro_winkler`, `stripe-ruby-mock` are pinned.

## Product / Feature TODOs (from code comments)

- `app/javascript/packs/buy/App.tsx`: send completed payment request to Rails.
- `app/javascript/packs/builder/Builder.tsx`: explain or remove side-load path.
- `app/javascript/packs/menu/App.tsx`: fix `orderingDeadlineText`.
- `app/models/user.rb`: clarify menu-order relationship.
- `app/models/menu.rb`: decide representation of menu metadata.
- `app/sql_queries/_user_credits.sql.erb`: handle credit expiration.
- `app/admin/menus.rb`: evaluate POST vs DELETE for menu item removal.
- `app/jobs/send_weekly_menu_job.rb`: improve reliability strategy.
- `test/models/order_test.rb`: extract shared setup into test_helper.
