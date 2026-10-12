# frozen_string_literal: true

module ActiveAdmin
  module GraphQL
    # Capability → member maps on {ResourceConfig} (RFC 0008).
    module ResourceCapabilityMaps
      def field_capabilities
        @field_capabilities ||= {}
      end

      def query_capabilities
        @query_capabilities ||= {}
      end

      def mutation_capabilities
        @mutation_capabilities ||= {}
      end

      def capability_for_field(name)
        field_capabilities[name.to_sym]
      end

      def capability_for_query(kind)
        query_capabilities[kind.to_sym]
      end

      def capability_for_mutation(kind)
        mutation_capabilities[kind.to_sym]
      end

      def assign_field_capabilities!(capability_name, names)
        assign_capabilities!(field_capabilities, capability_name, names, label: "field")
      end

      def assign_query_capabilities!(capability_name, names)
        assign_capabilities!(query_capabilities, capability_name, names, label: "query")
      end

      def assign_mutation_capabilities!(capability_name, names)
        assign_capabilities!(mutation_capabilities, capability_name, names, label: "mutation")
      end

      private

      def assign_capabilities!(map, capability_name, names, label:)
        capability = capability_name.to_sym
        names.flatten.each do |name|
          key = name.to_sym
          existing = map[key]
          if existing && existing != capability
            raise ArgumentError,
              "GraphQL #{label} #{key.inspect} already requires capability #{existing.inspect}"
          end
          map[key] = capability
        end
      end
    end
  end
end
