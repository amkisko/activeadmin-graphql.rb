# frozen_string_literal: true

ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../../../Gemfile", __dir__)

require "bundler/setup"

# Ruby 3.1+ does not load the logger stdlib by default; Rails 6.x expects Logger early.
require "logger"
