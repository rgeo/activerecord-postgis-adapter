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

Run tests against the test gemfiles:

run `rake appraisal` or run the tests manually:

```
BUNDLE_GEMFILE=./gemfiles/ar60.gemfile bundle
BUNDLE_GEMFILE=./gemfiles/ar60.gemfile rake
```

Make your changes and submit a pull request.

Note: the master branch targets the latest version of Active Record. To submit
a pull request for a prior version, be sure to branch from the correct version
(for example, 4.0-stable). Also be sure to set the target branch of the pull
request to that version (for example, 4.0-stable).
