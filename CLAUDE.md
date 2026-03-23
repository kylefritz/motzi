# Motzi

Neighborhood bakery's CSA site. Members browse menus, choose pickup days, and place orders.

## Conventions

- **Typecheck**: `bun run typecheck` (app only, default gate). `bun run typecheck:test` may fail on legacy test typings.
- **Database**: Never modify existing migrations. Always create a new one.
- **JSON APIs**: Responses use camelCase (via `olive_branch` gem). Use `jq` to parse JSON in the shell (not python3).
- **Complex SQL**: Lives in `app/sql_queries/` using ERB templates with the `sql_query` gem.
- **Logging**: Keep existing `console.log` statements. Do not delete or globally silence logs unless explicitly asked.
- **React tests**: Keep `act(...)` warnings as-is unless explicitly asked to change.
- If you run into Spring socket errors, then use `DISABLE_SPRING=1`. Otherwise dont use that and let spring do it's thing!

## Deployment

Heroku app `motzibread` auto-deploys from `master` when CI passes. Heroku Postgres 15 (essential-1). No Redis — everything runs on Postgres via Solid Queue (jobs), Solid Cable (ActionCable), and Solid Cache.

## Dev Shortcuts

- **Admin login** (dev only): `GET /dev/login_as_admin` — signs in as admin, no password. Useful for Playwright.

## MCP Notes

- **github**: Set `GITHUB_TOKEN=$(gh auth token)` in `.env` to enable GitHub MCP.
- **postgres**: MCP connects to `postgres://localhost/motzi` (local dev DB).
- **context7**: No auth needed — provides live Rails, React, Stripe docs.

## Worktrees

Feature work uses git worktrees in `.worktrees/`. When running `bundle` commands inside a worktree, set `BUNDLE_GEMFILE` to the worktree's Gemfile so bundler writes the lockfile to the right place:

```sh
BUNDLE_GEMFILE=$PWD/Gemfile bundle lock --update
```

## Before commit

- Run the rails tests (they're fast) & fix any errors

## After push

- Run `gh run watch` in the background to monitor CI. If it fails, investigate and fix.
