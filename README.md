# Motzi ![](https://github.com/kylefritz/motzi/workflows/ci/badge.svg)

Neighborhood bakery's CSA site

## Development

- postgres.app
- redis
- mise (manages Ruby/Bun)

### Setup

```
$ bin/setup
```

`bin/setup` runs:
- `mise install`
- `bundle`
- `bun install`
- `rails db:prepare` (use `DB_SETUP=1 bin/setup` for `db:setup`)

You need Postgres and Redis running locally, plus a few variables in a `.env` file:
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
STRIPE_PUBLISHABLE_KEY

### Running the app

Run Rails + Bun watch together:

```
$ bin/dev
```

`bin/dev` uses `Procfile.dev` and runs `bin/setup` by default. Set
`SKIP_SETUP=1` to skip the setup step.

### Local JS dev (Bun)

If you only want the JS watcher (no Rails):

```
$ bun run build:watch
```

If `bun` is not on your PATH:

```
$ mise exec -- bun run build:watch
```

### Data

#### Test data

Try loading the fixtures into your local development database so you have some data to play with

```
$ rails db:fixtures:load
$ rails fake_data:users
$ rails fake_data:orders
```

#### Real data

Copy the db from heroku to your local postgres

```
$ dropdb motzi
$ heroku pg:pull DATABASE_URL --app motzibread motzi
```

Download the menu images from s3

```
$ rake s3:download
```

### Heroku JS build (Bun)

To build JS assets during deploy, use the `heroku-buildpack-run` buildpack to
run a script at build time.

1. Add the buildpack (ensure it runs before the Ruby buildpack):

```
$ heroku buildpacks:add https://github.com/weibeld/heroku-buildpack-run
```

2. Add `buildpack-run.sh` at the repo root:

```bash
#!/usr/bin/env bash
set -euo pipefail

curl -fsSL https://bun.com/install | bash
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

bun install
bun run build
```

Make it executable (`chmod +x buildpack-run.sh`) and commit it so it runs on
each deploy.

### Running js tests

```
$ bun run test
```

Debug js tests

```
$ bun --inspect-brk test test/javascript/menu/items.test.tsx
```

### Checking emails

visit `/letter_opener` to see emails sent by rails

### spam users

```
User.find(SqlQuery.new(:spam_user_ids).execute.pluck("id")).each {|u| u.destroy!}
```
