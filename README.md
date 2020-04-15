# Motzi ![](https://github.com/kylefritz/motzi/workflows/ci/badge.svg)

Neighborhood bakery's CSA site

## Development

### Getting started

```
$ bundle
$ yarn install --check-files
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

Working on the react apps

```
$ ./bin/webpack-dev-server
```

### Running js tests

```
npx jest
```

### Checking emails

visit `/letter_opener` to see emails sent by rails
