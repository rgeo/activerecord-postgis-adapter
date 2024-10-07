require "bundler/gem_tasks"
require "rake/testtask"
require_relative "test/rake_helper"

task default: [:test]
task test: "test:all"

Rake::TestTask.new(:test_postgis) do |t|
  t.libs << postgis_test_load_paths
  t.test_files = postgis_test_files
  t.verbose = false
end

Rake::TestTask.new(:test_activerecord) do |t|
  t.libs << postgis_test_load_paths
  t.test_files = activerecord_test_files
  t.verbose = false
end

Rake::TestTask.new(:test_all) do |t|
  t.libs << postgis_test_load_paths
  t.test_files = all_test_files
  t.verbose = false
end

# We invoke the tests from here so we can add environment varaible(s)
# necessary for ActiveRecord tests. TestTask.new runs its block
# regardless of whether it has been invoked or not, so environment
# variables cannot be set in there if they're only needed for specific
# tests.
namespace :test do
  task :postgis do
    Rake::Task["test_postgis"].invoke
  end

  task :activerecord do
    ENV["ARCONN"] = "postgis"
    Rake::Task["test_activerecord"].invoke
  end

  task :all do
    ENV["ARCONN"] = "postgis"
    Rake::Task["test_all"].invoke
  end
end
