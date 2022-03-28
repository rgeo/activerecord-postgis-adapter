# frozen_string_literal: true

POSTGIS_TEST_HELPER = "test/test_helper.rb"

def ar_root
  File.join(Gem.loaded_specs["rails"].full_gem_path, "activerecord")
end

def postgis_test_load_paths
  ["lib", "test", File.join(ar_root, "lib"), File.join(ar_root, "test")]
end

def config_load_paths!
  postgis_test_load_paths.each { |p| $LOAD_PATH.unshift(p) unless $LOAD_PATH.include?(p) }
end

def set_arconfig_env!
  arconfig_file = File.expand_path(File.join(File.dirname(__FILE__), "database.yml"))
  ENV["ARCONFIG"] = arconfig_file
end

config_load_paths!
set_arconfig_env!

def activerecord_test_files
  if ENV["AR_TEST_FILES"]
    ENV["AR_TEST_FILES"]
      .split(",")
      .map { |file| File.join ar_root, file.strip }
      .sort
      .prepend(POSTGIS_TEST_HELPER)
  else
    Dir
      .glob("#{ar_root}/test/cases/**/*_test.rb")
      .grep_v(%r{/adapters/mysql2/})
      .grep_v(%r{/adapters/sqlite3/})
      .sort
      .prepend(POSTGIS_TEST_HELPER)
  end
end

def postgis_test_files
  if ENV["POSTGIS_TEST_FILES"]
    ENV["POSTGIS_TEST_FILES"].split(",").map(&:strip)
  else
    Dir.glob("test/cases/**/*_test.rb")
  end
end

def all_test_files
  activerecord_test_files + postgis_test_files
end
