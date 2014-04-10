module ActiveRecord  # :nodoc:

  module ConnectionAdapters  # :nodoc:

    module PostGISAdapter  # :nodoc:


      class TableDefinition < ConnectionAdapters::PostgreSQLAdapter::TableDefinition  # :nodoc:

        def initialize(types_, name_, temporary_, options_, as_, base_)
          @base = base_
          @spatial_columns_hash = {}
          super(types_, name_, temporary_, options_, as_)
        end

        def column(name_, type_, options_={})
          if (info_ = @base.spatial_column_constructor(type_.to_sym))
            type_ = options_[:type] || info_[:type] || type_
            if type_.to_s == 'geometry' &&
              (options_[:no_constraints] ||
               options_[:limit].is_a?(::Hash) && options_[:limit][:no_constraints])
            then
              options_.delete(:limit)
            else
              options_[:type] = type_
              type_ = :spatial
            end
          end
          if type_ == :spatial
            if (limit_ = options_.delete(:limit))
              options_.merge!(limit_) if limit_.is_a?(::Hash)
            end
            if options_[:geographic]
              type_ = :geography
              spatial_type_ = (options_[:type] || 'geometry').to_s.upcase.gsub('_', '')
              spatial_type_ << 'Z' if options_[:has_z]
              spatial_type_ << 'M' if options_[:has_m]
              options_[:limit] = "#{spatial_type_},#{options_[:srid] || 4326}"
            end
            name_ = name_.to_s
            if primary_key_column_name == name_
              raise ArgumentError, "you can't redefine the primary key column '#{name_}'. To define a custom primary key, pass { id: false } to create_table."
            end
            col_ = new_column_definition(name_, type_, options_)
            col_.set_spatial_type(options_[:type])
            col_.set_geographic(options_[:geographic])
            col_.set_srid(options_[:srid])
            col_.set_has_z(options_[:has_z])
            col_.set_has_m(options_[:has_m])
            (col_.geographic? ? @columns_hash : @spatial_columns_hash)[name_] = col_
          else
            super(name_, type_, options_)
          end
          self
        end

        def create_column_definition(name_, type_)
          if type_ == :spatial || type_ == :geography
            PostGISAdapter::ColumnDefinition.new(name_, type_)
          else
            super
          end
        end

        def non_geographic_spatial_columns
          @spatial_columns_hash.values
        end

      end


      class ColumnDefinition < ConnectionAdapters::ColumnDefinition  # :nodoc:

        def spatial_type
          @spatial_type
        end

        def geographic?
          @geographic
        end

        def srid
          @srid ? @srid.to_i : (geographic? ? 4326 : -1)
        end

        def has_z?
          @has_z
        end

        def has_m?
          @has_m
        end

        def set_geographic(value_)
          @geographic = value_ ? true : false
        end

        def set_spatial_type(value_)
          @spatial_type = value_.to_s
        end

        def set_srid(value_)
          @srid = value_
        end

        def set_has_z(value_)
          @has_z = value_ ? true : false
        end

        def set_has_m(value_)
          @has_m = value_ ? true : false
        end

      end


    end

  end

end
