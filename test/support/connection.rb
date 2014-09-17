require 'yaml'
require 'fileutils'
require 'pathname'
require 'active_support/logger'

module ARTest
  extend self
  def config
    @config ||= read_config
  end

  def connect
    ActiveRecord::Base.logger = ActiveSupport::Logger.new('debug.log', 0, 100 * 1024 * 1024)
    ActiveRecord::Base.configurations = config
    ActiveRecord::Base.establish_connection :default_env
  end

  def load_schema
    load File.expand_path('../../schema/schema.rb', __FILE__)
  end


  private

  def config_file
    Pathname.new(File.expand_path('../../database.yml',__FILE__))
  end

  def read_config
    unless config_file.exist?
      example_config = File.expand_path('../../database.example.yml',__FILE__)
      FileUtils.cp example_config, config_file
    end

    YAML.load_file(config_file)
  end
end
