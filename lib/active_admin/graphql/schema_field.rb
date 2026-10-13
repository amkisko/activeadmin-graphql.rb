# frozen_string_literal: true

module ActiveAdmin
  module GraphQL
    # Subclass of {::GraphQL::Schema::Field} for namespace +Query+ / +Mutation+ fields
    # and resource object fields.
    #
    # The +visibility:+ keyword accepts an optional Hash of metadata forwarded to
    # +graphql_schema_visible+ (second argument) when {GraphQL::Schema::Visibility} is enabled.
    #
    # +capability:+ (RFC 0008) and +capability_mode:+ (RFC 0009) gate +visible?+ /
    # +authorized?+ via +context[:capabilities]+. +graphql_field_visible+ may omit fields.
    # +dry_run:+ / +confirm:+ / +preview:+ (RFC 0013) control custom run-action fields.
    class SchemaField < ::GraphQL::Schema::Field
      CAPABILITY_MODES = %i[omit null].freeze

      def initialize(
        visibility: nil,
        authorize: nil,
        authorize_action: nil,
        capability: nil,
        capability_mode: nil,
        dry_run: false,
        confirm: false,
        preview: nil,
        extensions: ::GraphQL::EmptyObjects::EMPTY_ARRAY,
        **kwargs,
        &block
      )
        @capability = capability&.to_sym
        @capability_mode = normalize_capability_mode(capability_mode)
        @inject_dry_run = dry_run
        @inject_confirm = confirm
        @preview_proc = preview
        @visibility =
          if @capability && visibility.is_a?(Hash) && !visibility.key?(:capability)
            visibility.merge(capability: @capability)
          else
            visibility
          end
        @authorize = authorize
        @authorize_action = authorize_action
        field_extensions = Array(extensions)
        if @inject_confirm || @preview_proc
          field_extensions += [{
            RunActionControlExtension => {confirm: @inject_confirm, preview: @preview_proc}
          }]
        end
        if @inject_dry_run || @inject_confirm || @preview_proc || block
          super(extensions: field_extensions, **kwargs) do
            inject_run_action_control_arguments!
            instance_exec(&block) if block
          end
        else
          super(extensions: field_extensions, **kwargs)
        end
      end

      def visible?(ctx)
        return false unless super
        return false unless field_visible_by_hook?(ctx)

        if ctx[:namespace]&.graphql_visibility &&
            @capability &&
            !Capability.granted?(ctx, @capability) &&
            capability_mode_for(ctx) == :omit
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

      private

      def inject_run_action_control_arguments!
        if @inject_dry_run
          argument :dry_run, ::GraphQL::Types::Boolean, required: false, default_value: false, camelize: false,
            description: "When true, preview without performing the side-effecting action."
        end
        if @inject_confirm
          argument :confirm, ::GraphQL::Types::Boolean, required: false, default_value: false, camelize: false,
            description: "When false and dry_run is false, refuse with body confirm_required."
        end
      end

      def normalize_capability_mode(mode)
        return nil if mode.nil?

        sym = mode.to_sym
        unless CAPABILITY_MODES.include?(sym)
          raise ArgumentError, "capability_mode must be :omit or :null, got #{mode.inspect}"
        end
        sym
      end

      def capability_mode_for(ctx)
        mode = @capability_mode || ctx[:namespace]&.graphql_field_capability_mode_default || :omit
        mode.to_sym
      end

      def field_visible_by_hook?(ctx)
        hook = ctx[:namespace]&.graphql_field_visible
        return true if hook.nil?

        owner = self.owner
        meta = {
          graphql_type_name: owner.respond_to?(:graphql_name) ? owner.graphql_name : nil,
          field_name: graphql_name,
          resource: owner.respond_to?(:activeadmin_graphql_resource) ? owner.activeadmin_graphql_resource : nil
        }
        meta = meta.merge(@visibility) if @visibility.is_a?(Hash)
        !!hook.call(ctx, meta)
      end
    end
  end
end
