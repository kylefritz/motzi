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

## Landing the Plane (Session Completion)

**When ending a work session**, you MUST complete ALL steps below. Work is NOT complete until `git push` succeeds.

**MANDATORY WORKFLOW:**

1. **File issues for remaining work** - Create issues for anything that needs follow-up
2. **Run quality gates** (if code changed) - Tests, linters, builds
3. **Update issue status** - Close finished work, update in-progress items
4. **PUSH TO REMOTE** - This is MANDATORY:
   ```bash
   git pull --rebase
   bd sync
   git push
   git status  # MUST show "up to date with origin"
   ```
5. **Clean up** - Clear stashes, prune remote branches
6. **Verify** - All changes committed AND pushed
7. **Hand off** - Provide context for next session

**CRITICAL RULES:**
- Work is NOT complete until `git push` succeeds
- NEVER stop before pushing - that leaves work stranded locally
- NEVER say "ready to push when you are" - YOU must push
- If push fails, resolve and retry until it succeeds
