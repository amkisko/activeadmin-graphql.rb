# frozen_string_literal: true

module ActiveAdmin
  module GraphQL
    class SchemaBuilder
      module MutationUpdateDestroy
        private

        def mutation_update_field(sb, ns, aa_res, model, type_c)
          fname = "update_#{aa_res.resource_name.route_key.singularize.tr("-", "_")}"
          find_type = @find_input_types[model]
          update_input = @update_input_types[model]

          proc do
            field fname.to_sym, type_c, null: true, camelize: false,
              visibility: {kind: :mutation_update, graphql_type_name: sb.send(:graphql_type_name_for, aa_res), resource: aa_res},
              description: "Update #{model.name}" do
              argument :where, find_type, required: true, camelize: false
              argument :input, update_input, required: true, camelize: false
            end

            define_method(fname.to_sym) do |where:, input:, **|
              auth = context[:auth]
              blob = where.to_h.stringify_keys
              graph = sb.graph_params_from_find_blob(aa_res, blob)
              begin
                rid = ActiveAdmin::PrimaryKey.member_param_hash(model, blob)
              rescue ArgumentError => e
                raise ::GraphQL::ExecutionError, e.message
              end

              proxy = ResourceQueryProxy.new(
                aa_resource: aa_res,
                user: auth.user,
                namespace: ns,
                graph_params: graph
              )
              record = proxy.find_member(rid)
              raise ::GraphQL::ExecutionError, "not found" unless record

              unless auth.authorized?(aa_res, ActiveAdmin::Authorization::UPDATE, record)
                raise ::GraphQL::ExecutionError, "not authorized to update this record"
              end

              attrs = sb.assignable_slice_from_input(aa_res, input)
              record = if (hook = aa_res.graphql_config.resolve_update_proc)
                hook.call(
                  proxy: proxy,
                  input: input,
                  attributes: attrs,
                  record: record,
                  context: context,
                  auth: auth,
                  aa_resource: aa_res
                )
              else
                attrs = attrs.stringify_keys.slice(*aa_res.graphql_assignable_attribute_names)
                unless record.update(attrs)
                  raise ::GraphQL::ExecutionError, record.errors.full_messages.to_sentence
                end
                record
              end
              record
            end
          end
        end

        def mutation_destroy_field(sb, ns, aa_res, model)
          fname = "delete_#{aa_res.resource_name.route_key.singularize.tr("-", "_")}"
          find_type = @find_input_types[model]

          proc do
            field fname.to_sym, ::GraphQL::Types::Boolean, null: false, camelize: false,
              visibility: {kind: :mutation_delete, graphql_type_name: sb.send(:graphql_type_name_for, aa_res), resource: aa_res},
              description: "Delete #{model.name}" do
              argument :where, find_type, required: true, camelize: false
            end

            define_method(fname.to_sym) do |where:, **|
              auth = context[:auth]
              blob = where.to_h.stringify_keys
              graph = sb.graph_params_from_find_blob(aa_res, blob)
              begin
                rid = ActiveAdmin::PrimaryKey.member_param_hash(model, blob)
              rescue ArgumentError => e
                raise ::GraphQL::ExecutionError, e.message
              end

              proxy = ResourceQueryProxy.new(
                aa_resource: aa_res,
                user: auth.user,
                namespace: ns,
                graph_params: graph
              )
              record = proxy.find_member(rid)
              raise ::GraphQL::ExecutionError, "not found" unless record

              unless auth.authorized?(aa_res, ActiveAdmin::Authorization::DESTROY, record)
                raise ::GraphQL::ExecutionError, "not authorized to destroy this record"
              end

              if (hook = aa_res.graphql_config.resolve_destroy_proc)
                hook.call(
                  proxy: proxy,
                  record: record,
                  context: context,
                  auth: auth,
                  aa_resource: aa_res
                )
              else
                record.destroy!
              end
              true
            end
          end
        end
      end
    end
  end
end
