# Motzi Agent Notes

Concise project-specific helpers for CI and local dev.

## Tooling

- Node version: 20 (see `mise.toml`)
- Ruby version: 3.3.10 (see `Gemfile` / `mise.toml`)
- Package manager: Yarn v1 (lockfile is `yarn.lock`)
- Deployment: Heroku. When suggesting changes, consider the deployment impact (builds, assets, env vars, and CI).
- CI: GitHub Actions runs the test/build pipeline; keep changes compatible with GH CI.

## JavaScript tests (Jest)

Run all tests and update snapshots:

```
npx jest -u
```

Run a single test file (no snapshot update):

```
npx jest test/javascript/menu/items.test.js
```

Debug a single Jest test in Node inspector:

```
node --inspect-brk node_modules/.bin/jest --runInBand -u test/javascript/menu/items.test.js
```

Logging preference:
- Keep existing `console.log` statements in tests and app code. Do not delete or globally silence logs unless explicitly asked.

## JavaScript build (esbuild)

Build JS bundles once:

```
yarn build
```

Watch and rebuild in development:

```
yarn build:watch
```

## CI / deployment build steps

- GitHub Actions runs `yarn install`, `yarn build`, Rails tests, and Jest before deploying to Heroku.
- Heroku deploys from GH CI on successful `master` builds; make sure asset build changes are compatible with `yarn build`.

## Rails tests

Run all Rails tests:

```
bundle exec rails test
```

If you hit Spring socket permission errors, disable Spring:

```
DISABLE_SPRING=1 bundle exec rails test
```

Rails tests require a running local Postgres on `127.0.0.1:5432` / `::1:5432`.

Known warnings (as of Jan 27, 2026):
  - DidYouMean: `SPELL_CHECKERS.merge!` deprecation
  - PG: `PG::Coder.new(hash)` deprecation
  - Rails: rendering action with `.` in name (admin/menus/menu_builder.json.jbuilder)
