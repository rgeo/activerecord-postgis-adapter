source "https://rubygems.org"

# Specify your gem's dependencies in activerecord-postgis-adapter.gemspec
gemspec

gem "pg", "~> 1.0", platform: :ruby
gem "byebug" if ENV["BYEBUG"]
gem "tracer"

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
# Need to install for tests
gem "rails", github: "rails/rails", tag: "v#{activerecord_version}"

group :development do
  gem "minitest-excludes", "~> 2.0"

  # Gems used by the ActiveRecord test suite
  gem "bcrypt"
  gem "sqlite3"
  gem "msgpack"

  # Still used a little bit in our tests.
  # TODO: get rid of the dependency
  gem "mocha"
end
