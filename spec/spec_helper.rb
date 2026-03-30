# frozen_string_literal: true

if ENV["COVERAGE"] == "true"
  require "simplecov"
  SimpleCov.start do
    add_filter "/spec/"
    track_files "lib/**/*.rb"
  end
end

Encoding.default_external = Encoding::UTF_8

RSpec.configure do |config|
  config.disable_monkey_patching!
  config.filter_run focus: true
  config.filter_run_excluding changes_filesystem: true
  config.run_all_when_everything_filtered = true
  config.color = true
  config.order = :random
  config.example_status_persistence_file_path = ".rspec_failures"
end
