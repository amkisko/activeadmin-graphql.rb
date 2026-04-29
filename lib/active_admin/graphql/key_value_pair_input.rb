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

      def extract_pair(entry)
        return extract_from_struct(entry) if key_value_struct?(entry)
        return extract_from_hash(entry) if entry.is_a?(Hash)

        raise ::GraphQL::ExecutionError, "invalid key/value pair entry: #{entry.class}"
      end

      def key_value_struct?(entry)
        entry.respond_to?(:key) && entry.respond_to?(:value) && !entry.is_a?(Hash)
      end

      def extract_from_struct(entry)
        [entry.key, entry.value]
      end

      def extract_from_hash(entry)
        key = entry["key"] || entry[:key]
        raise ::GraphQL::ExecutionError, "key/value pair missing key" if key.nil?

        [key, entry["value"] || entry[:value]]
      end
    end
  end
end
