# frozen_string_literal: true

module ActiveAdmin
  module GraphQL
    # Block body for +capability :name do ... end+ (RFC 0008, RFC 0009).
    class CapabilityDefinitionDSL
      QUERY_ALIASES = {
        index: :collection,
        list: :collection,
        show: :member
      }.freeze

      MUTATION_ALIASES = {
        delete: :destroy
      }.freeze

      def initialize(config, capability_name, mode: nil)
        @config = config
        @capability_name = capability_name.to_sym
        @mode = mode
      end

      def fields(*names, mode: nil)
        @config.assign_field_capabilities!(
          @capability_name,
          names,
          mode: mode.nil? ? @mode : mode
        )
      end

      def queries(*names)
        keys = names.flatten.map { |name| normalize_query_key(name) }
        @config.assign_query_capabilities!(@capability_name, keys)
      end

      def mutations(*names)
        keys = names.flatten.map { |name| normalize_mutation_key(name) }
        @config.assign_mutation_capabilities!(@capability_name, keys)
      end

      def member_actions(*names)
        keys = names.flatten.map { |name| :"member_#{name.to_s.tr("-", "_")}" }
        @config.assign_mutation_capabilities!(@capability_name, keys)
      end

      def batch_actions(*names)
        keys = names.flatten.map { |name| :"batch_#{name.to_s.tr("-", "_")}" }
        @config.assign_mutation_capabilities!(@capability_name, keys)
      end

      def collection_actions(*names)
        keys = names.flatten.map { |name| :"collection_#{name.to_s.tr("-", "_")}" }
        @config.assign_mutation_capabilities!(@capability_name, keys)
      end

      private

      def normalize_query_key(name)
        key = name.to_sym
        QUERY_ALIASES.fetch(key, key)
      end

      def normalize_mutation_key(name)
        key = name.to_sym
        MUTATION_ALIASES.fetch(key, key)
      end
    end
  end
end
