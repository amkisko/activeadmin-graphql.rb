# frozen_string_literal: true

ActiveAdmin.setup do |config|
  config.load_paths = [Rails.root.join("config/active_admin").to_s]
  config.default_namespace = :admin
  config.authentication_method = false
  config.current_user_method = false
  config.site_title = "Dummy"
  config.logout_link_path = false
  config.batch_actions = true
end
