require "bundler/gem_tasks"
require "rake/testtask"
require "appraisal"

task default: [:test]

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.test_files = %w(test/**/*_test.rb)
  t.verbose = false
end
