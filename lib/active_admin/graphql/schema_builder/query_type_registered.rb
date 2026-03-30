# frozen_string_literal: true

module ActiveAdmin
  module GraphQL
    class SchemaBuilder
      module QueryTypeRegistered
        def add_registered_resource_query_field!(query_class, builder:, ns:, registered_resource_union:,
          aa_by_graphql_type_name:)
          query_class.class_eval do
            field :registered_resource, registered_resource_union, null: true, camelize: false,
              visibility: {kind: :query_registered_resource},
              description: "Load any registered resource by GraphQL type name (+type_name+), " \
                    "mirroring singular resource queries. Use +path+ for nested belongs_to route params." do
              argument :type_name, ::GraphQL::Types::String, required: true, camelize: false
              argument :id, ::GraphQL::Types::ID, required: true, camelize: false
              argument :path, [KeyValuePairInput], required: false, camelize: false,
                description: "Parent route params as flat key/value pairs (same keys as nested REST segments)."
            end

            define_method(:registered_resource) do |type_name:, id:, path: nil|
              aa_res = aa_by_graphql_type_name[type_name.to_s]
              raise ::GraphQL::ExecutionError, "unknown resource type_name #{type_name.inspect}" unless aa_res

              model = aa_res.resource_class
              auth = context[:auth]
              unless auth.authorized?(aa_res, ActiveAdmin::Authorization::READ, model)
                raise ::GraphQL::ExecutionError, "not authorized to read #{model.name}"
              end

              graph_params = KeyValuePairs.to_hash(path)
              proxy = ResourceQueryProxy.new(
                aa_resource: aa_res,
                user: auth.user,
                namespace: ns,
                graph_params: graph_params
              )
              record = builder.graphql_resolve_show(
                aa_res,
                proxy: proxy,
                context: context,
                id: id,
                graph_params: graph_params
              )
              return nil unless record

              unless auth.authorized?(aa_res, ActiveAdmin::Authorization::READ, record)
                raise ::GraphQL::ExecutionError, "not authorized to read this record"
              end

              record
            end
          end
        end
      end
    end
  end
end
