# Contributing

Fork the repo:

`git clone git@github.com:rgeo/activerecord-postgis-adapter.git`

Set up your test database:

```sh
createdb postgis_adapter_test
createuser -s postgres
psql postgis_adapter_test
=# CREATE EXTENSION postgis;
```

Make sure the tests pass:

`rake`

Run tests against both ActiveRecord 4.0 and 4.1 test gemfiles:

```
BUNDLE_GEMFILE=./travis/ar40.gemfile bundle
BUNDLE_GEMFILE=./travis/ar40.gemfile rake

BUNDLE_GEMFILE=./travis/ar41.gemfile bundle
BUNDLE_GEMFILE=./travis/ar41.gemfile rake
```

Make your changes and submit a pull request.
