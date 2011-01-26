# -----------------------------------------------------------------------------
# 
# PostGIS adapter for ActiveRecord
# 
# -----------------------------------------------------------------------------
# Copyright 2010 Daniel Azuma
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


module ActiveRecord
    
  module ConnectionAdapters
    
    module PostGISAdapter
      
      
      class MainAdapter < PostgreSQLAdapter
        
        
        ADAPTER_NAME = 'PostGIS'.freeze
        
        SPATIAL_COLUMN_CONSTRUCTORS = ::RGeo::ActiveRecord::DEFAULT_SPATIAL_COLUMN_CONSTRUCTORS.merge(
          :geography => {:type => 'geometry', :geographic => true},
        )
        
        @@native_database_types = nil
        
        
        def adapter_name
          ADAPTER_NAME
        end
        
        
        def spatial_column_constructor(name_)
          SPATIAL_COLUMN_CONSTRUCTORS[name_]
        end
        
        
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
          if ::RGeo::Feature::Geometry.check_type(value_)
            "'#{::RGeo::WKRep::WKBGenerator.new(:hex_format => true, :type_format => :ewkb, :emit_ewkb_srid => true).generate(value_)}'"
          else
            super
          end
        end
        
        
        def columns(table_name_, name_=nil)  #:nodoc:
          table_name_ = table_name_.to_s
          spatial_info_ = spatial_column_info(table_name_)
          column_definitions(table_name_).collect do |name_, type_, default_, notnull_|
            SpatialColumn.new(name_, default_, type_, notnull_ == 'f', type_ =~ /geometry/i ? spatial_info_[name_] : nil)
          end
        end
        
        
        def create_table(table_name_, options_={})
          table_name_ = table_name_.to_s
          table_definition_ = SpatialTableDefinition.new(self)
          table_definition_.primary_key(options_[:primary_key] || ::ActiveRecord::Base.get_primary_key(table_name_.singularize)) unless options_[:id] == false
          yield table_definition_ if block_given?
          if options_[:force] && table_exists?(table_name_)
            drop_table(table_name_, options_)
          end
          
          create_sql_ = "CREATE#{' TEMPORARY' if options_[:temporary]} TABLE "
          create_sql_ << "#{quote_table_name(table_name_)} ("
          create_sql_ << table_definition_.to_sql
          create_sql_ << ") #{options_[:options]}"
          execute create_sql_
          
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
        
        
        def drop_table(table_name_, options_={})
          execute("DELETE from geometry_columns where f_table_name='#{quote_string(table_name_.to_s)}'")
          super
        end
        
        
        def add_column(table_name_, column_name_, type_, options_={})
          table_name_ = table_name_.to_s
          if (info_ = spatial_column_constructor(type_.to_sym))
            limit_ = options_[:limit]
            options_.merge!(limit_) if limit_.is_a?(::Hash)
            type_ = (options_[:type] || info_[:type] || type_).to_s.gsub('_', '').upcase
            has_z_ = options_[:has_z]
            has_m_ = options_[:has_m]
            srid_ = (options_[:srid] || 4326).to_i
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
              execute("SELECT AddGeometryColumn('#{quote_string(table_name_)}', '#{quote_string(column_name_.to_s)}', #{srid_}, '#{quote_string(type_)}', #{dimensions_})")
            end
          else
            super
          end
        end
        
        
        def remove_column(table_name_, *column_names_)
          column_names_ = column_names_.flatten.map{ |n_| n_.to_s }
          spatial_info_ = spatial_column_info(table_name_)
          remaining_column_names_ = []
          column_names_.each do |name_|
            if spatial_info_.include?(name_)
              execute("SELECT DropGeometryColumn('#{quote_string(table_name_.to_s)}','#{quote_string(name_)}')")
            else
              remaining_column_names_ << name_.to_sym
            end
          end
          if remaining_column_names_.size > 0
            super(table_name_, *remaining_column_names_)
          end
        end
        
        
        def add_index(table_name_, column_name_, options_={})
          table_name_ = table_name_.to_s
          column_names_ = ::Array.wrap(column_name_)
          index_name_ = index_name(table_name_, :column => column_names_)
          gist_clause_ = ''
          index_type_ = ''
          if ::Hash === options_  # legacy support, since this param was a string
            index_type_ = 'UNIQUE' if options_[:unique]
            index_name_ = options_[:name].to_s if options_.key?(:name)
            gist_clause_ = 'USING GIST' if options_[:spatial]
          else
            index_type_ = options_
          end
          if index_name_.length > index_name_length
            raise ::ArgumentError, "Index name '#{index_name_}' on table '#{table_name_}' is too long; the limit is #{index_name_length} characters"
          end
          if index_name_exists?(table_name_, index_name_, false)
            raise ::ArgumentError, "Index name '#{index_name_}' on table '#{table_name_}' already exists"
          end
          quoted_column_names_ = quoted_columns_for_index(column_names_, options_).join(", ")
          execute "CREATE #{index_type_} INDEX #{quote_column_name(index_name_)} ON #{quote_table_name(table_name_)} #{gist_clause_} (#{quoted_column_names_})"
        end
        
        
        def spatial_column_info(table_name_)
          info_ = query("SELECT * FROM geometry_columns WHERE f_table_name='#{quote_string(table_name_.to_s)}'")
          result_ = {}
          info_.each do |row_|
            name_ = row_[3]
            type_ = row_[6]
            dimension_ = row_[4].to_i
            has_m_ = type_ =~ /m$/i ? true : false
            type_.sub!(/m$/, '')
            has_z_ = dimension_ > 3 || dimension_ == 3 && !has_m_
            result_[name_] = {
              :name => name_,
              :type => type_,
              :dimension => dimension_,
              :srid => row_[5].to_i,
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
