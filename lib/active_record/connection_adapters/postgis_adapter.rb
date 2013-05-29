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


# The activerecord-postgis-adapter gem installs the *postgis*
# connection adapter into ActiveRecord.

module ActiveRecord

  # All ActiveRecord adapters go in this namespace.
  # This adapter is installed into the PostGISAdapter submodule.
  module ConnectionAdapters

    # The PostGIS Adapter lives in this namespace.
    module PostGISAdapter

      # The name returned by the adapter_name method of this adapter.
      ADAPTER_NAME = 'PostGIS'.freeze

    end

  end


end


# :stopdoc:

require 'active_record'
require 'active_record/connection_adapters/postgresql_adapter'
require 'rgeo/active_record'

case ::ActiveRecord::VERSION::MAJOR
when 3
  require 'active_record/connection_adapters/postgis_adapter/shared/version.rb'
  require 'active_record/connection_adapters/postgis_adapter/shared/common_adapter_methods.rb'
  require 'active_record/connection_adapters/postgis_adapter/rails3/main_adapter.rb'
  require 'active_record/connection_adapters/postgis_adapter/rails3/spatial_table_definition.rb'
  require 'active_record/connection_adapters/postgis_adapter/rails3/spatial_column.rb'
  require 'active_record/connection_adapters/postgis_adapter/shared/arel_tosql.rb'
  require 'active_record/connection_adapters/postgis_adapter/shared/setup.rb'
  require 'active_record/connection_adapters/postgis_adapter/rails3/create_connection'
when 4

  # TEMP
  if defined?(::RUBY_ENGINE) && ::RUBY_ENGINE == 'jruby'
    raise "**** Sorry, activerecord-postgis-adapter does not yet support Rails 4 on JRuby ****"
  end

  require 'active_record/connection_adapters/postgis_adapter/shared/version.rb'
  require 'active_record/connection_adapters/postgis_adapter/shared/common_adapter_methods.rb'
  require 'active_record/connection_adapters/postgis_adapter/rails4/main_adapter.rb'
  require 'active_record/connection_adapters/postgis_adapter/rails4/spatial_table_definition.rb'
  require 'active_record/connection_adapters/postgis_adapter/rails4/spatial_column.rb'
  require 'active_record/connection_adapters/postgis_adapter/shared/arel_tosql.rb'
  require 'active_record/connection_adapters/postgis_adapter/shared/setup.rb'
  require 'active_record/connection_adapters/postgis_adapter/rails4/create_connection'
  require 'active_record/connection_adapters/postgis_adapter/rails4/postgis_database_tasks.rb'
else
  raise "Unsupported ActiveRecord version #{::ActiveRecord::VERSION::STRING}"
end

::ActiveRecord::ConnectionAdapters::PostGISAdapter.initial_setup

if defined?(::Rails::Railtie)
  load ::File.expand_path('postgis_adapter/shared/railtie.rb', ::File.dirname(__FILE__))
end

# :startdoc:
