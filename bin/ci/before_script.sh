createdb -U postgres postgis_adapter_test

if [[ "$POSTGIS" == "2.0" ]]; then
  psql -U postgres -d postgis_adapter_test -c "CREATE EXTENSION postgis;"
else
  createlang -U postgres plpgsql postgis_adapter_test
  psql -U postgres -d postgis_adapter_test -f /usr/share/postgresql/9.1/contrib/postgis-1.5/postgis.sql
  psql -U postgres -d postgis_adapter_test -f /usr/share/postgresql/9.1/contrib/postgis-1.5/spatial_ref_sys.sql
fi
