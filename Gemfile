source "https://rubygems.org"

# Specify your gem's dependencies in activerecord-postgis-adapter.gemspec
gemspec

gem 'pg', '~> 0.17', platform: :ruby
gem 'activerecord-jdbcpostgresql-adapter', '~> 1.3.9', platform: :jruby
gem 'ffi-geos', platform: :jruby
gem 'byebug', platform: :mri_22

# Temporary for Rails 5 alpha support
gem 'rgeo-activerecord', github: 'dzjuck/rgeo-activerecord', branch: 'rails_5'
gem 'activerecord', '>= 5.0.0.alpha', github: 'rails/rails'
gem 'arel', '>=7.0.0.alpha', github: 'rails/arel'