# Motzi Agent Notes

Concise project-specific helpers for CI and local dev.

## Tooling

- Ruby version: 3.3.10 (see `Gemfile` / `mise.toml`)
- Package manager: Bun (keep `yarn.lock` for Heroku compatibility)
- Deployment: Heroku. When suggesting changes, consider the deployment impact (builds, assets, env vars, and CI).
- CI: GitHub Actions runs the test/build pipeline; keep changes compatible with GH CI.

## JavaScript tests (Bun)

Run all JS tests:

```
bun run test
```

Update snapshots (if any):

```
bun run test -- -u
```

Run a single test file:

```
bun run test -- test/javascript/menu/items.test.tsx
```

Debug a single test in Bun inspector:

```
bun --inspect-brk test test/javascript/menu/items.test.tsx
```

Logging preference:

- Keep existing `console.log` statements in tests and app code. Do not delete or globally silence logs unless explicitly asked.

## JavaScript build (esbuild)

Build JS bundles once:

```
bun run build
```

Watch and rebuild in development:

```
bun run build:watch
```

## CI / deployment build steps

- GitHub Actions runs `bun install`, `bun run build`, Rails tests, and Jest before deploying to Heroku.
- Heroku deploys from GH CI on successful `master` builds; make sure asset build changes are compatible with `bun run build` and the Heroku buildpack setup.

## Rails tests

Run all Rails tests (agents need elevated permissions):

```
bundle exec rails test
```

If you hit Spring socket permission errors, disable Spring:

```
DISABLE_SPRING=1 bundle exec rails test
```

Rails tests require a running local Postgres on `127.0.0.1:5432` / `::1:5432`.
