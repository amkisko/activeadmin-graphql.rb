# frozen_string_literal: true

module ActiveAdmin
  module GraphQL
    class SchemaBuilder
      module Visibility
        private

        def apply_graphql_visibility!(schema)
          vis = @namespace.graphql_visibility
          return if vis.nil?

          if vis == true
            schema.use(::GraphQL::Schema::Visibility)
          elsif vis.is_a?(Hash)
            schema.use(::GraphQL::Schema::Visibility, **vis.symbolize_keys)
          else
            raise ActiveAdmin::DependencyError,
              "namespace graphql_visibility must be nil, true, or a Hash of GraphQL::Schema::Visibility options"
          end
        end

        def attach_registered_resource_union_visibility!(union_class)
          union_class.define_singleton_method(:visible?) do |ctx|
            hook = ctx[:namespace]&.graphql_schema_visible
            return super(ctx) if hook.nil?

            super(ctx) && !!hook.call(ctx, {kind: :registered_resource_union})
          end
        end

        def attach_resource_object_visibility!(type_class, graphql_name, aa_res)
          type_class.field_class(::ActiveAdmin::GraphQL::SchemaField)
          gn = graphql_name
          ar = aa_res
          type_class.define_singleton_method(:visible?) do |ctx|
            hook = ctx[:namespace]&.graphql_schema_visible
            return super(ctx) if hook.nil?

            super(ctx) && !!hook.call(ctx, {kind: :resource_object, graphql_type_name: gn, resource: ar})
          end
        end

        def attach_input_object_visibility!(input_class, graphql_type_name, aa_res, role)
          gtn = graphql_type_name
          ar = aa_res
          r = role
          input_class.define_singleton_method(:visible?) do |ctx|
            hook = ctx[:namespace]&.graphql_schema_visible
            return super(ctx) if hook.nil?

            super(ctx) && !!hook.call(ctx, {kind: :input_object, graphql_type_name: gtn, resource: ar, role: r})
          end
        end
      end
    end
  end
end
