require "bundler/gem_tasks"
require "rake/testtask"

task default: [:test]

Rake::TestTask.new(:test) do |t|
  t.libs << 'test'
  t.test_files = %w(test/**/*_test.rb)
  t.verbose = false
end

desc 'Run compatibility tests'
task :compatibility do
  sh "BUNDLE_GEMFILE=./travis/ar40.gemfile bundle"
  sh "BUNDLE_GEMFILE=./travis/ar40.gemfile rake"
  sh "BUNDLE_GEMFILE=./travis/ar41.gemfile bundle"
  sh "BUNDLE_GEMFILE=./travis/ar41.gemfile rake"
end
