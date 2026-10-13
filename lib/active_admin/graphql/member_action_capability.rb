# frozen_string_literal: true

module ActiveAdmin
  module GraphQL
    # Compatibility wrapper around {RunActionCapability} for member actions (RFC 0012).
    module MemberActionCapability
      module_function

      def resolve(namespace, aa_res, action_name = nil)
        RunActionCapability.resolve(namespace, aa_res, :member, action_name)
      end
    end
  end
end
