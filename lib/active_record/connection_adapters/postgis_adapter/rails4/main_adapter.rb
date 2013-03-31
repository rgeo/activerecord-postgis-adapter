# -----------------------------------------------------------------------------
#
# PostGIS adapter for ActiveRecord
#
# -----------------------------------------------------------------------------
# Copyright 2010-2012 Daniel Azuma
#
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# * Redistributions of source code must retain the above copyright notice,
#   this list of conditions and the following disclaimer.
# * Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.
# * Neither the name of the copyright holder, nor the names of any other
#   contributors to this software, may be used to endorse or promote products
#   derived from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
# -----------------------------------------------------------------------------
;


module ActiveRecord  # :nodoc:

  module ConnectionAdapters  # :nodoc:

    module PostGISAdapter  # :nodoc:


      class MainAdapter < PostgreSQLAdapter  # :nodoc:


        SPATIAL_COLUMN_CONSTRUCTORS = ::RGeo::ActiveRecord::DEFAULT_SPATIAL_COLUMN_CONSTRUCTORS.merge(
          :geography => {:type => 'geometry', :geographic => true}
        )

        @@native_database_types = nil


        # Overridden to change the visitor

        def initialize(*args_)
          super
          @visitor = ::Arel::Visitors::PostGIS.new(self)
        end


        def set_rgeo_factory_settings(factory_settings_)
          @rgeo_factory_settings = factory_settings_
        end


        def adapter_name
          PostGISAdapter::ADAPTER_NAME
        end


        def spatial_column_constructor(name_)
          SPATIAL_COLUMN_CONSTRUCTORS[name_]
        end


        # Overridden to add the :spatial type

        def native_database_types
          @@native_database_types ||= super.merge(:spatial => {:name => 'geometry'})
        end


        def postgis_lib_version
          unless defined?(@postgis_lib_version)
            @postgis_lib_version = select_value("SELECT PostGIS_Lib_Version()") rescue nil
          end
          @postgis_lib_version
        end


        def srs_database_columns
          {:srtext_column => 'srtext', :proj4text_column => 'proj4text', :auth_name_column => 'auth_name', :auth_srid_column => 'auth_srid'}
        end


        def quote(value_, column_=nil)
          # Overridden to recognize geometry types
          if ::RGeo::Feature::Geometry.check_type(value_)
            "'#{::RGeo::WKRep::WKBGenerator.new(:hex_format => true, :type_format => :ewkb, :emit_ewkb_srid => true).generate(value_)}'"
          elsif value_.is_a?(::RGeo::Cartesian::BoundingBox)
            "'#{value_.min_x},#{value_.min_y},#{value_.max_x},#{value_.max_y}'::box"
          else
            super
          end
        end


        def type_cast(value_, column_, array_member_=false)
          # Overridden to recognize geometry types
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
            # JDBC support: JDBC adapter returns a hash for column definitions,
            # instead of an array of values.
            if col_name_.kind_of?(::Hash)
              notnull_ = col_name_["column_not_null"]
              default_ = col_name_["column_default"]
              type_ = col_name_["column_type"]
              col_name_ = col_name_["column_name"]
              # TODO: get oid and fmod from jdbc
            end
            oid_ = OID::TYPE_MAP.fetch(oid_.to_i, fmod_.to_i) {
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


        def table_definition
          # Override to create a spatial table definition
          SpatialTableDefinition.new(self)
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


        def drop_table(table_name_, *options_)
          if postgis_lib_version.to_s.split('.').first.to_i == 1
            execute("DELETE from geometry_columns where f_table_name='#{quote_string(table_name_.to_s)}'")
          end
          super
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
              srid_ = (options_[:srid] || -1).to_i
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
