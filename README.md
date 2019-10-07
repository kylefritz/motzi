# Motzi

Neighborhood bakery's CSA site


## Development

### Getting started
```
$ bundle
$ yarn install --check-files
$ rails db:create db:migrate
```

#### Test data
Try loading the fixtures into your local development database so you have some data to play with

```
$ rails db:fixtures:load
```

#### Migrations don't work?
Sometimes we're pretty fast and loose with db migrations. If your dev db is stuck try:
```
$ rails db:drop db:create db:migrate db:fixtures:load
```

### Running the app
```
rails server
```

Working on the react apps
```
$ ./bin/webpack-dev-server
```
