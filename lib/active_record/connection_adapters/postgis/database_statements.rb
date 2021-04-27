# frozen_string_literal: true

require 'active_record/connection_adapters/abstract/database_statements'

module ActiveRecord
  module ConnectionAdapters # :nodoc:
    module PostGISDatabaseStatements
      def truncate_tables(*table_names)
        table_names -= ["spatial_ref_sys"]
        super(*table_names)
      end
    end
    DatabaseStatements.prepend(PostGISDatabaseStatements)
  end
end