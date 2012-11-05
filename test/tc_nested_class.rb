# -----------------------------------------------------------------------------
#
# Tests for the PostGIS ActiveRecord adapter
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

require 'test/unit'
require 'rgeo/active_record/adapter_test_helper'


module RGeo
  module ActiveRecord  # :nodoc:
    module PostGISAdapter  # :nodoc:
      module Tests  # :nodoc:

        class TestNestedClass < ::Test::Unit::TestCase  # :nodoc:

          DATABASE_CONFIG_PATH = ::File.dirname(__FILE__)+'/database.yml'
          include AdapterTestHelper


          module Foo
            def self.table_name_prefix
              'foo_'
            end
            class Bar < ::ActiveRecord::Base
            end
          end


          define_test_methods do


            def test_nested_model
              Foo::Bar.class_eval do
                establish_connection(TestNestedClass::DATABASE_CONFIG)
              end
              Foo::Bar.connection.create_table(:foo_bars) do |t_|
                t_.column 'latlon', :point, :srid => 3785
              end
              Foo::Bar.all
              Foo::Bar.connection.drop_table(:foo_bars)
            end


          end

        end

      end
    end
  end
end
