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

      TableDefinitionSuperclass = if defined?(ConnectionAdapters::PostgreSQLAdapter::TableDefinition)
        ConnectionAdapters::PostgreSQLAdapter::TableDefinition
      else
        ConnectionAdapters::TableDefinition
      end

      class SpatialTableDefinition < TableDefinitionSuperclass  # :nodoc:

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
          super(name_, type_, options_)
          if type_ == :spatial
            col_ = self[name_]
            col_.extend(SpatialColumnDefinitionMethods) unless col_.respond_to?(:geographic?)
            options_.merge!(col_.limit) if col_.limit.is_a?(::Hash)
            col_.set_spatial_type(options_[:type])
            col_.set_geographic(options_[:geographic])
            col_.set_srid(options_[:srid])
            col_.set_has_z(options_[:has_z])
            col_.set_has_m(options_[:has_m])
          end
          self
        end

        def to_sql
          @columns.find_all{ |c_| !c_.respond_to?(:geographic?) || c_.geographic? }.map{ |c_| c_.to_sql } * ', '
        end

        def non_geographic_spatial_columns
          @columns.find_all{ |c_| c_.respond_to?(:geographic?) && !c_.geographic? }
        end

      end


      module SpatialColumnDefinitionMethods  # :nodoc:

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

        def sql_type
          type_ = spatial_type.upcase.gsub('_', '')
          type_ << 'Z' if has_z?
          type_ << 'M' if has_m?
          "GEOGRAPHY(#{type_},#{srid})"
        end

      end


    end

  end

end
