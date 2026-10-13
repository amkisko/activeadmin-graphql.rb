# frozen_string_literal: true

module ActiveAdmin
  module GraphQL
    # Resolves the capability for batch / member / collection run-action fields (RFC 0012).
    module RunActionCapability
      KINDS = %i[batch member collection].freeze

      module_function

      # @param kind [Symbol] +:batch+, +:member+, or +:collection+
      # @param action_name [String, Symbol, nil] per-action name; +nil+ for the aggregate field
      def resolve(namespace, aa_res, kind, action_name = nil)
        kind = kind.to_sym
        unless KINDS.include?(kind)
          raise ArgumentError, "run-action kind must be one of #{KINDS.inspect}, got #{kind.inspect}"
        end

        if action_name
          per_capability = per_action_config_capability(aa_res, kind, action_name)
          return per_capability if per_capability

          mapped = aa_res.graphql_config.capability_for_mutation(
            :"#{kind}_#{action_name.to_s.tr("-", "_")}"
          )
        else
          aggregate_capability = aggregate_config_capability(aa_res, kind)
          return aggregate_capability if aggregate_capability

          mapped = aa_res.graphql_config.capability_for_mutation(:"#{kind}_action")
        end
        return mapped if mapped

        namespace.public_send(:"graphql_#{kind}_action_capability_default")&.to_sym
      end

      def per_action_config_capability(aa_res, kind, action_name)
        map =
          case kind
          when :member then aa_res.graphql_config.member_action_mutations
          when :collection then aa_res.graphql_config.collection_action_mutations
          when :batch then nil
          end
        return nil unless map

        map[action_name.to_s]&.capability
      end
      module_function :per_action_config_capability

      def aggregate_config_capability(aa_res, kind)
        cfg =
          case kind
          when :member then aa_res.graphql_config.member_run_action
          when :batch then aa_res.graphql_config.batch_run_action
          when :collection then aa_res.graphql_config.collection_run_action
          end
        cfg&.capability
      end
      module_function :aggregate_config_capability
    end
  end
end
