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
      def initialize(visibility: nil, **kwargs, &block)
        @visibility = visibility
        super(**kwargs, &block)
      end

      def visible?(ctx)
        return false unless super

        return true unless @visibility

        hook = ctx[:namespace]&.graphql_schema_visible
        return true if hook.nil?

        !!hook.call(ctx, @visibility)
      end
    end
  end
end
