# frozen_string_literal: true

module ActiveAdmin
  module GraphQL
    class SchemaBuilder
      module MutationCreate
        private

        def mutation_create_field(sb, ns, aa_res, model, type_c)
          fname = "create_#{aa_res.resource_name.route_key.singularize.tr("-", "_")}"
          create_input = @create_input_types[model]

          proc do
            field fname.to_sym, type_c, null: true, camelize: false,
              visibility: {kind: :mutation_create, graphql_type_name: sb.send(:graphql_type_name_for, aa_res), resource: aa_res},
              description: "Create #{model.name}" do
              argument :input, create_input, required: true, camelize: false
            end

            define_method(fname.to_sym) do |input:, **|
              auth = context[:auth]
              unless auth.authorized?(aa_res, ActiveAdmin::Authorization::CREATE, model)
                raise ::GraphQL::ExecutionError, "not authorized to create #{model.name}"
              end

              proxy = ResourceQueryProxy.new(
                aa_resource: aa_res,
                user: auth.user,
                namespace: ns,
                graph_params: sb.graph_params_from_input(aa_res, input)
              )
              attrs = sb.assignable_slice_from_input(aa_res, input)
              record = if (hook = aa_res.graphql_config.resolve_create_proc)
                hook.call(
                  proxy: proxy,
                  input: input,
                  attributes: attrs,
                  context: context,
                  auth: auth,
                  aa_resource: aa_res
                )
              else
                r = proxy.build_new(attrs)
                unless auth.authorized?(aa_res, ActiveAdmin::Authorization::CREATE, r)
                  raise ::GraphQL::ExecutionError, "not authorized to create this record"
                end

                unless r.save
                  raise ::GraphQL::ExecutionError, r.errors.full_messages.to_sentence
                end
                r
              end

              unless auth.authorized?(aa_res, ActiveAdmin::Authorization::CREATE, record)
                raise ::GraphQL::ExecutionError, "not authorized to create this record"
              end

              record
            end
          end
        end
      end
    end
  end
end
