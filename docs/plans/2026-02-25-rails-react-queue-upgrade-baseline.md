# Rails + React + Queue Upgrade Baseline

Date: 2026-02-25
Branch: `codex/motzi-rails-upgrade`

## Plan Review Summary

The attached upgrade plan is sound and phased correctly for this codebase.

- `activeadmin` must move before Rails 7.1+ because current `2.13.1` constraints block newer railties.
- Queue/cable migration should stay separate from framework and React major bumps to reduce rollback risk.
- React 18 is appropriately deferred until Stripe and Material UI ecosystem blockers are removed.

## Current Baseline Snapshot

### Ruby/Rails/Admin/Queue

- Rails: `~> 6.1.7.3` (`Gemfile`)
- ActiveAdmin: `~> 2.13.1` (`Gemfile`)
- Sidekiq: present (`Gemfile`, worker process, initializer, routes)
- Redis: present for ActionCable + global initializer (`Gemfile`, `config/cable.yml`, `config/initializers/redis.rb`)

### Frontend

- React: `16.10.2`
- ReactDOM API: legacy `ReactDOM.render` in entrypoints
- Stripe frontend: `react-stripe-elements` (legacy)
- UI framework: `@material-ui/core` / `@material-ui/icons` v4

## Baseline Checks

Status captured on this machine:

- `bundle list | rg 'rails|activeadmin|sidekiq|redis'`: **passes**
- `mise exec -- env DISABLE_SPRING=1 bundle exec rails test test/models/user_test.rb`: **passes** (12 runs, 0 failures)
- `bun run test`: **passes** (46 test files, 0 failures)
- `bun run typecheck`: **fails** (existing TypeScript type errors across legacy React code)

Notes:

- `mise.toml` must be trusted (`mise trust`) so project Ruby/Bundler are activated correctly.
- In Codex sandbox, Bun temp-dir and localhost DB access require running commands outside sandbox.
- CI remains the source of truth for full-suite reproducible verification.

## Release Gate Manual QA Script

### Admin

- login/logout
- dashboard load
- menu CRUD + copy-from
- open menu for orders
- send test menu email
- user batch delete behavior
- pickup list view

### Customer

- view menu
- add/remove cart items
- place order (card + credit)
- update order
- receive confirmation email

### Jobs

- `SendWeeklyMenuJob` enqueues and processes
- reminder tasks execute and send mail
- ActiveStorage jobs execute

## Next Implementation Slice

1. Upgrade ActiveAdmin to latest compatible 3.x and resolve admin DSL/runtime issues.
2. Run admin-focused regression tests and manual gates.
3. Only then start Rails hop to `7.0.x`.
