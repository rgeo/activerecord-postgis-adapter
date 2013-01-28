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


# :stopdoc:

module ActiveRecord

  module ConnectionAdapters

    module PostGISAdapter


      class SpatialColumn < ConnectionAdapters::PostgreSQLColumn


        FACTORY_SETTINGS_CACHE = {}


        def initialize(factory_settings_, table_name_, name_, default_, sql_type_=nil, null_=true, opts_=nil)
          @factory_settings = factory_settings_
          @table_name = table_name_
          @geographic = sql_type_ =~ /geography/i ? true : false
          if opts_
            # This case comes from an entry in the geometry_columns table
            @geometric_type = ::RGeo::ActiveRecord.geometric_type_from_name(opts_[:type]) ||
              ::RGeo::Feature::Geometry
            @srid = opts_[:srid].to_i
            @has_z = opts_[:has_z] ? true : false
            @has_m = opts_[:has_m] ? true : false
          elsif @geographic
            # Geographic type information is embedded in the SQL type
            @geometric_type = ::RGeo::Feature::Geometry
            @srid = 4326
            @has_z = @has_m = false
            if sql_type_ =~ /geography\((.*)\)$/i
              params_ = $1.split(',')
              if params_.size >= 2
                if params_.first =~ /([a-z]+[^zm])(z?)(m?)/i
                  @has_z = $2.length > 0
                  @has_m = $3.length > 0
                  @geometric_type = ::RGeo::ActiveRecord.geometric_type_from_name($1)
                end
                if params_.last =~ /(\d+)/
                  @srid = $1.to_i
                end
              end
            end
          elsif sql_type_ =~ /geography|geometry|point|linestring|polygon/i
            # Just in case there is a geometry column with no geometry_columns entry.
            @geometric_type = ::RGeo::Feature::Geometry
            @srid = @has_z = @has_m = nil
          else
            # Non-spatial column
            @geometric_type = @has_z = @has_m = @srid = nil
          end
          super(name_, default_, sql_type_, null_)
          if type == :spatial
            if @srid
              @limit = {:srid => @srid, :type => @geometric_type.type_name.underscore}
              @limit[:has_z] = true if @has_z
              @limit[:has_m] = true if @has_m
              @limit[:geographic] = true if @geographic
            else
              @limit = {:no_constraints => true}
            end
          end
          FACTORY_SETTINGS_CACHE[factory_settings_.object_id] = factory_settings_
        end


        attr_reader :geographic
        attr_reader :srid
        attr_reader :geometric_type
        attr_reader :has_z
        attr_reader :has_m

        alias_method :geographic?, :geographic
        alias_method :has_z?, :has_z
        alias_method :has_m?, :has_m


        def spatial?
          type == :spatial
        end


        def has_spatial_constraints?
          !@srid.nil?
        end


        def klass
          type == :spatial ? ::RGeo::Feature::Geometry : super
        end


        def type_cast(value_)
          if type == :spatial
            SpatialColumn.convert_to_geometry(value_, @factory_settings, @table_name, name,
              @geographic, @srid, @has_z, @has_m)
          else
            super
          end
        end


        def type_cast_code(var_name_)
          if type == :spatial
            "::ActiveRecord::ConnectionAdapters::PostGISAdapter::SpatialColumn.convert_to_geometry("+
              "#{var_name_}, ::ActiveRecord::ConnectionAdapters::PostGISAdapter::SpatialColumn::"+
              "FACTORY_SETTINGS_CACHE[#{@factory_settings.object_id}], #{@table_name.inspect}, "+
              "#{name.inspect}, #{@geographic ? 'true' : 'false'}, #{@srid.inspect}, "+
              "#{@has_z ? 'true' : 'false'}, #{@has_m ? 'true' : 'false'})"
          else
            super
          end
        end


        private


        def simplified_type(sql_type_)
          sql_type_ =~ /geography|geometry|point|linestring|polygon/i ? :spatial : super
        end


        def self.convert_to_geometry(input_, factory_settings_, table_name_, column_, geographic_, srid_, has_z_, has_m_)
          if srid_
            constraints_ = {:geographic => geographic_, :has_z_coordinate => has_z_,
              :has_m_coordinate => has_m_, :srid => srid_}
          else
            constraints_ = nil
          end
          if ::RGeo::Feature::Geometry === input_
            factory_ = factory_settings_.get_column_factory(table_name_, column_, constraints_)
            ::RGeo::Feature.cast(input_, factory_) rescue nil
          elsif input_.respond_to?(:to_str)
            input_ = input_.to_str
            if input_.length == 0
              nil
            else
              factory_ = factory_settings_.get_column_factory(table_name_, column_, constraints_)
              marker_ = input_[0,1]
              if marker_ == "\x00" || marker_ == "\x01" || input_[0,4] =~ /[0-9a-fA-F]{4}/
                ::RGeo::WKRep::WKBParser.new(factory_, :support_ewkb => true).parse(input_) rescue nil
              else
                ::RGeo::WKRep::WKTParser.new(factory_, :support_ewkt => true).parse(input_) rescue nil
              end
            end
          else
            nil
          end
        end


      end


    end

  end

end

# :startdoc:
