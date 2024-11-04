# frozen_string_literal: true

POSTGIS_TEST_HELPER = "test/test_helper.rb"

def ar_root
  Gem.loaded_specs["activerecord"].full_gem_path
end

def postgis_test_load_paths
  ["lib", "test", File.join(ar_root, "lib"), File.join(ar_root, "test")]
end

def config_load_paths!
  postgis_test_load_paths.each { |p| $LOAD_PATH.unshift(p) unless $LOAD_PATH.include?(p) }
end

def set_arconfig_env!
  arconfig_file = File.expand_path("database.yml", __dir__)
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
      .then { FileList[*_1] }
  else
    FileList["#{ar_root}/test/cases/**/*_test.rb"]
      .reject { _1.include?("/adapters/") || _1.include?("/encryption/performance") }
      .then { |list| FileList[POSTGIS_TEST_HELPER] + list + FileList["#{ar_root}/test/cases/adapters/postgresql/**/*_test.rb"] }
  end
end

def postgis_test_files
  if ENV["POSTGIS_TEST_FILES"]
    ENV["POSTGIS_TEST_FILES"].split(",").map(&:strip).then { FileList[*_1] }
  else
    FileList["test/cases/**/*_test.rb"]
  end
end

def all_test_files
  activerecord_test_files + postgis_test_files
end
