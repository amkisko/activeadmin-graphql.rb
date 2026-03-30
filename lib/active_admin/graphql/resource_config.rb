# frozen_string_literal: true

require_relative "run_action_mutation_config"

module ActiveAdmin
  module GraphQL
    # Per-resource GraphQL options set via +graphql+ in +ActiveAdmin.register+.
    class ResourceConfig
      attr_accessor :enabled
      attr_accessor :graphql_type_name
      attr_accessor :only_attributes
      attr_accessor :exclude_attributes
      attr_accessor :extension_block

      # Optional resolver overrides (set from +graphql do+). SchemaBuilder still owns field names,
      # arguments, and types; procs replace only the Ruby resolution body.
      attr_accessor :resolve_index_proc
      attr_accessor :resolve_show_proc
      attr_accessor :resolve_create_proc
      attr_accessor :resolve_update_proc
      attr_accessor :resolve_destroy_proc

      # Default return type for run-action mutations (+batch+, +member+, +collection+) when a kind-specific
      # {RunActionMutationConfig#payload_type} is not set. Falls back to {RunActionPayload}.
      attr_accessor :run_action_payload_type

      def initialize
        @enabled = true
        @exclude_attributes = []
      end

      def disabled?
        !enabled
      end

      def batch_run_action
        @batch_run_action ||= RunActionMutationConfig.new
      end

      def member_run_action
        @member_run_action ||= RunActionMutationConfig.new
      end

      def collection_run_action
        @collection_run_action ||= RunActionMutationConfig.new
      end

      # Per +member_action+ name (string) -> {RunActionMutationConfig} for typed fields like +posts_member_publish+.
      def member_action_mutations
        @member_action_mutations ||= {}
      end

      def member_action_mutation_for(name)
        key = name.to_s
        member_action_mutations[key] ||= RunActionMutationConfig.new
      end

      def collection_action_mutations
        @collection_action_mutations ||= {}
      end

      def collection_action_mutation_for(name)
        key = name.to_s
        collection_action_mutations[key] ||= RunActionMutationConfig.new
      end
    end
  end
end
