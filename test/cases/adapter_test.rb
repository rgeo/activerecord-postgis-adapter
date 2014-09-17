require_relative 'helper'

class AdapterTest < ActiveSupport::TestCase  # :nodoc:
  def test_rgeo_extension
    assert RGeo::Geos.supported?
  end

  def test_ignore_tables
    assert_includes ActiveRecord::SchemaDumper.ignore_tables, 'geometry_columns'
    assert_includes ActiveRecord::SchemaDumper.ignore_tables, 'spatial_ref_sys'
    assert_includes ActiveRecord::SchemaDumper.ignore_tables, 'layer'
    assert_includes ActiveRecord::SchemaDumper.ignore_tables, 'topology'
  end

  def test_version
    refute_nil ActiveRecord::ConnectionAdapters::PostGIS::VERSION
  end

  def test_postgis_available
    connection = ActiveRecord::Base.connection
    assert_equal 'PostGIS', connection.adapter_name
    refute_nil connection.postgis_lib_version
  end
end
