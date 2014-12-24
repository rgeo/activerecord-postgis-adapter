require_relative 'test_helper'

class SchemaDumperTest < ActiveSupport::TestCase

  def test_schema
    schema = capture(:stdout) do
      ActiveRecord::SchemaDumper.dump
    end
    assert_match /t.string/, schema
    assert_match /t.text/, schema
    assert_match /t.st_line_string/, schema
    assert_match /t.polygon/, schema
    assert_match /t.st_geometry/, schema
  end

end