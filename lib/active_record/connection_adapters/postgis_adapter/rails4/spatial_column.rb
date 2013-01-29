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


        def initialize(factory_settings_, table_name_, name_, default_, oid_type_, sql_type_=nil, null_=true, opts_=nil)
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
          super(name_, default_, oid_type_, sql_type_, null_)
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


      # Register spatial types with the postgres OID mechanism
      # so we can recognize custom columns coming from the database.

      class SpatialOID < PostgreSQLAdapter::OID::Type

        def initialize(factory_generator_)
          @factory_generator = factory_generator_
        end

        def type_cast(value_)
          return if value_.nil?
          ::RGeo::WKRep::WKBParser.new(@factory_generator, :support_ewkb => true).parse(value_) rescue nil
        end

      end

      PostgreSQLAdapter::OID.register_type('geometry', SpatialOID.new(nil))
      PostgreSQLAdapter::OID.register_type('geography', SpatialOID.new(::RGeo::Geographic.method(:spherical_factory)))


      # This is a hack to ActiveRecord::ModelSchema. We have to "decorate" the decorate_columns
      # method to apply class-specific customizations to spatial type casting.

      module DecorateColumnsModification

        def decorate_columns(columns_hash_)
          columns_hash_ = super(columns_hash_)
          return unless columns_hash_
          canonical_columns_ = self.columns_hash
          columns_hash_.each do |name_, col_|
            if col_.is_a?(SpatialOID) && (canonical_ = canonical_columns_[name_]) && canonical_.spatial?
              columns_hash_[name_] = canonical_
            end
          end
          columns_hash_
        end

      end

      ::ActiveRecord::Base.extend(DecorateColumnsModification)


    end

  end

end

# :startdoc:
