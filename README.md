# Motzi ![](https://github.com/kylefritz/motzi/workflows/ci/badge.svg)

Neighborhood bakery's CSA site

## Development

- postgres.app
- redis
- mise (manages Ruby/Bun)

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

### Running tests

If you want to run the full stack of automated tests locally, use the helper script we keep in `bin/tests`. It runs `mise exec -- bundle exec rails test` first and, if the Rails suite succeeds, continues with `bun run test` so you can catch both Ruby and Bun failures in one go.

### Running js tests

```
$ bun run test
```

Watch js tests

```
$ bun run test --watch
```

Debug js tests

```
$ bun test --inspect-brk test/javascript/menu/items.test.tsx
```

Or wait for a debugger to attach:

```
$ bun test --inspect-wait test/javascript/menu/items.test.tsx
```

Then open the debug URL that Bun prints (it looks like `https://debug.bun.sh/...`).

### Git hooks (Husky)

Skip Husky hooks for a single commit:

```
HUSKY=0 git commit -m "no hooks run"
```

### Checking emails

visit `/letter_opener` to see emails sent by rails

### spam users

```
User.find(SqlQuery.new(:spam_user_ids).execute.pluck("id")).each {|u| u.destroy!}
```

### Bun on Heroku with a Bun buildpack

Ensure a Bun buildpack runs before the Ruby buildpack so `assets:precompile` can run
`bun run build` via jsbundling-rails.
