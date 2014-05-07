createdb -U postgres postgis_adapter_test
psql -U postgres -d postgis_adapter_test -c "CREATE EXTENSION postgis;"
