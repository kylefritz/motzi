# Motzi

Neighborhood bakery's CSA site. Members browse menus, choose pickup days, and place orders.

## Sandbox

Rails commands (`bundle exec rails test`, `bin/rails`, migrations, etc.) need to connect to Postgres. Always run them with `dangerouslyDisableSandbox: true`.

## Conventions

- **Typecheck**: `bun run typecheck` (app only, default gate). `bun run typecheck:test` may fail on legacy test typings.
- **Database**: Never modify existing migrations. Always create a new one.
- **JSON APIs**: Responses use camelCase (via `olive_branch` gem). Use `jq` to parse JSON in the shell (not python3).
- **Complex SQL**: Lives in `app/sql_queries/` using ERB templates with the `sql_query` gem.
- **Logging**: Keep existing `console.log` statements. Do not delete or globally silence logs unless explicitly asked.
- **React tests**: Keep `act(...)` warnings as-is unless explicitly asked to change.
- If you run into Spring socket errors, then use `DISABLE_SPRING=1`. Otherwise dont use that and let spring do it's thing!

## Tests

There are three test suites. The first two run in CI; the third is manual.

| Suite | Command | What it tests | Speed | CI? |
|-------|---------|---------------|-------|-----|
| **Rails** | `bundle exec rails test` | Models, controllers, mailers, jobs, SQL queries | ~35s | Yes |
| **JS** | `bun test` | React components (menu, cart, builder, credits) via jsdom | ~3s | Yes |
| **Visual** | `bunx playwright test` | Email template screenshots — mobile (iPhone 14) & desktop | ~20s | No — manual only |

### Visual tests

Playwright screenshots all 6 email templates at mobile and desktop viewports, then sends each screenshot to Claude Haiku for visual QA (checks for overlapping text, broken layout, clipped content). Not in CI because they require a running Rails server with dev data and an `ANTHROPIC_API_KEY`.

```
bunx playwright test                              # run all (12 tests: 6 emails × 2 viewports)
bunx playwright test --project mobile             # mobile only
bunx playwright test --grep "havent_ordered"       # single email
```

**When to run:** after changing email templates (`.mjml`), shared mailer partials (`app/views/shared_mailer/`), or the `_head.html.erb` styles.

**Requirements:** Rails on localhost:3000, `ANTHROPIC_API_KEY` in `.env`, Chromium (`bunx playwright install chromium`).

**Files:**
- `playwright.config.ts` — project config (mobile/desktop viewports)
- `test/visual/email-screenshots.spec.ts` — the test
- `test/visual/email-check-prompt.txt` — Claude's visual QA prompt (edit to tune what it checks)
- `test/visual/screenshots/` — output (gitignored)

## AWS / S3

- **Bucket**: `motzi` in `us-east-1` — used by Active Storage for item images
- **IAM user**: `motzi-s3` — can read/write objects but cannot manage bucket policies
- **Config**: `config/storage.yml` (`amazon` service), credentials via `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY`
- **Public prefix**: `s3://motzi/public/` is publicly readable. Everything else (Active Storage files) is private.
- **PR screenshots**: Uploaded to `s3://motzi/public/gh/pr-<NUMBER>/` — see "PR Screenshots" below.

## PR Screenshots

PRs with visual changes should include screenshots in the PR description (not comments).

**Quick way** (screenshots multiple URLs and updates the PR description):
```
bin/screenshot-pr /404 /422 /500.html
bin/screenshot-pr --device "iPhone 14" /rails/mailers/reminder_mailer/havent_ordered_email
```

**Manual way** (screenshot a single URL):
```
bin/screenshot /some-page my-feature
# outputs S3 URL and markdown to paste
```

Screenshots are uploaded to `s3://motzi/public/gh/pr-<NUMBER>/` and embedded in the PR body under a `## Screenshots` section. The `bin/screenshot-pr` script replaces any existing screenshots section when re-run.

## Deployment

Heroku app `motzibread` auto-deploys from `master` when CI passes. Heroku Postgres 15 (essential-1). No Redis — everything runs on Postgres via Solid Queue (jobs), Solid Cable (ActionCable), and Solid Cache.

## Dev Shortcuts

- **Admin login** (dev only): `GET /dev/login_as_admin` — signs in as admin, no password. Useful for Playwright.

## MCP Notes

- **github**: Set `GITHUB_TOKEN=$(gh auth token)` in `.env` to enable GitHub MCP.
- **postgres**: MCP connects to `postgres://localhost/motzi` (local dev DB).
- **context7**: No auth needed — provides live Rails, React, Stripe docs.

## Worktrees

Feature work uses git worktrees in `.worktrees/`. When setting up a worktree:

- **Symlink `.env`**: `ln -s ../../.env .env` (worktrees don't get untracked files)
- **Bundler lockfile**: use `BUNDLE_GEMFILE=$PWD/Gemfile bundle lock --update` so bundler writes to the worktree, not the main repo

## Issues

We track work in GitHub Issues (`gh issue list`). When wrapping up a conversation or between tasks, feel free to suggest an open issue that might be worth tackling next.

## Before commit

- Run the Rails tests (they're fast) & fix any errors
- If you changed email templates or mailer styles, run the visual tests too

## After push

- Check GitHub Actions status in the background after pushing: `gh run list --branch $(git branch --show-current) --workflow CI --limit 1 --json databaseId --jq '.[0].databaseId' | xargs gh run watch --exit-status`. If anything fails, investigate and fix.
