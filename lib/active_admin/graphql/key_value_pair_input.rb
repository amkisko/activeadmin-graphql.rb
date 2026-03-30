# frozen_string_literal: true

module ActiveAdmin
  module GraphQL
    # Shared input for flat string key/value pairs (Rails param-style). Used instead of a JSON map
    # for nested route segments and custom action arguments so the schema stays explicit.
    class KeyValuePairInput < ::GraphQL::Schema::InputObject
      graphql_name "ActiveAdminKeyValuePair"
      description "Param entry: string key and value (same shape as flat Rails query/form fields)."

      argument :key, ::GraphQL::Types::String, required: true, camelize: false
      argument :value, ::GraphQL::Types::String, required: true, camelize: false
    end

    module KeyValuePairs
      module_function

      # @param entries [nil, Array<#key, #value>, Array<Hash>]
      # @return [Hash<String, String>]
      def to_hash(entries)
        return {} if entries.nil?

        unless entries.is_a?(Array)
          raise ArgumentError, "expected an array of key/value pairs, got #{entries.class}"
        end

        entries.each_with_object({}) do |e, h|
          key, val = extract_pair(e)
          h[key.to_s] = val.to_s
        end
      end

      def extract_pair(e)
        if e.respond_to?(:key) && e.respond_to?(:value) && !e.is_a?(Hash)
          [e.key, e.value]
        elsif e.is_a?(Hash)
          k = e["key"] || e[:key]
          v = e["value"] || e[:value]
          raise ::GraphQL::ExecutionError, "key/value pair missing key" if k.nil?

          [k, v]
        else
          raise ::GraphQL::ExecutionError, "invalid key/value pair entry: #{e.class}"
        end
      end
    end
  end
end
