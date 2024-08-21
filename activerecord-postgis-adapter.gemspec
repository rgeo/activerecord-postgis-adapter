require_relative "lib/active_record/connection_adapters/postgis/version"

Gem::Specification.new do |spec|
  spec.name = "activerecord-postgis-adapter"
  spec.summary = "ActiveRecord adapter for PostGIS, based on RGeo."
  spec.description =
    "ActiveRecord connection adapter for PostGIS. It is based on the stock " \
    "PostgreSQL adapter, and adds built-in support for the spatial extensions "\
    "provided by PostGIS. It uses the RGeo library to represent spatial data in Ruby."

  spec.version = ActiveRecord::ConnectionAdapters::PostGIS::VERSION
  spec.authors = ["Daniel Azuma", "Tee Parham"]
  spec.email = ["dazuma@gmail.com", "parhameter@gmail.com", "kfdoggett@gmail.com"]
  spec.homepage = "http://github.com/rgeo/activerecord-postgis-adapter"
  spec.license = "BSD-3-Clause"

  spec.files = Dir["lib/**/*", "LICENSE.txt"]
  spec.platform = Gem::Platform::RUBY

  spec.required_ruby_version = ">= 3.1.0"

  spec.add_dependency "activerecord", "~> 7.2.0"
  spec.add_dependency "rgeo-activerecord", "~> 7.0.0"

  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "minitest", "~> 5.4"
  spec.add_development_dependency "mocha", "~> 2.4"
  spec.add_development_dependency "benchmark-ips", "~> 2.12"
  spec.add_development_dependency "rubocop", "~> 1.50"

  spec.metadata = {
    "rubygems_mfa_required" => "true"
  }
end
