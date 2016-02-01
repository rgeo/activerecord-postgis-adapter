# Contributing

Fork the repo:

`git clone git@github.com:rgeo/activerecord-postgis-adapter.git`

Set up your test database:

```sh
createuser -s postgres
psql -U postgres -c "create database postgis_adapter_test"
psql -U postgres -d postgis_adapter_test -c "create extension postgis"
```

Install dependencies:

```sh
bundle install
```

Make sure the tests pass:

`rake`

Run tests against both ActiveRecord 4.0 and 4.1 test gemfiles:

run `rake appraisal` or run the tests manually:

```
BUNDLE_GEMFILE=./gemfiles/ar40.gemfile bundle
BUNDLE_GEMFILE=./gemfiles/ar40.gemfile rake

BUNDLE_GEMFILE=./gemfiles/ar41.gemfile bundle
BUNDLE_GEMFILE=./gemfiles/ar41.gemfile rake
```

Make your changes and submit a pull request.
