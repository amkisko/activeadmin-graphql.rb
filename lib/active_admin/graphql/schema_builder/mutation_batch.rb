# frozen_string_literal: true

module ActiveAdmin
  module GraphQL
    class SchemaBuilder
      module MutationBatch
        private

        def mutation_batch_field(sb, ns, aa_res)
          plural = aa_res.resource_name.route_key.tr("-", "_")
          fname = "#{plural}_batch_action"
          allowed = aa_res.batch_actions.map { |a| a.sym.to_s }.freeze
          batch_payload_t = run_action_return_type(aa_res, :batch)

          proc do
            field fname.to_sym, batch_payload_t, null: false, camelize: false,
              visibility: {kind: :mutation_batch_action, graphql_type_name: sb.send(:graphql_type_name_for, aa_res), resource: aa_res, field_name: fname},
              description: "Run a batch action registered on #{aa_res.resource_name} (+batch_action+ DSL), " \
                    "same as the index batch UI (+collection_selection+ / +batch_action_inputs+)." do
              argument :batch_action, ::GraphQL::Types::String, required: true, camelize: false
              argument :ids, [::GraphQL::Types::ID], required: true, camelize: false
              argument :inputs, [KeyValuePairInput], required: false, camelize: false,
                description: "Batch action form fields as key/value pairs (passed as +batch_action_inputs+)."
              if (btc = aa_res.belongs_to_config)
                argument btc.to_param.to_sym, ::GraphQL::Types::ID, required: btc.required?, camelize: false
              end
            end

            define_method(fname.to_sym) do |batch_action:, ids:, inputs: nil, **kw|
              auth = context[:auth]
              mdl = aa_res.resource_class
              cfg = aa_res.graphql_config.batch_run_action
              auth_enabled = cfg.authorize.nil? ? (ns.graphql_custom_mutation_authorization_default != false) : cfg.authorize
              if auth_enabled && !auth.authorized?(aa_res, ActiveAdmin::Authorization::READ, mdl)
                raise ::GraphQL::ExecutionError, "not authorized to read #{mdl.name}"
              end

              ba = batch_action.to_s
              unless allowed.include?(ba)
                raise ::GraphQL::ExecutionError, "Unknown batch_action #{ba.inspect} for #{plural}"
              end

              max_ids = ns.graphql_batch_action_max_ids
              if max_ids.is_a?(Integer) && max_ids.positive? && ids.size > max_ids
                raise ::GraphQL::ExecutionError,
                  "ids cannot exceed #{max_ids} entries (received #{ids.size})"
              end

              proxy = ResourceQueryProxy.new(
                aa_resource: aa_res,
                user: context[:auth].user,
                namespace: ns,
                graph_params: sb.graph_params_for_mutation(aa_res, kw)
              )
              sb.graphql_resolve_batch_action(
                aa_res,
                proxy: proxy,
                context: context,
                batch_action: ba,
                ids: ids,
                inputs: inputs
              )
            end
          end
        end
      end
    end
  end
end
