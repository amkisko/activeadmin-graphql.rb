# frozen_string_literal: true

module ActiveAdmin
  module GraphQL
    class SchemaBuilder
      module QueryTypePolicies
        def add_activeadmin_policies_query_field!(query_class, builder:, ns:, aa_by_graphql_type_name:)
          adapter = builder.send(:policy_adapter)
          return unless adapter

          resource_policy_type = Class.new(::GraphQL::Schema::Object) do
            graphql_name "ActiveAdminResourcePolicies"
            field :type_name, ::GraphQL::Types::String, null: false, camelize: false
            field :activeadmin_policies, builder.send(:policy_set_type), null: false, camelize: false
          end

          page_policy_type = Class.new(::GraphQL::Schema::Object) do
            graphql_name "ActiveAdminPagePolicies"
            field :name, ::GraphQL::Types::String, null: false, camelize: false
            field :activeadmin_policies, builder.send(:policy_set_type), null: false, camelize: false
          end

          record_policy_type = Class.new(::GraphQL::Schema::Object) do
            graphql_name "ActiveAdminRecordPolicies"
            field :id, ::GraphQL::Types::ID, null: false, camelize: false
            field :activeadmin_policies, builder.send(:policy_set_type), null: false, camelize: false
          end

          matrix_type = Class.new(::GraphQL::Schema::Object) do
            graphql_name "ActiveAdminPolicies"
            field :resources, [resource_policy_type], null: false, camelize: false
            field :pages, [page_policy_type], null: false, camelize: false
          end

          query_class.class_eval do
            field :activeadmin_policies, matrix_type, null: false, camelize: false,
              visibility: {kind: :query_activeadmin_policies}

            field :activeadmin_policies_for, [record_policy_type], null: false, camelize: false,
              visibility: {kind: :query_activeadmin_policies_for} do
              argument :type_name, ::GraphQL::Types::String, required: true, camelize: false
              argument :ids, [::GraphQL::Types::ID], required: true, camelize: false
              argument :path, [KeyValuePairInput], required: false, camelize: false
            end

            define_method(:activeadmin_policies) do
              resources = builder.send(:active_resources).filter_map do |aa_res|
                next unless adapter.include_resource?(aa_res)

                {
                  type_name: builder.send(:graphql_type_name_for, aa_res),
                  activeadmin_policies: ActiveAdmin::GraphQL::PolicySetCache.fetch(
                    context,
                    subject_owner: aa_res,
                    subject: aa_res.resource_class
                  )
                }
              end
              pages = ns.resources.select { |r| r.is_a?(ActiveAdmin::Page) }.map do |page|
                {
                  name: page.name,
                  activeadmin_policies: ActiveAdmin::GraphQL::PolicySetCache.fetch(
                    context,
                    subject_owner: page,
                    subject: page
                  )
                }
              end
              {resources: resources, pages: pages}
            end

            define_method(:activeadmin_policies_for) do |type_name:, ids:, path: nil|
              aa_res = aa_by_graphql_type_name[type_name.to_s]
              raise ::GraphQL::ExecutionError, "unknown resource type_name #{type_name.inspect}" unless aa_res
              unless adapter.include_resource?(aa_res)
                raise ::GraphQL::ExecutionError, "policies disabled for #{type_name.inspect}"
              end

              proxy = ResourceQueryProxy.new(
                aa_resource: aa_res,
                user: context[:auth].user,
                namespace: ns,
                graph_params: KeyValuePairs.to_hash(path)
              )

              records_by_id = proxy.find_members(ids.map(&:to_s))
              ids.map do |id|
                record = records_by_id[id.to_s]
                raise ::GraphQL::ExecutionError, "not found" unless record

                {
                  id: id.to_s,
                  activeadmin_policies: ActiveAdmin::GraphQL::PolicySetCache.fetch(
                    context,
                    subject_owner: aa_res,
                    subject: record
                  )
                }
              end
            end
          end
        end
      end
    end
  end
end
