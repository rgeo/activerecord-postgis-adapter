source "https://rubygems.org"

# Specify your gem's dependencies in activerecord-postgis-adapter.gemspec
gemspec

gem "pg", "~> 1.0", platform: :ruby
gem "byebug" if ENV["BYEBUG"]
# Need to install for tests
gem "activerecord", github: "rails/rails", tag: "v7.2.0.beta2"

group :development do
  # Gems used by the ActiveRecord test suite
  gem "bcrypt"
  gem "sqlite3"
  gem "msgpack"
end
