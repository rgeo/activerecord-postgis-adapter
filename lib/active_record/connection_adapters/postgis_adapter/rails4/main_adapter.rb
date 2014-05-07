module ActiveRecord  # :nodoc:
  module ConnectionAdapters  # :nodoc:
    module PostGISAdapter  # :nodoc:
      class MainAdapter < PostgreSQLAdapter  # :nodoc:
        def initialize(*args_)
          # Overridden to change the visitor
          super
          @visitor = ::Arel::Visitors::PostGIS.new(self)
        end

        include PostGISAdapter::CommonAdapterMethods

        @@native_database_types = nil

        def native_database_types
          # Overridden to add the :spatial type
          @@native_database_types ||= super.merge(
            :spatial => {:name => 'geometry'},
            :geography => {:name => 'geography'})
        end

        def type_cast(value_, column_, array_member_=false)
          if ::RGeo::Feature::Geometry.check_type(value_)
            ::RGeo::WKRep::WKBGenerator.new(:hex_format => true, :type_format => :ewkb, :emit_ewkb_srid => true).generate(value_)
          else
            super
          end
        end

        def columns(table_name_, name_=nil)
          # FULL REPLACEMENT. RE-CHECK ON NEW VERSIONS.
          # We needed to return a spatial column subclass.
          table_name_ = table_name_.to_s
          spatial_info_ = spatial_column_info(table_name_)
          column_definitions(table_name_).collect do |col_name_, type_, default_, notnull_, oid_, fmod_|
            oid_ = type_map.fetch(oid_.to_i, fmod_.to_i) {
              OID::Identity.new
            }
            SpatialColumn.new(@rgeo_factory_settings, table_name_, col_name_, default_, oid_, type_,
              notnull_ == 'f', type_ =~ /geometry/i ? spatial_info_[col_name_] : nil)
          end
        end

        def indexes(table_name_, name_=nil)
          # FULL REPLACEMENT. RE-CHECK ON NEW VERSIONS.
          result_ = query(<<-SQL, 'SCHEMA')
            SELECT distinct i.relname, d.indisunique, d.indkey, pg_get_indexdef(d.indexrelid), t.oid
            FROM pg_class t
            INNER JOIN pg_index d ON t.oid = d.indrelid
            INNER JOIN pg_class i ON d.indexrelid = i.oid
            WHERE i.relkind = 'i'
              AND d.indisprimary = 'f'
              AND t.relname = '#{table_name_}'
              AND i.relnamespace IN (SELECT oid FROM pg_namespace WHERE nspname = ANY (current_schemas(false)) )
            ORDER BY i.relname
          SQL

          result_.map do |row_|
            index_name_ = row_[0]
            unique_ = row_[1] == 't'
            indkey_ = row_[2].split(" ")
            inddef_ = row_[3]
            oid_ = row_[4]

            columns_ = query(<<-SQL, "SCHEMA")
              SELECT a.attnum, a.attname, t.typname
                FROM pg_attribute a, pg_type t
              WHERE a.attrelid = #{oid_}
                AND a.attnum IN (#{indkey_.join(",")})
                AND a.atttypid = t.oid
            SQL
            columns_ = columns_.inject({}){ |h_, r_| h_[r_[0].to_s] = [r_[1], r_[2]]; h_ }
            column_names_ = columns_.values_at(*indkey_).compact.map{ |a_| a_[0] }

            # add info on sort order for columns (only desc order is explicitly specified, asc is the default)
            desc_order_columns_ = inddef_.scan(/(\w+) DESC/).flatten
            orders_ = desc_order_columns_.any? ? Hash[desc_order_columns_.map {|order_column_| [order_column_, :desc]}] : {}
            where_ = inddef_.scan(/WHERE (.+)$/).flatten[0]
            spatial_ = inddef_ =~ /using\s+gist/i && columns_.size == 1 &&
              (columns_.values.first[1] == 'geometry' || columns_.values.first[1] == 'geography')

            if column_names_.empty?
              nil
            else
              ::RGeo::ActiveRecord::SpatialIndexDefinition.new(table_name_, index_name_, unique_, column_names_, [], orders_, where_, spatial_ ? true : false)
            end
          end.compact
        end

<<<<<<< HEAD

=======
>>>>>>> rgeo/master
        def create_table_definition(name_, temporary_, options_, as_=nil)
          # Override to create a spatial table definition (post-4.0.0.beta1)
          PostGISAdapter::TableDefinition.new(native_database_types, name_, temporary_, options_, as_, self)
        end

        def create_table(table_name_, options_={}, &block_)
          table_name_ = table_name_.to_s
          # Call super and snag the table definition
          table_definition_ = nil
          super(table_name_, options_) do |td_|
            block_.call(td_) if block_
            table_definition_ = td_
          end
          table_definition_.non_geographic_spatial_columns.each do |col_|
            type_ = col_.spatial_type.gsub('_', '').upcase
            has_z_ = col_.has_z?
            has_m_ = col_.has_m?
            type_ = "#{type_}M" if has_m_ && !has_z_
            dimensions_ = 2
            dimensions_ += 1 if has_z_
            dimensions_ += 1 if has_m_
            execute("SELECT AddGeometryColumn('#{quote_string(table_name_)}', '#{quote_string(col_.name.to_s)}', #{col_.srid}, '#{quote_string(type_)}', #{dimensions_})")
          end
        end

        def add_column(table_name_, column_name_, type_, options_={})
          table_name_ = table_name_.to_s
          column_name_ = column_name_.to_s
          if (info_ = spatial_column_constructor(type_.to_sym))
            limit_ = options_[:limit]
            if type_.to_s == 'geometry' &&
              (options_[:no_constraints] || limit_.is_a?(::Hash) && limit_[:no_constraints])
            then
              options_.delete(:limit)
              super
            else
              options_.merge!(limit_) if limit_.is_a?(::Hash)
              type_ = (options_[:type] || info_[:type] || type_).to_s.gsub('_', '').upcase
              has_z_ = options_[:has_z]
              has_m_ = options_[:has_m]
              srid_ = (options_[:srid] || PostGISAdapter::DEFAULT_SRID).to_i
              if options_[:geographic]
                type_ << 'Z' if has_z_
                type_ << 'M' if has_m_
                execute("ALTER TABLE #{quote_table_name(table_name_)} ADD COLUMN #{quote_column_name(column_name_)} GEOGRAPHY(#{type_},#{srid_})")
                change_column_default(table_name_, column_name_, options_[:default]) if options_include_default?(options_)
                change_column_null(table_name_, column_name_, false, options_[:default]) if options_[:null] == false
              else
                type_ = "#{type_}M" if has_m_ && !has_z_
                dimensions_ = 2
                dimensions_ += 1 if has_z_
                dimensions_ += 1 if has_m_
                execute("SELECT AddGeometryColumn('#{quote_string(table_name_)}', '#{quote_string(column_name_)}', #{srid_}, '#{quote_string(type_)}', #{dimensions_})")
              end
            end
          else
            super
          end
        end

        def remove_column(table_name_, column_name_, type_=nil, options_={})
          table_name_ = table_name_.to_s
          column_name_ = column_name_.to_s
          spatial_info_ = spatial_column_info(table_name_)
          if spatial_info_.include?(column_name_)
            execute("SELECT DropGeometryColumn('#{quote_string(table_name_)}','#{quote_string(column_name_)}')")
          else
            super
          end
        end

        def add_index(table_name_, column_name_, options_={})
          # FULL REPLACEMENT. RE-CHECK ON NEW VERSIONS.
          # We have to fully-replace because of the gist_clause.
          options_ ||= {}
          gist_clause_ = options_.delete(:spatial) ? ' USING GIST' : ''
          index_name_, index_type_, index_columns_, index_options_ = add_index_options(table_name_, column_name_, options_)
          execute "CREATE #{index_type_} INDEX #{quote_column_name(index_name_)} ON #{quote_table_name(table_name_)}#{gist_clause_} (#{index_columns_})#{index_options_}"
        end

        def spatial_column_info(table_name_)
          info_ = query("SELECT f_geometry_column,coord_dimension,srid,type FROM geometry_columns WHERE f_table_name='#{quote_string(table_name_.to_s)}'")
          result_ = {}
          info_.each do |row_|
            name_ = row_[0]
            type_ = row_[3]
            dimension_ = row_[1].to_i
            has_m_ = type_ =~ /m$/i ? true : false
            type_.sub!(/m$/, '')
            has_z_ = dimension_ > 3 || dimension_ == 3 && !has_m_
            result_[name_] = {
              :name => name_,
              :type => type_,
              :dimension => dimension_,
              :srid => row_[2].to_i,
              :has_z => has_z_,
              :has_m => has_m_,
            }
          end
          result_
        end

      end
    end
  end
end
