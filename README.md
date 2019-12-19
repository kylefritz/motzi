# Motzi

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

#### Migrations don't work?
Sometimes we're pretty fast and loose with db migrations. If your dev db is stuck try:
```
$ rails db:drop db:setup
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
