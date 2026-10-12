# frozen_string_literal: true

module ActiveAdmin
  module GraphQL
    # Named grants carried in GraphQL +context[:capabilities]+ (RFC 0008).
    module Capability
      module_function

      def normalize_set(raw)
        return nil if raw.nil?

        Set.new(
          Array(raw).filter_map do |item|
            next if item.nil?

            name = item.to_s.strip
            next if name.empty?

            name.to_sym
          end
        )
      end

      def granted?(context, capability_name)
        return true if capability_name.nil?

        caps = context[:capabilities]
        return false if caps.nil?

        caps = normalize_set(caps) unless caps.is_a?(Set)
        caps.include?(capability_name.to_sym)
      end
    end
  end
end
