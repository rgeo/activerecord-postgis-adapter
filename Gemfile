source "https://rubygems.org"

# Specify your gem's dependencies in activerecord-postgis-adapter.gemspec
gemspec

gem "pg", "~> 1.0", platform: :ruby
gem "activerecord-jdbcpostgresql-adapter", platform: :jruby
gem "ffi-geos", platform: :jruby
gem "byebug" if ENV["BYEBUG"]

def activerecord_version
  return ENV["AR_VERSION"] if ENV["AR_VERSION"]

  require "uri"
  require "yaml"
  require "net/http"

  # read gemspec to get activerecord version spec
  # pull all activerecord versions from rubygems
  # find the newest version that matches the version from our gemspec
  gs = Bundler.load_gemspec("activerecord-postgis-adapter.gemspec")
  ar_dep = gs.dependencies.find { |d| d.name == "activerecord" }

  uri = URI("https://rubygems.org/api/v1/versions/activerecord.yaml")
  res = Net::HTTP.get_response(uri)
  versions = YAML.safe_load(res.body)
  ver = versions.find { |v| ar_dep.match?("activerecord", v["number"]) }

  raise Bundler::GemNotFound, "No matching Activerecord version found for #{ar_dep.requirement}" unless ver

  ver["number"]
end

group :development do
  # Need to install for tests
  gem "rails", git: "https://github.com/rails/rails.git", tag: "v#{activerecord_version}"

  # Gems used by the ActiveRecord test suite
  gem "bcrypt"
  gem "mocha"
  gem "sqlite3"
end
