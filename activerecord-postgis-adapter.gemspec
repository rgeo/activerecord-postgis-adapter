::Gem::Specification.new do |s_|
  s_.name = 'activerecord-postgis-adapter'
  s_.summary = 'An ActiveRecord adapter for PostGIS, based on RGeo.'
  s_.description = "This is an ActiveRecord connection adapter for PostGIS. It is based on the stock PostgreSQL adapter, but provides built-in support for the spatial extensions provided by PostGIS. It uses the RGeo library to represent spatial data in Ruby."
  s_.version = "#{::File.read('Version').strip}.nonrelease"
  s_.author = 'Daniel Azuma'
  s_.email = 'dazuma@gmail.com'
  s_.homepage = "http://dazuma.github.com/activerecord-postgis-adapter"
  s_.licenses = ['BSD']
  s_.required_ruby_version = '>= 2.0.0'
  s_.files = ::Dir.glob("lib/**/*.{rb,rake}") +
    ::Dir.glob("test/**/*.rb") +
    ::Dir.glob("*.rdoc") +
    ['Version', 'LICENSE.txt']
  s_.extra_rdoc_files = ::Dir.glob("*.rdoc")
  s_.test_files = ::Dir.glob("test/**/tc_*.rb")
  s_.platform = ::Gem::Platform::RUBY
  s_.add_dependency('rgeo-activerecord', '~> 0.5.0')

  s_.add_development_dependency('rake')
  s_.add_development_dependency('minitest')
  s_.add_development_dependency('rdoc')
end
