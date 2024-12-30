exclude "test_schema_dump_with_timestamptz_datetime_format", TRIAGE_MSG
exclude "test_schema_dump_when_changing_datetime_type_for_an_existing_app", TRIAGE_MSG
if ActiveRecord::Base.lease_connection.pool.server_version(ActiveRecord::Base.lease_connection) < 15_00_00
  exclude "test_schema_dumps_unique_constraints", TRIAGE_MSG
end
