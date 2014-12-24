require_relative 'test_helper'

class ArelTest < ActiveSupport::TestCase
  def test_postgis_visitor
    assert_equal Arel::Visitors::PostGIS, Arel::Visitors::VISITORS['postgis']
  end
end
