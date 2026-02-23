# Motzi

Neighborhood bakery's CSA (Community Supported Agriculture) site. Members browse menus, choose pickup days, and place orders. See `agents.md` for tooling/CI reference.

## Architecture

- **Backend**: Rails 6.1, PostgreSQL, Redis, Sidekiq
- **Frontend**: React 16 + TypeScript, esbuild via jsbundling-rails, Material UI
- **Auth**: Devise
- **Payments**: Stripe
- **Admin**: ActiveAdmin at `/admin`
- **Analytics**: Blazer at `/blazer`, Ahoy for event tracking
- **Errors**: Sentry (Ruby + browser)
- **Storage**: ActiveStorage + S3

## Key Models

- `Menu` → `MenuItem` → `Item` — bakery product catalog
- `Order` → `OrderItem` — member purchases
- `PickupDay` / `MenuItemPickupDay` — scheduling
- `User` — members (Devise)
- `CreditBundle` / `CreditItem` — store credits

## Conventions

- **JS/TS**: Prettier runs on commit (Husky). Run `bun run typecheck` for TypeScript checks.
- **Ruby**: RuboCop per `.rubocop.yml`. No frozen string literal comments. No doc comments required.
- **Database**: Never modify existing migrations. Always create a new one.
- **JSON APIs**: Responses use camelCase (via `olive_branch` gem). Use `jq` to parse JSON in the shell (not python3).
- **Complex SQL**: Lives in `app/sql_queries/` using ERB templates with the `sql_query` gem.

## Sensitive Files — Never Edit Without Explicit Approval

- `.env` — secrets (gitignored, loaded by direnv)
- `Gemfile.lock` — managed by Bundler
- `bun.lockb` — managed by Bun

## Deployment

Heroku auto-deploys from `master` when GitHub Actions CI passes.

## MCP Notes

- **github**: Set `GITHUB_TOKEN=$(gh auth token)` in `.env` to enable GitHub MCP.
- **postgres**: MCP connects to `postgres://localhost/motzi` (local dev DB).
- **context7**: No auth needed — provides live Rails, React, Stripe docs.
