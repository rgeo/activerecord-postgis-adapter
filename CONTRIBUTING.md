# Contributing

Fork the repo:

`git clone git@github.com:rgeo/activerecord-postgis-adapter.git`

Set up your test database:

`createdb postgis_adapter_test`

`createuser -s postgres`

`psql postgis_adapter_test`

`=# CREATE EXTENSION postgis;`

Make sure the tests pass:

`rake`

Make your changes and submit a pull request.
