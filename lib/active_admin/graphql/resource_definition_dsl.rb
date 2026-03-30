# frozen_string_literal: true

require_relative "run_action_mutation_config"
require_relative "run_action_mutation_dsl"

module ActiveAdmin
  module GraphQL
    # DSL for +graphql do ... end+ inside +ActiveAdmin.register+.
    class ResourceDefinitionDSL
      def initialize(config)
        @config = config
      end

      def disable!
        @config.enabled = false
      end

      def type_name(name)
        @config.graphql_type_name = name.to_s
      end

      def only(*attrs)
        @config.only_attributes = attrs.flatten.map(&:to_sym)
      end

      def except(*attrs)
        @config.exclude_attributes.concat(attrs.flatten.map(&:to_sym))
      end
      alias_method :exclude, :except

      def configure(&block)
        @config.extension_block = block
      end

      # Override the list field resolver (+posts+, etc.). Must return an +ActiveRecord::Relation+
      # (or compatible with the connection type). Same auth and +ResourceQueryProxy+ as the default.
      def resolve_index(&block)
        @config.resolve_index_proc = block
      end
      alias_method :resolve_collection, :resolve_index

      # Override the singular field resolver (+post+, +registered_resource+ for this type).
      # Must return a record instance or +nil+.
      def resolve_show(&block)
        @config.resolve_show_proc = block
      end
      alias_method :resolve_member, :resolve_show

      def resolve_create(&block)
        @config.resolve_create_proc = block
      end

      def resolve_update(&block)
        @config.resolve_update_proc = block
      end

      def resolve_destroy(&block)
        @config.resolve_destroy_proc = block
      end

      # @see #batch_action_mutation
      def resolve_batch_action(&block)
        @config.batch_run_action.resolve_proc = block
      end

      # @see #member_action_mutation
      def resolve_member_action(&block)
        @config.member_run_action.resolve_proc = block
      end

      # @see #collection_action_mutation
      def resolve_collection_action(&block)
        @config.collection_run_action.resolve_proc = block
      end

      # Pair +type+ and +resolve+ for +posts_batch_action+ (graphql-ruby-style block).
      def batch_action_mutation(&block)
        RunActionMutationDSL.new(@config.batch_run_action).instance_exec(&block)
      end

      # With no name: configures the aggregate +posts_member_action(action: …)+ field.
      # With a symbol/string: configures +posts_member_<action>+ (one field per +member_action+), so each
      # action can use its own +type+, +resolve+, +arguments+, and GraphQL inputs.
      def member_action_mutation(name = nil, &block)
        cfg = name.nil? ? @config.member_run_action : @config.member_action_mutation_for(name)
        RunActionMutationDSL.new(cfg).instance_exec(&block)
      end

      def collection_action_mutation(name = nil, &block)
        cfg = name.nil? ? @config.collection_run_action : @config.collection_action_mutation_for(name)
        RunActionMutationDSL.new(cfg).instance_exec(&block)
      end

      # Default return type for all run-action fields unless a kind-specific +type+ is set inside
      # +batch_action_mutation+ / +member_action_mutation+ / +collection_action_mutation+.
      def run_action_payload_type(type)
        RunActionMutationConfig.ensure_graphql_object_subclass!(type)
        @config.run_action_payload_type = type
      end

      def batch_action_run_action_payload_type(type)
        RunActionMutationConfig.ensure_graphql_object_subclass!(type)
        @config.batch_run_action.payload_type = type
      end

      def member_action_run_action_payload_type(type)
        RunActionMutationConfig.ensure_graphql_object_subclass!(type)
        @config.member_run_action.payload_type = type
      end

      def collection_action_run_action_payload_type(type)
        RunActionMutationConfig.ensure_graphql_object_subclass!(type)
        @config.collection_run_action.payload_type = type
      end
    end
  end
end
