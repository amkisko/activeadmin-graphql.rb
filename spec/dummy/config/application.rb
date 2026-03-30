# frozen_string_literal: true

require_relative "boot"

require "rails"
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_view/railtie"
require "rails/test_unit/railtie"
require "sprockets/railtie"

# Gemspec development deps sit in Bundler's :development group; Rails.groups under test is
# only :default + :test, so Devise and other tooling would not load. The dummy runs in test.
if Rails.env.test?
  Bundler.require(:default, :test, :development)
else
  Bundler.require(*Rails.groups)
end

module Dummy
  class Application < Rails::Application
    config.root = File.expand_path("..", __dir__)

    config.load_defaults "#{Rails::VERSION::MAJOR}.#{Rails::VERSION::MINOR}"

    config.eager_load = false

    config.secret_key_base = "x" * 64
    config.api_only = false

    config.active_record.maintain_test_schema = false
  end
end
