# frozen_string_literal: true

# Minimal helpers for ActiveAdmin registration lifecycle (graphql specs).
module ActiveAdminIntegrationSpecHelper
  def with_resources_during(example)
    load_resources { yield }

    example.run

    load_resources {}
  end

  def reload_menus!
    ActiveAdmin.application.namespaces.each(&:reset_menu!)
  end

  def reload_routes!
    Rails.application.reload_routes!
  end

  def load_resources
    ActiveAdmin.unload!
    yield
    reload_menus!
    reload_routes!
  end
end
