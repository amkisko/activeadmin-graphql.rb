# frozen_string_literal: true

module ActiveAdmin
  module GraphQL
    class SchemaBuilder
      module QueryTypeCollection
        def add_model_query_fields!(query_class, builder:, ns:, aa_by_model:, object_types:,
          list_filter_input_types:, find_input_types:)
          aa_by_model.each do |model, aa_res|
            builder.define_query_collection_field!(
              query_class, model, aa_res, builder, ns, object_types, list_filter_input_types
            )
            builder.define_query_member_field!(
              query_class, model, aa_res, builder, ns, object_types, find_input_types
            )
          end
        end

        def define_query_collection_field!(query_class, model, aa_res, builder, ns, object_types,
          list_filter_input_types)
          plural_route = aa_res.resource_name.route_key.tr("-", "_")
          type_gn = builder.send(:graphql_type_name_for, aa_res)
          filter_type = list_filter_input_types[model]
          type_c = object_types[model]
          return unless type_c

          query_class.class_eval do
            field plural_route.to_sym, type_c.connection_type, null: false, connection: true, camelize: false,
              visibility: {
                kind: :query_collection_field,
                graphql_type_name: type_gn,
                field_name: plural_route,
                resource: aa_res
              },
              description: "Paginated list of #{model.name} (#{aa_res.resource_name.human}); " \
                "pass +filter+ or legacy +q+ / +scope+ / +order+ (Ransack +q+ matches the JSON index param). " \
                "Nested resources require the parent foreign key (same as REST route params)." do
              argument :filter, filter_type, required: false, camelize: false
              argument :scope, ::GraphQL::Types::String, required: false, camelize: false
              argument :q, ::GraphQL::Types::JSON, required: false, camelize: false
              argument :order, ::GraphQL::Types::String, required: false, camelize: false
              if (btc = aa_res.belongs_to_config)
                argument btc.to_param.to_sym, ::GraphQL::Types::ID, required: btc.required?, camelize: false
              end
            end

            define_method(plural_route.to_sym) do |filter: nil, scope: nil, q: nil, order: nil, **kw|
              auth = context[:auth]
              unless auth.authorized?(aa_res, ActiveAdmin::Authorization::READ, model)
                raise ::GraphQL::ExecutionError, "not authorized to read #{model.name}"
              end

              graph_params = builder.list_graph_params(
                aa_res,
                filter: filter,
                scope: scope,
                q: q,
                order: order,
                **kw
              )
              proxy = ResourceQueryProxy.new(
                aa_resource: aa_res,
                user: auth.user,
                namespace: ns,
                graph_params: graph_params
              )
              builder.graphql_resolve_index(
                aa_res,
                proxy: proxy,
                context: context,
                graph_params: graph_params,
                filter: filter,
                scope: scope,
                q: q,
                order: order,
                **kw
              )
            end
          end
        end
      end
    end
  end
end
