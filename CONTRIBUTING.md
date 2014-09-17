# Contributing

Fork the repo:

`git clone git@github.com:rgeo/activerecord-postgis-adapter.git`

Set up your test database:

```sh
createdb postgis_adapter_test
createuser -s postgres
```

Make sure the tests pass:

```ruby
bundle
rake
```

Make your changes and submit a pull request.
