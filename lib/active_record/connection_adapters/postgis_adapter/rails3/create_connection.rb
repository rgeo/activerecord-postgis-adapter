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

  class Base  # :nodoc:

    class << self


      if defined?(::RUBY_ENGINE) && ::RUBY_ENGINE == 'jruby'


        require 'active_record/connection_adapters/jdbcpostgresql_adapter'
        require 'active_record/connection_adapters/postgis_adapter/shared/jdbc_compat'


        def postgis_connection(config_)
          ::ActiveRecord::ConnectionAdapters::PostGISAdapter.create_jdbc_connection(self, config_)
        end

        alias_method :jdbcpostgis_connection, :postgis_connection


      else


        require 'pg'


        # ActiveRecord looks for the postgis_connection factory method in
        # this class.
        #
        # Based on the default <tt>postgresql_connection</tt> definition from
        # ActiveRecord.

        def postgis_connection(config_)
          config_ = config_.symbolize_keys
          host_ = config_[:host]
          port_ = config_[:port] || 5432
          username_ = config_[:username].to_s if config_[:username]
          password_ = config_[:password].to_s if config_[:password]

          if config_.key?(:database)
            database_ = config_[:database]
          else
            raise ::ArgumentError, "No database specified. Missing argument: database."
          end

          # The postgres drivers don't allow the creation of an unconnected PGconn object,
          # so just pass a nil connection object for the time being.
          ::ActiveRecord::ConnectionAdapters::PostGISAdapter::MainAdapter.new(nil, logger, [host_, port_, nil, nil, database_, username_, password_], config_)
        end


      end


    end

  end

end
