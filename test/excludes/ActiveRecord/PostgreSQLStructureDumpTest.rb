
setup do
	@ignore_tables = ActiveRecord::SchemaDumper.ignore_tables
	ActiveRecord::SchemaDumper.ignore_tables = []
	ARTest.config["connections"]["postgresql"] = { "arunit" => { "database" => ARTest.config["connections"]["postgis"]["arunit"]["database"] } }
end

teardown do
	ActiveRecord::SchemaDumper.ignore_tables = @ignore_tables
	ARTest.config["connections"].delete("postgresql")
end
