require "test_helper"

class NestedClassTest < ActiveSupport::TestCase  # :nodoc:
  module Foo
    def self.table_name_prefix
      "foo_"
    end
    class Bar < ActiveRecord::Base
      establish_connection YAML.load_file(ActiveSupport::TestCase::DATABASE_CONFIG_PATH)
    end
  end

  def test_nested_model
    Foo::Bar.connection.create_table(:foo_bars, force: true) do |t|
      t.column "latlon", :st_point, srid: 3785
    end
    assert_empty Foo::Bar.all
    Foo::Bar.connection.drop_table(:foo_bars)
  end
end
