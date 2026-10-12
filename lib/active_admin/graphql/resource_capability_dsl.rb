# frozen_string_literal: true

require_relative "capability_definition_dsl"

module ActiveAdmin
  module GraphQL
    # +capability+ entry on {ResourceDefinitionDSL} (RFC 0008).
    module ResourceCapabilityDSL
      def capability(
        name,
        fields: nil,
        queries: nil,
        mutations: nil,
        member_actions: nil,
        batch_actions: nil,
        collection_actions: nil,
        &block
      )
        body = CapabilityDefinitionDSL.new(@config, name)
        body.fields(*fields) if fields
        body.queries(*queries) if queries
        body.mutations(*mutations) if mutations
        body.member_actions(*member_actions) if member_actions
        body.batch_actions(*batch_actions) if batch_actions
        body.collection_actions(*collection_actions) if collection_actions
        body.instance_exec(&block) if block
        name.to_sym
      end
    end
  end
end
