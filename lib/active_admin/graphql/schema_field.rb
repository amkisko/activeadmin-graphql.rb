# frozen_string_literal: true

module ActiveAdmin
  module GraphQL
    # Subclass of {::GraphQL::Schema::Field} for namespace +Query+ / +Mutation+ fields.
    #
    # The +visibility:+ keyword accepts an optional Hash of metadata forwarded to
    # +graphql_schema_visible+ (second argument) when {GraphQL::Schema::Visibility} is enabled.
    # That hook runs from {#visible?}; it does not replace graphql-ruby's visibility system—it
    # composes with +super+ like any custom +Field+ class.
    class SchemaField < ::GraphQL::Schema::Field
      def initialize(visibility: nil, authorize: nil, authorize_action: nil, **kwargs, &block)
        @visibility = visibility
        @authorize = authorize
        @authorize_action = authorize_action
        super(**kwargs, &block)
      end

      def visible?(ctx)
        return false unless super

        return true unless @visibility

        hook = ctx[:namespace]&.graphql_schema_visible
        return true if hook.nil?

        !!hook.call(ctx, @visibility)
      end

      def authorized?(object, args, ctx)
        return false unless super

        owner = self.owner
        aa_resource = owner.respond_to?(:activeadmin_graphql_resource) ? owner.activeadmin_graphql_resource : nil
        return true unless aa_resource

        enabled = if @authorize.nil?
          ctx[:namespace]&.graphql_custom_field_authorization_default != false
        else
          @authorize
        end
        return true unless enabled

        action = @authorize_action || ActiveAdmin::Authorization::READ
        !!ctx[:auth]&.authorized?(aa_resource, action, object)
      end
    end
  end
end
