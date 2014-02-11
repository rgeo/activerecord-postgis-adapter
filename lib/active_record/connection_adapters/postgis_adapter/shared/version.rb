begin
  require 'versionomy'
rescue ::LoadError
end


module ActiveRecord

  module ConnectionAdapters

    module PostGISAdapter


      # Current version of PostGISAdapter as a frozen string
      VERSION_STRING = ::File.read(::File.expand_path('../../../../../Version', ::File.dirname(__FILE__))).strip.freeze

      # Current version of PostGISAdapter as a Versionomy object, if the
      # Versionomy gem is available; otherwise equal to VERSION_STRING.
      VERSION = defined?(::Versionomy) ? ::Versionomy.parse(VERSION_STRING) : VERSION_STRING


    end

  end

end
