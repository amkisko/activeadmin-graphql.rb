# frozen_string_literal: true

module ActiveAdmin
  module GraphQL
    # Nested DSL for +graphql { create do … }+ and +update do … }+, pairing
    # ActiveAdmin +permit_params+ with graphql-ruby-style +resolve+.
    class MutationInputDefinitionDSL
      def initialize(config)
        @config = config
      end

      def permit_params(*attrs)
        @config.permit_params_attributes = attrs.flatten.map(&:to_sym)
      end
      alias_method :permit, :permit_params

      def resolve(&block)
        @config.resolve_proc = block
      end
    end
  end
end
