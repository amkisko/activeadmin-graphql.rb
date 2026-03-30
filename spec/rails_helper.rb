# frozen_string_literal: true

require "fileutils"

require_relative "spec_helper"

ENV["RAILS_ENV"] = "test"

require_relative "dummy/config/environment"

DUMMY_ROOT = Rails.root unless defined?(DUMMY_ROOT)

FileUtils.mkdir_p(DUMMY_ROOT.join("storage"))
FileUtils.mkdir_p(DUMMY_ROOT.join("tmp", "storage"))

ActiveRecord::Base.connection_pool.with_connection do |conn|
  needs_schema =
    !conn.table_exists?(:posts) ||
    !conn.table_exists?(:active_admin_comments)
  if needs_schema
    ActiveRecord::Migration.verbose = false
    load DUMMY_ROOT.join("db", "schema.rb").to_s
  end
end

require "rspec/rails"

require "activeadmin/graphql"

Rails.application.reload_routes!

ActiveAdmin.application.authentication_method = false
ActiveAdmin.application.current_user_method = false

require_relative "support/active_admin_integration_spec_helper"
require_relative "support/graphql_deny_post_authorization_adapter"

RSpec.configure do |config|
  config.use_transactional_fixtures = true
  config.use_instantiated_fixtures = false
  config.render_views = false

  config.include Devise::Test::IntegrationHelpers, type: :request
  config.include ActiveAdminIntegrationSpecHelper
end
