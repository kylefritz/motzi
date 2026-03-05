# Motzi

Neighborhood bakery's CSA (Community Supported Agriculture) site. Members browse menus, choose pickup days, and place orders.

## Architecture

- **Backend**: Rails 7.2, PostgreSQL, Solid Queue
- **Frontend**: React 18 + TypeScript, esbuild via jsbundling-rails, styled-components
- **Auth**: Devise
- **Payments**: Stripe
- **Admin**: ActiveAdmin at `/admin`
- **Jobs UI**: Mission Control Jobs at `/jobs` (admin-only)
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

- **JS/TS**: Prettier runs on commit (Husky). Keep React test `act(...)` warnings as-is unless explicitly asked to change.
- **Typecheck**:
  - `bun run typecheck` checks app code only (`tsconfig.app.json`) and is the default gate.
  - `bun run typecheck:test` checks test code (`tsconfig.test.json`) and may fail on legacy test typings.
- **Ruby**: RuboCop per `.rubocop.yml`. No frozen string literal comments. No doc comments required.
- **Database**: Never modify existing migrations. Always create a new one.
- **JSON APIs**: Responses use camelCase (via `olive_branch` gem). Use `jq` to parse JSON in the shell (not python3).
- **Complex SQL**: Lives in `app/sql_queries/` using ERB templates with the `sql_query` gem.
- **Logging**: Keep existing `console.log` statements in tests and app code. Do not delete or globally silence logs unless explicitly asked.

## Sensitive Files

- `.env` — secrets (gitignored, loaded by direnv)
- `Gemfile.lock` and `bun.lockb` are managed files: edit only through `bundle install` / `bun install`.

## Tooling

- Ruby version: 3.3.10 (see `Gemfile` / `mise.toml`)
- Package manager: Bun
- CI: GitHub Actions runs `bun install`, `bun run build`, Rails tests, Bun tests, and typecheck.

## Testing

### Rails tests

```
bundle exec rails test
```

If you hit Spring socket permission errors, disable Spring:

```
DISABLE_SPRING=1 bundle exec rails test
```

Rails tests require a running local Postgres on `127.0.0.1:5432` / `::1:5432`.

### JavaScript tests (Bun)

```
bun run test
```

Update snapshots: `bun run test -- -u`

Run a single test: `bun run test -- test/javascript/menu/items.test.tsx`

Debug: `bun --inspect-brk test test/javascript/menu/items.test.tsx`

### TypeScript checks

App-only (default):

```
bun run typecheck
```

Include tests too:

```
bun run typecheck:test
```

### JavaScript build (esbuild)

Build once: `bun run build`

Watch: `bun run build:watch`

### Git hooks (Husky)

Skip hooks: `HUSKY=0 git commit -m "no hooks run"`

## Deployment

Heroku auto-deploys from `master` when GitHub Actions CI passes. Background workers run via Solid Queue (`bin/jobs start`) and ActionCable uses the `async` adapter (no Redis runtime requirement).

## MCP Notes

- **github**: Set `GITHUB_TOKEN=$(gh auth token)` in `.env` to enable GitHub MCP.
- **postgres**: MCP connects to `postgres://localhost/motzi` (local dev DB).
- **context7**: No auth needed — provides live Rails, React, Stripe docs.
