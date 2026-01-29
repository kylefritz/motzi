# Proposed Changes (Draft)

Date: 2026-01-27

This document tracks potential improvements and follow-ups. It is a draft list, not a committed roadmap.

## p0 customer requested features

- Add support having ordering open for two weeks at once so that we can use the heroku for holiday ordering.
  - If there are two menus open, show them as tabs on the ordering page.
  - Likely the holiday menu would be posted 3-4 weeks ahead and allow people to order for a few weeks
  - During the period when the holiday menu is up, we might have a new weekly menu for each week
  - please update the admin site to support multiple menus also.
  - please write tests that prove it's ok for menus to overlap.
  - maybe during create, we should have a flag called "allow overlap" for holiday menus. if this flag is set, let a menu overlap with another one?

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
