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
        require "graphql"
        require "graphql/types/json"
        require "graphql/types/iso_8601_date_time"
        require "graphql/types/iso_8601_date"
        require_relative "graphql/resource_interface"
        require_relative "graphql/schema_field"
        require_relative "graphql/auth_context"
        require_relative "graphql/record_source"
        require_relative "graphql/resource_query_proxy"
        require_relative "graphql/run_action_payload"
        require_relative "graphql/run_action_mutation_config"
        require_relative "graphql/run_action_mutation_dsl"
        require_relative "graphql/key_value_pair_input"
        require_relative "graphql/schema_builder"
      end

      # @param namespace [ActiveAdmin::Namespace]
      # @return [Class] schema class (subclass of GraphQL::Schema)
      def schema_for(namespace)
        cache_key = namespace.name
        SCHEMA_CACHE.delete(cache_key) if defined?(Rails) && Rails.env.development?
        SCHEMA_CACHE[cache_key] ||= SchemaBuilder.new(namespace).build
      end

      def clear_schema_cache!
        SCHEMA_CACHE.clear
      end

      def clear_schema_for!(namespace)
        SCHEMA_CACHE.delete(namespace.name)
      end
    end
  end
end

require_relative "graphql/integration"
ActiveAdmin::GraphQL::Integration.install!
ActiveAdmin::GraphQL.load!
