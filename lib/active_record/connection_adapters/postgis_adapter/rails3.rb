# -----------------------------------------------------------------------------
#
# PostGIS adapter for Rails 3.x
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


require 'active_record/connection_adapters/postgresql_adapter'


require 'active_record/connection_adapters/postgis_adapter/rails3/main_adapter.rb'
require 'active_record/connection_adapters/postgis_adapter/rails3/spatial_table_definition.rb'
require 'active_record/connection_adapters/postgis_adapter/rails3/spatial_column.rb'
require 'active_record/connection_adapters/postgis_adapter/rails3/arel_tosql.rb'


if defined?(::RUBY_ENGINE) && ::RUBY_ENGINE == 'jruby'
  require 'active_record/connection_adapters/postgis_adapter/rails3/jdbc_connection'
else
  require 'active_record/connection_adapters/postgis_adapter/rails3/pg_connection'
end


if defined?(::Rails::Railtie)
  require 'active_record/connection_adapters/postgis_adapter/rails3/railtie.rb'
end


ignore_tables_ = ::ActiveRecord::SchemaDumper.ignore_tables
ignore_tables_ << 'geometry_columns' unless ignore_tables_.include?('geometry_columns')
ignore_tables_ << 'spatial_ref_sys' unless ignore_tables_.include?('spatial_ref_sys')
ignore_tables_ << 'layer' unless ignore_tables_.include?('layer')
ignore_tables_ << 'topology' unless ignore_tables_.include?('topology')
