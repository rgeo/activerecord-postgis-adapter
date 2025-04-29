# Contributing

Fork the repo:

`git clone git@github.com:rgeo/activerecord-postgis-adapter.git`

Set up your test database:

```sh
createuser -s postgres
psql -U postgres -c "create database postgis_adapter_test"
psql -U postgres -d postgis_adapter_test -c "create extension postgis"
```

You may also set up environment variables to define the database connection.
See `test/database.yml` for which variables are used. All are optional.
For example:

```sh
export PGUSER=postgis_test
export PGPASSWORD=password123
export PGPORT=95432
export PGHOST=127.0.0.2
export PGDATABASE=postgis_adapter_test

psql -c "create database postgis_adapter_test"
psql -c "create extension postgis"
```

Install dependencies:

```sh
bundle install
```

Make sure the tests pass:

`bundle exec rake`

Run tests with a specific ActiveRecord version:

```sh
AR_VERSION=7.0.1 bundle install
AR_VERSION=7.0.1 bundle exec rake test
```

To run a specific test, use the `POSTGIS_TEST_FILES` environment variable:

`POSTGIS_TEST_FILES=test/cases/ddl_test.rb bundle exec rake test:postgis`

If you are testing a feature against the ActiveRecord test suite run:

`bundle exec rake test:activerecord`

Files can be specified with the `AR_TEST_FILES` environment variable:

`AR_TEST_FILES=test/cases/adapters/postgresql/*_test.rb bundle exec rake test:activerecord`

To test with both local and ActiveRecord tests, run:

`bundle exec rake test:all`

Run tests against the test gemfiles:

run `rake appraisal` or run the tests manually:

```
BUNDLE_GEMFILE=./gemfiles/ar61.gemfile bundle
BUNDLE_GEMFILE=./gemfiles/ar61.gemfile bundle exec rake
```

Make your changes and submit a pull request.

Note: the master branch targets the latest version of Active Record. To submit
a pull request for a prior version, be sure to branch from the correct version
(for example, 4.0-stable). Also be sure to set the target branch of the pull
request to that version (for example, 4.0-stable).
