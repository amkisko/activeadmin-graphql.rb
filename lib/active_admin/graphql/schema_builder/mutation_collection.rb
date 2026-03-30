# frozen_string_literal: true

module ActiveAdmin
  module GraphQL
    class SchemaBuilder
      module MutationCollection
        private

        def mutation_collection_fields(sb, ns, aa_res)
          [mutation_collection_aggregate_field(sb, ns, aa_res)] + aa_res.collection_actions.map do |ca|
            mutation_single_collection_action_field(sb, ns, aa_res, ca)
          end
        end

        def mutation_collection_aggregate_field(sb, ns, aa_res)
          plural = aa_res.resource_name.route_key.tr("-", "_")
          fname = "#{plural}_collection_action"
          allowed = aa_res.collection_actions.map { |a| a.name.to_s }.freeze
          collection_payload_t = run_action_return_type(aa_res, :collection)

          proc do
            field fname.to_sym, collection_payload_t, null: false, camelize: false,
              visibility: {kind: :mutation_collection_action, graphql_type_name: sb.send(:graphql_type_name_for, aa_res), resource: aa_res, field_name: fname, aggregate: true},
              description: "Invoke a +collection_action+ on #{aa_res.resource_name} by name (same scoping as REST +index+). Prefer per-action fields +#{plural}_collection_<action>+ for distinct inputs or return types." do
              argument :action, ::GraphQL::Types::String, required: true, camelize: false
              argument :params, [KeyValuePairInput], required: false, camelize: false,
                description: "Extra request params as flat key/value pairs."
              if (btc = aa_res.belongs_to_config)
                argument btc.to_param.to_sym, ::GraphQL::Types::ID, required: btc.required?, camelize: false
              end
            end

            define_method(fname.to_sym) do |action:, params: nil, **kw|
              auth = context[:auth]
              mdl = aa_res.resource_class
              unless auth.authorized?(aa_res, ActiveAdmin::Authorization::READ, mdl)
                raise ::GraphQL::ExecutionError, "not authorized to read #{mdl.name}"
              end

              act = action.to_s
              unless allowed.include?(act)
                raise ::GraphQL::ExecutionError, "Unknown collection action #{act.inspect} for #{plural}"
              end

              proxy = ResourceQueryProxy.new(
                aa_resource: aa_res,
                user: context[:auth].user,
                namespace: ns,
                graph_params: sb.graph_params_for_mutation(aa_res, kw)
              )
              sb.graphql_resolve_collection_action(
                aa_res,
                proxy: proxy,
                context: context,
                action: act,
                params: params,
                **kw
              )
            end
          end
        end

        def mutation_single_collection_action_field(sb, ns, aa_res, collection_action_def)
          plural = aa_res.resource_name.route_key.tr("-", "_")
          action_name = collection_action_def.name.to_s
          field_name = "#{plural}_collection_#{action_name.tr("-", "_")}"
          fname = field_name.to_sym
          per_cfg = aa_res.graphql_config.collection_action_mutations[action_name]
          collection_payload_t = collection_action_return_type(aa_res, action_name)

          proc do
            field fname, collection_payload_t, null: false, camelize: false,
              visibility: {
                kind: :mutation_collection_action,
                graphql_type_name: sb.send(:graphql_type_name_for, aa_res),
                resource: aa_res,
                field_name: field_name,
                collection_action: action_name
              },
              description: "Invoke +collection_action+ #{action_name} on #{aa_res.resource_name} (same scoping as REST +index+)." do
              argument :params, [KeyValuePairInput], required: false, camelize: false,
                description: "Extra request params as flat key/value pairs."
              if (btc = aa_res.belongs_to_config)
                argument btc.to_param.to_sym, ::GraphQL::Types::ID, required: btc.required?, camelize: false
              end
              if per_cfg&.arguments_proc
                instance_exec(&per_cfg.arguments_proc)
              end
            end

            define_method(fname) do |params: nil, **kw|
              auth = context[:auth]
              mdl = aa_res.resource_class
              unless auth.authorized?(aa_res, ActiveAdmin::Authorization::READ, mdl)
                raise ::GraphQL::ExecutionError, "not authorized to read #{mdl.name}"
              end

              proxy = ResourceQueryProxy.new(
                aa_resource: aa_res,
                user: context[:auth].user,
                namespace: ns,
                graph_params: sb.graph_params_for_mutation(aa_res, kw)
              )
              sb.graphql_resolve_collection_action(
                aa_res,
                proxy: proxy,
                context: context,
                action: action_name,
                params: params,
                **kw
              )
            end
          end
        end
      end
    end
  end
end
