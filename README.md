# Motzi ![](https://github.com/kylefritz/motzi/workflows/ci/badge.svg)

Neighborhood bakery's CSA site

## Development

- postgres.app
- redis
- mise (manages Ruby/Bun)

### Getting started

```
$ mise install
$ bundle
$ bun install
$ rails db:setup
```

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

### Running the app

```
$ rails server
```

You need a few variables in a .env file
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
STRIPE_PUBLISHABLE_KEY

Working on the react apps

```
$ bun run build:watch
```

### Running js tests

```
$ bun run test
```

Update snapshots (if any)

```
$ bun run test -- -u
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
