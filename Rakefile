# frozen_string_literal: true

require "bundler/gem_tasks"

require "rspec/core/rake_task"
RSpec::Core::RakeTask.new(:spec)

require "rubocop/rake_task"
RuboCop::RakeTask.new

begin
  require "appraisal"
  Appraisal::Task.new
rescue LoadError
  # Appraisal not installed yet
end

begin
  require "parallel_tests/tasks"
rescue LoadError
  # parallel_tests not installed yet
end

task default: :spec
