exclude "test_legacy_change_column_with_null_executes_update", TRIAGE_MSG
exclude "test_disable_extension_on_7_0", TRIAGE_MSG
exclude "test_legacy_add_foreign_key_with_deferrable_true", TRIAGE_MSG
exclude "test_create_table_with_uuid_primary_key_on_5_0_defaults_to_uuid_generate_v4_on_postgresql",
        "Migration compatibility checks adapter_name == \"PostgreSQL\", which is \"PostGIS\" here"
exclude "test_add_column_datetime_on_7_0_uses_datetime_type_on_postgresql",
        "with_postgresql_datetime_type sets PostgreSQLAdapter.datetime_type, but PostGIS uses PostGISAdapter.datetime_type"
exclude "test_schema_load_applies_declared_version_compatibility_on_postgresql",
        "with_postgresql_datetime_type sets PostgreSQLAdapter.datetime_type, but PostGIS uses PostGISAdapter.datetime_type"
