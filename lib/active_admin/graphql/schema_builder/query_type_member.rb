# frozen_string_literal: true

module ActiveAdmin
  module GraphQL
    class SchemaBuilder
      module QueryTypeMember
        def define_query_member_field!(query_class, model, aa_res, builder, ns, object_types, find_input_types)
          singular = aa_res.resource_name.route_key.singularize.camelize(:lower)
          type_gn = builder.send(:graphql_type_name_for, aa_res)
          find_type = find_input_types[model]
          type_c = object_types[model]
          return unless type_c

          query_class.class_eval do
            field singular.to_sym, type_c, null: true, camelize: false,
              visibility: {
                kind: :query_member_field,
                graphql_type_name: type_gn,
                field_name: singular,
                resource: aa_res
              },
              description: "Find #{model.name} by id (same scoping chain as REST +show+). Use +where+ or legacy +id+." do
              argument :where, find_type, required: false, camelize: false
              if ActiveAdmin::PrimaryKey.composite?(model)
                argument :id, ::GraphQL::Types::ID, required: false, camelize: false,
                  description: "JSON object string with all primary keys, or use per-key arguments"
              else
                argument :id, ::GraphQL::Types::ID, required: false, camelize: false
              end
              if ActiveAdmin::PrimaryKey.composite?(model)
                ActiveAdmin::PrimaryKey.ordered_columns(model).each do |col|
                  coldef = model.columns_hash[col]
                  next unless coldef

                  gql_t = builder.send(:graphql_scalar_for_column, aa_res, model, coldef)
                  argument col.to_sym, gql_t, required: false, camelize: false
                end
              end
              if (btc = aa_res.belongs_to_config)
                argument btc.to_param.to_sym, ::GraphQL::Types::ID, required: false, camelize: false
              end
            end

            define_method(singular.to_sym) do |where: nil, id: nil, **kw|
              auth = context[:auth]
              unless auth.authorized?(aa_res, ActiveAdmin::Authorization::READ, model)
                raise ::GraphQL::ExecutionError, "not authorized to read #{model.name}"
              end

              begin
                if where
                  blob = where.to_h.stringify_keys
                  graph = builder.graph_params_from_find_blob(aa_res, blob)
                  rid = ActiveAdmin::PrimaryKey.member_param_hash(model, blob)
                else
                  graph = builder.graph_params_for_mutation(aa_res, kw)
                  rid = ActiveAdmin::PrimaryKey.field_kw_to_param_hash(model, id: id, **kw)
                end
              rescue ArgumentError => e
                raise ::GraphQL::ExecutionError, e.message
              end

              proxy = ResourceQueryProxy.new(
                aa_resource: aa_res,
                user: auth.user,
                namespace: ns,
                graph_params: graph
              )
              record = builder.graphql_resolve_show(
                aa_res,
                proxy: proxy,
                context: context,
                id: rid,
                graph_params: graph,
                where: where,
                id_argument: id
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
