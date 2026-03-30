# frozen_string_literal: true

module ActiveAdmin
  module GraphQL
    # Return type for mutations that run batch, member, or collection controller actions.
    class RunActionPayload < ::GraphQL::Schema::Object
      graphql_name "ActiveAdminRunActionPayload"

      def self.visible?(context)
        hook = context[:namespace]&.graphql_schema_visible
        return super if hook.nil?

        super && !!hook.call(context, {kind: :run_action_payload})
      end

      field :ok, ::GraphQL::Types::Boolean, null: false
      field :status, ::GraphQL::Types::Int, null: true,
        description: "HTTP-style status from the controller response, when set."
      field :location, ::GraphQL::Types::String, null: true,
        description: "Redirect target, if the action called +redirect_to+."
      field :body, ::GraphQL::Types::String, null: true,
        description: "Response body text when the action rendered (e.g. JSON)."

      Result = Struct.new(:ok, :status, :location, :body, keyword_init: true)
    end
  end
end
