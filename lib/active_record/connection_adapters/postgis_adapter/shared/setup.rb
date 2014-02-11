module ActiveRecord  # :nodoc:

  module ConnectionAdapters  # :nodoc:

    module PostGISAdapter  # :nodoc:


      def self.initial_setup
        gis_ignore_tables_ = ['geometry_columns', 'spatial_ref_sys', 'layer', 'topology']
        ignore_tables_ = ::ActiveRecord::SchemaDumper.ignore_tables
        gis_ignore_tables_.each do |table_|
          ignore_tables_ << table_ unless ignore_tables_.include?(table_)
        end
      end


    end

  end

end
