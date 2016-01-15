require "./lib/active_record/connection_adapters/postgis/version.rb"

Gem::Specification.new do |spec|
  spec.name = "activerecord-postgis-adapter"
  spec.summary = "ActiveRecord adapter for PostGIS, based on RGeo."
  spec.description =
   "ActiveRecord connection adapter for PostGIS. It is based on the stock PostgreSQL adapter, and adds " \
   "built-in support for the spatial extensions provided by PostGIS. It uses the RGeo library to represent " \
   "spatial data in Ruby."

  spec.version = ActiveRecord::ConnectionAdapters::PostGIS::VERSION
  spec.author = "Daniel Azuma, Tee Parham"
  spec.email = "dazuma@gmail.com, parhameter@gmail.com"
  spec.homepage = "http://github.com/rgeo/activerecord-postgis-adapter"
  spec.licenses = ["BSD"]

  spec.files = Dir["lib/**/*", "LICENSE.txt"]
  spec.platform = Gem::Platform::RUBY

  spec.required_ruby_version = ">= 2.2.2"

  spec.add_dependency "activerecord", "~> 5.0.0.beta"
  spec.add_dependency "rgeo-activerecord", "~> 5.0.0.beta"

  spec.add_development_dependency "rake", "~> 10.4"
  spec.add_development_dependency "minitest", "~> 5.4"
  spec.add_development_dependency "mocha", "~> 1.1"
  spec.add_development_dependency "appraisal", "~> 2.0"
end
