# frozen_string_literal: true

module ActiveAdmin
  module GraphQL
    # Implemented by every namespace resource +GraphQL::Schema::Object+ type so clients can
    # fragment on a shared +id+ field or use abstract selections consistently.
    module ResourceInterface
      include ::GraphQL::Schema::Interface

      graphql_name "ActiveAdminResource"
      description "Shared shape for Active Admin resource records exposed in this namespace."

      field :id, ::GraphQL::Types::ID, null: false

      definition_methods do
        def visible?(context)
          hook = context[:namespace]&.graphql_schema_visible
          return super if hook.nil?

          super && !!hook.call(context, {kind: :resource_interface})
        end
      end
    end
  end
end
