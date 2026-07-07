# frozen_string_literal: true

polyrun_cov_measure =
  ENV["POLYRUN_COVERAGE_DISABLE"] != "1" &&
  %w[1 true yes].include?(ENV["POLYRUN_COVERAGE"]&.to_s&.downcase)

if polyrun_cov_measure
  require "coverage"
  branch = %w[1 true yes].include?(ENV["POLYRUN_COVERAGE_BRANCHES"]&.to_s&.downcase)
  ::Coverage.start(lines: true, branches: branch)
end

if polyrun_cov_measure
  require "polyrun/coverage/rails"
  Polyrun::Coverage::Rails.start!(root: File.expand_path("..", __dir__))
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
require "polyrun/rspec"
Polyrun::RSpec.install_failure_fragments!
