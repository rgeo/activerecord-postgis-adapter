exclude :test_migrator_forward, "Hangs indefinitely. Doesn't care about timeout"
exclude :test_get_all_versions, "Hangs indefinitely. Doesn't care about timeout"
exclude :test_finds_pending_migrations, "Hangs indefinitely. Doesn't care about timeout"
exclude :test_migrator_db_has_no_schema_migrations_table, "Too slow, something's wrong."
