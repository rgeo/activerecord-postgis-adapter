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


      SPATIAL_COLUMN_CONSTRUCTORS = ::RGeo::ActiveRecord::DEFAULT_SPATIAL_COLUMN_CONSTRUCTORS.merge(
        :geography => {:type => 'geometry', :geographic => true}
      )


      module CommonAdapterMethods  # :nodoc:


        def set_rgeo_factory_settings(factory_settings_)
          @rgeo_factory_settings = factory_settings_
        end


        def adapter_name
          PostGISAdapter::ADAPTER_NAME
        end


        def spatial_column_constructor(name_)
          PostGISAdapter::SPATIAL_COLUMN_CONSTRUCTORS[name_]
        end


        def postgis_lib_version
          unless defined?(@postgis_lib_version)
            @postgis_lib_version = select_value("SELECT PostGIS_Lib_Version()") rescue nil
          end
          @postgis_lib_version
        end


        def default_srid
          unless defined?(@default_srid)
            case postgis_lib_version
            when nil
              @default_srid = nil
            when /^1/
              @default_srid = -1
            else
              @default_srid = 0
            end
          end
          @default_srid
        end


        def srs_database_columns
          {:srtext_column => 'srtext', :proj4text_column => 'proj4text', :auth_name_column => 'auth_name', :auth_srid_column => 'auth_srid'}
        end


        def quote(value_, column_=nil)
          if ::RGeo::Feature::Geometry.check_type(value_)
            "'#{::RGeo::WKRep::WKBGenerator.new(:hex_format => true, :type_format => :ewkb, :emit_ewkb_srid => true).generate(value_)}'"
          elsif value_.is_a?(::RGeo::Cartesian::BoundingBox)
            "'#{value_.min_x},#{value_.min_y},#{value_.max_x},#{value_.max_y}'::box"
          else
            super
          end
        end


      end


    end

  end

end
