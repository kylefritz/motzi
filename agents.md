# Motzi Agent Notes

Concise project-specific helpers for CI and local dev.

## Tooling

- Node version: 20 (see `mise.toml`)
- Ruby version: 3.1.4 (see `Gemfile` / `mise.toml`)
- Package manager: Yarn v1 (lockfile is `yarn.lock`)

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

## JavaScript build (esbuild)

Build JS bundles once:

```
yarn build
```

Watch and rebuild in development:

```
yarn build:watch
```

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
