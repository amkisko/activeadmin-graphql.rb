# frozen_string_literal: true

module ActiveAdmin
  # GraphQL HTTP API for ActiveAdmin (graphql-ruby), shipped in the +activeadmin-graphql+ gem.
  #
  # Bundling +activeadmin-graphql+ loads +graphql-ruby+ and registers this integration. Enable the
  # HTTP endpoint per namespace in +config/initializers/active_admin.rb+:
  #
  #   ActiveAdmin.setup do |config|
  #     config.namespace :admin do |api|
  #       api.graphql = true
  #     end
  #   end
  #
  module GraphQL
    SCHEMA_CACHE = {}
  end
end

require_relative "graphql/resource_config"

module ActiveAdmin
  module GraphQL
    class << self
      # Requires graphql-ruby and schema builders. Safe to call repeatedly; loads once.
      def load!
        return if @graphql_features_loaded

        @graphql_features_loaded = true
        ActiveAdmin::Dependency["graphql"].spec!
        require_graphql_dependencies!
        require_active_admin_graphql_components!
      end

      # @param namespace [ActiveAdmin::Namespace]
      # @return [Class] schema class (subclass of GraphQL::Schema)
      #
      # Cached per namespace for the process. In development, call
      # {clear_schema_cache!} or {clear_schema_for!} after ActiveAdmin +unload!+
      # (already wired in {Integration::ApplicationUnloadClearsGraphQLSchema}) or
      # when admin registrations change without a full unload.
      def schema_for(namespace)
        cache_key = namespace.name
        SCHEMA_CACHE[cache_key] ||= SchemaBuilder.new(namespace).build
      end

      def clear_schema_cache!
        SCHEMA_CACHE.clear
      end

      def clear_schema_for!(namespace)
        SCHEMA_CACHE.delete(namespace.name)
      end

      def require_graphql_dependencies!
        require "graphql"
        require "graphql/types/json"
        require "graphql/types/iso_8601_date_time"
        require "graphql/types/iso_8601_date"
      end

      def require_active_admin_graphql_components!
        %w[
          graphql/resource_interface
          graphql/schema_field
          graphql/auth_context
          graphql/record_source
          graphql/resource_query_proxy
          graphql/run_action_payload
          graphql/run_action_mutation_config
          graphql/run_action_mutation_dsl
          graphql/key_value_pair_input
          graphql/schema_builder
        ].each { |path| require_relative path }
      end
    end
  end
end

require_relative "graphql/integration"
ActiveAdmin::GraphQL::Integration.install!
ActiveAdmin::GraphQL.load!
