# frozen_string_literal: true

module ActiveAdmin
  module GraphQL
    # Inclusion and schema-surface toggles for +graphql do ... end+.
    module ResourceSurfaceDSL
      def enable!
        @config.enabled = true
      end

      def disable!
        @config.enabled = false
      end

      def enable_queries!
        @config.queries_enabled = true
      end

      def disable_queries!
        @config.queries_enabled = false
      end

      def enable_mutations!
        @config.mutations_enabled = true
      end

      def disable_mutations!
        @config.mutations_enabled = false
      end

      def enable_run_actions!
        @config.run_actions_enabled = true
      end

      def disable_run_actions!
        @config.run_actions_enabled = false
      end

      def enable_policies!
        @config.policies_enabled = true
      end

      def disable_policies!
        @config.policies_enabled = false
      end
    end
  end
end
