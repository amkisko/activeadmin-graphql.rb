# frozen_string_literal: true

require_relative "run_action_mutation_config"

module ActiveAdmin
  module GraphQL
    # Nested DSL for a single run-action mutation kind (+batch_action_mutation+, etc.): +type+ and +resolve+,
    # similar to graphql-ruby pairing field type with resolution.
    class RunActionMutationDSL
      def initialize(mutation_config)
        @mutation_config = mutation_config
      end

      # GraphQL object type for this mutation field (alias: +payload_type+).
      def type(gql_object_class)
        RunActionMutationConfig.ensure_graphql_object_subclass!(gql_object_class)
        @mutation_config.payload_type = gql_object_class
      end
      alias_method :payload_type, :type

      def resolve(&block)
        @mutation_config.resolve_proc = block
      end

      # Per-action fields only: extra GraphQL arguments (+argument :reason, String, …+).
      # Not used on the aggregate +posts_member_action(action: …)+ field.
      def arguments(&block)
        @mutation_config.arguments_proc = block
      end

      def authorize(value = true)
        @mutation_config.authorize = !!value
      end
    end
  end
end
