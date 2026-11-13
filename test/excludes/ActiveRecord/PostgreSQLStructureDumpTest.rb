
setup do
  # Rails 8.2 deprecated SchemaDumper.ignore_tables in favor of ActiveRecord.schema_ignored_tables
  @ignore_tables_owner = ActiveRecord.respond_to?(:schema_ignored_tables) ? ActiveRecord : ActiveRecord::SchemaDumper
  @ignore_tables_method = ActiveRecord.respond_to?(:schema_ignored_tables) ? :schema_ignored_tables : :ignore_tables
  @ignore_tables = @ignore_tables_owner.public_send(@ignore_tables_method)
  @ignore_tables_owner.public_send(:"#{@ignore_tables_method}=", [])
  ARTest.config["connections"]["postgresql"] = { "arunit" => { "database" => ARTest.config["connections"]["postgis"]["arunit"]["database"] } }
end

teardown do
  @ignore_tables_owner.public_send(:"#{@ignore_tables_method}=", @ignore_tables)
  ARTest.config["connections"].delete("postgresql")
end

exclude :test_structure_dump, TRIAGE_MSG + " / Likely due to CI installation of pg_dump vs postges"
