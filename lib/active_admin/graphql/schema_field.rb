# frozen_string_literal: true

module ActiveAdmin
  module GraphQL
    # Subclass of {::GraphQL::Schema::Field} for namespace +Query+ / +Mutation+ fields.
    #
    # The +visibility:+ keyword accepts an optional Hash of metadata forwarded to
    # +graphql_schema_visible+ (second argument) when {GraphQL::Schema::Visibility} is enabled.
    # That hook runs from {#visible?}; it does not replace graphql-ruby's visibility system—it
    # composes with +super+ like any custom +Field+ class.
    #
    # +capability:+ (RFC 0008) gates +visible?+ and +authorized?+ via +context[:capabilities]+.
    class SchemaField < ::GraphQL::Schema::Field
      def initialize(visibility: nil, authorize: nil, authorize_action: nil, capability: nil, **kwargs, &block)
        @capability = capability&.to_sym
        @visibility =
          if @capability && visibility.is_a?(Hash) && !visibility.key?(:capability)
            visibility.merge(capability: @capability)
          else
            visibility
          end
        @authorize = authorize
        @authorize_action = authorize_action
        super(**kwargs, &block)
      end

      def visible?(ctx)
        return false unless super

        # Gate introspection only when Schema::Visibility is enabled; otherwise
        # capability is enforced in +authorized?+ so hosts without the plugin
        # do not trip graphql-ruby's legacy Warden +visible?+ path.
        if ctx[:namespace]&.graphql_visibility && !Capability.granted?(ctx, @capability)
          return false
        end

        return true unless @visibility

        hook = ctx[:namespace]&.graphql_schema_visible
        return true if hook.nil?

        !!hook.call(ctx, @visibility)
      end

      def authorized?(object, args, ctx)
        return false unless super
        return false unless Capability.granted?(ctx, @capability)

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
